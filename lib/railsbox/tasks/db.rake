require 'rubygems/user_interaction'
include Gem::UserInteraction

namespace :railsbox do
  require 'fileutils'

  namespace :db do
    def db_dump_file_path
      File.expand_path("#{Rails.root}/tmp/dump.sql")
    end

    desc 'pull the production PostgreSQL database into the development SQLite'
    task :pull do
      Rake::Task['db:download_pg_dump'].invoke
      Rake::Task['db:optimze_pg_dump_for_sqlite'].invoke
      Rake::Task['db:recreate_with_dump'].invoke
    end

    desc 'display db config'
    task :display_config do
      puts Rails.application.config.database_configuration.inspect
    end

    desc 'Pull pg db from heroku'
    task :pull_db_from_heroku do
      input = ask("This will clear all data from the development database and replace\nit with the data and schema from heroku. Are you sure? (y/n)")
      abort('Good call ;-)') if input == 'n'

      db_config = Rails.application.config.database_configuration
      begin
        heroku_config = Psych.load_file(Rails.root.join('config', 'heroku.yml'))
      rescue
        abort 'This app does not contain a heroku config file. eg. /config/heroku.yml '
      end
      heroku_apps = heroku_config.keys.map {|app_key| heroku_config[app_key]['app'] }
      which_heroku_app = choose_from_list("which heroku app do you want to pull the db from:", heroku_apps)
      abort 'invalid app choice' unless which_heroku_app[0]

      puts 'Pulling db from heroku and dumpping it into your dev db.'
      puts 'Running rake db:drop'
      Rake::Task['db:drop'].invoke
      cmd = "heroku pg:pull DATABASE_URL #{db_config['development']['database']} --app #{which_heroku_app[0]}"
      puts "Running #{cmd}"

      system `#{cmd}`
    end

    def get_ansible_db_vars(env, db_type)
      ansible_vars = Psych.load_file(Rails.root.join('railsbox', 'ansible', 'group_vars', 'all', 'config.yml'))
      name = ansible_vars["#{db_type}_db_name"]
      user = ansible_vars["#{db_type}db_user"]
      password = ansible_vars["#{db_type}db_password"]
      ansible_env_vars = Psych.load_file(Rails.root.join('railsbox', 'ansible', 'group_vars', env, 'config.yml'))
      name = ansible_env_vars["#{db_type}db_name"] if ansible_env_vars["#{db_type}db_name"]
      user = ansible_env_vars["#{db_type}db_user"] if ansible_env_vars["#{db_type}db_user"]
      password = ansible_env_vars["#{db_type}db_password"] if ansible_env_vars["#{db_type}db_password"]
      abort "Missing #{env} database name" if name.blank?
      abort "Missing #{env} database user" if user.blank?
      [name, user, password]
    end

    def get_ansible_bd_host(env)
      n = false
      host = ''
      File.open(Rails.root.join('railsbox', env, 'inventory'), "r").each_line do |line|
        n = true if line.gsub(/\[|\]/, '').strip == 'postgresql'
        host = line.strip if n
      end
      host
    end

    def which_env(envs = ['staging', 'production'])
      which_env = choose_from_list("which env do you want to pull the db from:", ['staging', 'production'])
      abort 'You must choose a valid env' unless which_env[0]
      which_env[0]
    end

    desc "download the mysqldump content into #{db_dump_file_path}"
    task :mysql_dump_download do
      env = which_env
      mysql_name, mysql_user, mysql_password = get_ansible_db_vars(env, 'mysql')
      mysql_host = get_ansible_bd_host(env)
      puts "host: #{mysql_host}\ndatabase: #{mysql_name}\nuser: #{mysql_user}"
      File.delete(db_dump_file_path) if File.exist?(db_dump_file_path)
      puts 'old db dump removed if exists'

      cmd = 'ssh -C '
      cmd << "#{mysql_user}@#{mysql_host} "
      cmd << "mysqldump "
      cmd << "-u #{mysql_user} "
      cmd << "--password='#{mysql_password}' " if mysql_password
      cmd << "> #{db_dump_file_path}"

      puts "running #{cmd}"

      system `#{cmd}`
    end

    desc "download the pg_dump content into #{db_dump_file_path}"
    task :pg_dump_download do
      env = which_env
      pg_name, pg_user, pg_password = get_ansible_db_vars(env, 'postgresql')
      postgres_host = get_ansible_bd_host(env)

      puts "host: #{postgres_host}\ndatabase: #{pg_name}\nuser: #{pg_user}"

      # remove the old dump
      File.delete(db_dump_file_path) if File.exist?(db_dump_file_path)
      puts 'old db dump removed if exists'

      cmd =  "ssh -C "
      cmd << "#{pg_user}@"
      cmd << "#{postgres_host} "
      # cmd << "PGPASSWORD=#{prod['password']} "
      cmd << "pg_dump --no-owner"
      cmd << " --username=#{pg_user} #{pg_name} > "
      cmd << db_dump_file_path

      puts "Running #{cmd}"
      system `#{cmd}`
    end

    def import_setup
      config = Rails.application.config.database_configuration
      abort "Missing dev database config" if config['development'].blank?
      abort "no pg dumpfile located in #{db_dump_file_path}" unless File.exist?(db_dump_file_path)
      input = ask_yes_no('Are you sure you want to delete your dev db?', nil)
      abort 'Good call ;-)' unless input
      Rake::Task['db:drop'].invoke
      Rake::Task['db:create'].invoke

      config['development']
    end

    desc 'import into local mysql db'
    task :import_dump_into_dev_mysql_db do
      dev = import_setup

      cmd = "mysql"
      cmd << " -u #{dev['username']}" unless dev['username'].blank?
      cmd << " #{dev['database']} < #{db_dump_file_path}"

      puts "Running #{cmd}"
      system `#{cmd}`
    end

    desc 'import into local pg db'
    task :import_dump_into_dev_pg_db do
      dev = import_setup
      cmd = "psql"
      cmd << " -U #{dev['username']}" unless dev['username'].blank?
      cmd << " #{dev['database']} < #{db_dump_file_path}"

      puts "Running #{cmd}"
      system `#{cmd}`
    end

    desc 'Pull pg db and import into local dev db'
    task :get_dump_and_import do
      Rake::Task['railsbox:db:pg_dump_download'].invoke
      Rake::Task['railsbox:db:import_dump_into_dev_pg_db'].invoke
    end

    # desc 'remove unused statements and optimze sql for SQLite'
    # task :optimze_pg_dump_for_sqlite do
    #   result = []
    #   lines = File.readlines(db_dump_file_path)
    #   @version = 0
    #   lines.each do |line|
    #     next if line =~ /SELECT pg_catalog.setval/  # sequence value's
    #     next if line =~ /SET /                      # postgres specific config
    #     next if line =~ /--/                        # comment
    #
    #     if line =~ /INSERT INTO schema_migrations/
    #       @version = line.match(/INSERT INTO schema_migrations VALUES \('([\d]*)/)[1]
    #     end
    #
    #     # replace true and false for 't' and 'f'
    #     line.gsub!("true", "'t'")
    #     line.gsub!("false", "'f'")
    #     result << line
    #   end
    #
    #   File.open(db_dump_file_path, "w") do |f|
    #     # Add BEGIN and END so we add it to 1 transaction. Increase speed!
    #     f.puts("BEGIN;")
    #     result.each{|line| f.puts(line) unless line.blank?}
    #     f.puts("END;")
    #   end
    # end

  #   desc 'backup development.sqlite3 and create a new one with the dumped data'
  #   task :recreate_with_dump do
  #     # sqlite so backup
  #     database = Rails.configuration.database_configuration['development']['database']
  #     database_path = File.expand_path("#{Rails.root}/#{database}")
  #     # remove old backup
  #     File.delete(database_path + '.backup') if File.exist?(database_path + '.backup')
  #
  #     # copy current for backup
  #     FileUtils.cp database_path, database_path + '.backup' if File.exist?(database_path)
  #
  #     # dropping and re-creating db
  #     ENV['VERSION'] = @version
  #     Rake::Task['db:drop'].invoke
  #     Rake::Task["db:migrate"].invoke
  #
  #     puts "migrated to version: #{@version}"
  #     puts "importing..."
  #     # remove migration info
  #     system `sqlite3 #{database_path} "delete from schema_migrations;"`
  #     # import dump.sql
  #     system `sqlite3 #{database_path} ".read #{db_dump_file_path}"`
  #
  #     puts "DONE!"
  #     puts "NOTE: you're now migrated to version #{@version}. Please run db:migrate to apply newer migrations"
  #   end
  end
end
