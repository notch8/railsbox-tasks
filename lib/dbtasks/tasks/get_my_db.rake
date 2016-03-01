require 'rubygems/user_interaction'
include Gem::UserInteraction

['development', 'demo', 'testing', 'staging', 'production'].each do |environment_name|
  desc "Load the #{environment_name} environment"
  task environment_name do
    ENV['RAILS_ENV'] = environment_name
    ENV['RACK_ENV'] = environment_name
  end
end

task :check_env do
  abort('Please set an environment') unless ENV['RAILS_ENV'].present? && ENV['RAILS_ENV'] != 'development'
end

desc "deploy using ansible"
task :deploy => :check_env do
  sh "cd #{Rails.root.join('railsbox', ENV['RAILS_ENV'])} && ./deploy.sh"
end

desc "deploy using ansible"
task :provision => :check_env  do
  sh "cd #{Rails.root.join('railsbox', ENV['RAILS_ENV'])} && ./provision.sh"
end

#### TODO this is very much a work in progress
namespace :pg do
  desc 'reset the database'
  task :reset => :check_env do
    sh "cd #{Rails.root.join('railsbox', ENV['RAILS_ENV'])} && ansible -i inventory "
  end

  desc 'push the database'
  task :push do
    input = ask("This will clear all data from the #{ENV['RAILS_ENV']} database. Are you sure? (y/n)")
    abort('Good call ;-)') if input != 'y'

    sh "pg_dump --no-privileges --no-owner --clean --create -Fc oma_development > oma.dump"
    #
    #dump
  end

  desc 'pull the database'
  task :pull do

  end

end

require 'fileutils'

namespace :db do
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

  desc 'download the pg_dump content into tmp/dump.sql'
  task :download_pg_dump do
    config = Rails.application.config.database_configuration

    abort "Missing production database config" if config['production'].blank?

    dev  = config['development']
    prod = config['production']

    abort "Development db is not sqlite3" unless dev['adapter'] =~ /sqlite3/
    abort "Production db is not postgresql" unless prod['adapter'] =~ /postgresql/
    abort "Missing ssh host" if prod['ssh_host'].blank?
    abort "Missing database name" if prod['database'].blank?

    # remove the old one
    if File.exists?(pg_dump_file_path)
      File.delete(pg_dump_file_path)
    end

    cmd  = "ssh -C "
    cmd << "#{prod['ssh_user']}@" if prod['ssh_user'].present?
    cmd << "#{prod['ssh_host']} "
    cmd << "PGPASSWORD=#{prod['password']} "
    cmd << "pg_dump --data-only --inserts "
    cmd << "--username=#{prod['username']} #{prod['database']} > "
    cmd << pg_dump_file_path

    system `#{cmd}`
  end

  desc 'remove unused statements and optimze sql for SQLite'
  task :optimze_pg_dump_for_sqlite do
    result = []
    lines = File.readlines(pg_dump_file_path)
    @version = 0
    lines.each do | line |
      next if line =~ /SELECT pg_catalog.setval/  # sequence value's
      next if line =~ /SET /                      # postgres specific config
      next if line =~ /--/                        # comment

      if line =~ /INSERT INTO schema_migrations/
        @version = line.match(/INSERT INTO schema_migrations VALUES \('([\d]*)/)[1]
      end

      # replace true and false for 't' and 'f'
      line.gsub!("true","'t'")
      line.gsub!("false","'f'")
      result << line
    end

    File.open(pg_dump_file_path, "w") do |f|
      # Add BEGIN and END so we add it to 1 transaction. Increase speed!
      f.puts("BEGIN;")
      result.each{|line| f.puts(line) unless line.blank?}
      f.puts("END;")
    end
  end

  desc 'backup development.sqlite3 and create a new one with the dumped data'
  task :recreate_with_dump do
    # sqlite so backup
    database = Rails.configuration.database_configuration['development']['database']
    database_path = File.expand_path("#{Rails.root}/#{database}")
    # remove old backup
    if File.exists?(database_path + '.backup')
      File.delete(database_path + '.backup')
    end
    # copy current for backup
    FileUtils.cp database_path, database_path + '.backup' if File.exists?(database_path)

    # dropping and re-creating db
    ENV['VERSION'] = @version
    Rake::Task['db:drop'].invoke
    Rake::Task["db:migrate"].invoke

    puts "migrated to version: #{@version}"
    puts "importing..."
    # remove migration info
    system `sqlite3 #{database_path} "delete from schema_migrations;"`
    # import dump.sql
    system `sqlite3 #{database_path} ".read #{pg_dump_file_path}"`

    puts "DONE!"
    puts "NOTE: you're now migrated to version #{@version}. Please run db:migrate to apply newer migrations"
  end

  def pg_dump_file_path
    File.expand_path("#{Rails.root}/tmp/dump.sql")
  end
end