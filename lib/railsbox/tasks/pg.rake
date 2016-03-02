#### TODO this is very much a work in progress
namespace :railsbox do
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
      # dump
    end

    desc 'pull the database'
    task :pull do
    end
  end
end
