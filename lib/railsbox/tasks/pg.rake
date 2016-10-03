require 'rubygems/user_interaction'
include Gem::UserInteraction
require 'railsbox/helpers'

namespace :railsbox do
  namespace :pg do
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
      sh cmd
    end

    desc "download the pg_dump content into #{Helpers.db_dump_file_path}"
    task :dump => :check_env do
      ENV['DB_KIND'] = db_kind = 'postgresql'

      # remove the old dump
      File.delete(Helpers.db_dump_file_path) if File.exist?(Helpers.db_dump_file_path)
      puts 'old db dump removed if exists'

      cmd =  Helpers.ssh_command
      # cmd << "PGPASSWORD=#{prod['password']} "
      cmd << "pg_dump --no-owner"
      cmd << " --username=#{Helpers.db_user} #{Helpers.db_name} > "
      cmd << Helpers.db_dump_file_path

      sh cmd
    end

    desc 'import into local pg db'
    task :restore => :check_env do
      ENV['DB_KIND'] = 'postgresql'
      import_setup

      cmd = Helpers.ssh_command
      cmd << "'psql"
      cmd << " -U #{Helpers.db_user}" if Helpers.db_user.present?
      cmd << " #{Helpers.db_name} < #{Helpers.db_dump_file_path}'"

      sh cmd
    end

    desc 'Pull pg db and import into local dev db'
    task :pull do
      Rake::Task['railsbox:pg:dump'].invoke
      Rake::Task['railsbox:pg:restore'].invoke
    end
  end
end
