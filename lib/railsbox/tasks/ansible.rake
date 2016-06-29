namespace :railsbox do
  ['development', 'demo', 'testing', 'staging', 'production'].each do |environment_name|
    desc "Load the #{environment_name} environment"
    task environment_name do
      ENV['RAILS_ENV'] = environment_name
      ENV['RACK_ENV'] = environment_name
    end
  end

  task :check_env do
    abort('Please set an environment') unless ENV['RAILS_ENV'].present?
  end

  desc "deploy using ansible"
  task :deploy => :check_env do
    sh "cd #{Rails.root.join('railsbox', ENV['RAILS_ENV'])} && ./deploy.sh"
  end

  desc "provision using ansible"
  task :provision => :check_env do
    sh "cd #{Rails.root.join('railsbox', ENV['RAILS_ENV'])} && ./provision.sh"
  end
end
