require 'rubygems/user_interaction'
include Gem::UserInteraction
require 'railsbox/helpers'

namespace :railsbox do
  namespace :pg do
    desc 'reset the database'
    task :reset => :check_env do
      sh "cd #{Rails.root.join('railsbox', ENV['RAILS_ENV'])} && ansible -i inventory "
    end

    include Helpers
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

    desc "download the pg_dump content into #{Helpers.db_dump_file_path}"
    task :pg_dump_download do
      env = which_env
      pg_name, pg_user, pg_password = Helpers.get_ansible_db_vars(env, 'postgresql')
      postgres_host = Helpers.get_ansible_db_host(env)

      puts "host: #{postgres_host}\ndatabase: #{pg_name}\nuser: #{pg_user}"

      # remove the old dump
      File.delete(Helpers.db_dump_file_path) if File.exist?(Helpers.db_dump_file_path)
      puts 'old db dump removed if exists'

      cmd =  "ssh -C "
      cmd << "#{pg_user}@"
      cmd << "#{postgres_host} "
      # cmd << "PGPASSWORD=#{prod['password']} "
      cmd << "pg_dump --no-owner"
      cmd << " --username=#{pg_user} #{pg_name} > "
      cmd << Helpers.db_dump_file_path

      puts "Running #{cmd}"
      system `#{cmd}`
    end

    desc 'import into local pg db'
    task :import_dump_into_dev_pg_db do
      dev = Helpers.import_setup
      cmd = "psql"
      cmd << " -U #{dev['username']}" unless dev['username'].blank?
      cmd << " #{dev['database']} < #{Helpers.db_dump_file_path}"

      puts "Running #{cmd}"
      system `#{cmd}`
    end

    desc 'Pull pg db and import into local dev db'
    task :pull_dump_and_import do
      Rake::Task['railsbox:db:pg_dump_download'].invoke
      Rake::Task['railsbox:db:import_dump_into_dev_pg_db'].invoke
    end
  end
end
