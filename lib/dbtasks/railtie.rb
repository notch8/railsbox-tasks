require 'rails'

module Dbtasks
  class DbtasksRailtie < Rails::Railtie
    rake_tasks do
      __DIR__ = File.dirname(__FILE__)
      load File.expand_path(File.join(__DIR__, "tasks", "get_my_db.rake"))
    end
  end
end
