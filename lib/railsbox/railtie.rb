require 'rails'

module Railsbox
  class RailsboxRailtie < Rails::Railtie
    rake_tasks do
      __DIR__ = File.dirname(__FILE__)
      load File.expand_path(File.join(__DIR__, "tasks", "ansible.rake"))
      load File.expand_path(File.join(__DIR__, "tasks", "pg.rake"))
      load File.expand_path(File.join(__DIR__, "tasks", "db.rake"))
    end
  end
end
