module Railsbox
  module Helpers
    def ansible_vars
      if !@ansible_vars
        @ansible_vars = Psych.load_file(File.join('railsbox', 'ansible', 'group_vars', 'all', 'config.yml'))
        @ansible_vars.merge!(Psych.load_file(File.join('railsbox', 'ansible', 'group_vars', ENV['RAILS_ENV'], 'config.yml')))
        @ansible_vars['host'] ||= get_db_host
      end
      return @ansible_vars
    end

    def db_kind
      if ENV['DB_KIND'] && ENV['DB_KIND'].size > 1
        ENV['DB_KIND']
      elsif File.exists?('config/database.yml')
        db_config = Psych.load_file('config/database.yml')
        db_config[ENV['RAILS_ENV']]['adapter'].gsub(/\d/, '').gsub("^pg$", "postgresql") # turn mysql2 in to mysql
      end
    end

    def db_user
      ansible_vars["#{db_kind}_db_user"]
    end

    def db_pass
      ansible_vars["#{db_kind}_db_password"]
    end

    def db_name
      ansible_vars["#{db_kind}_db_name"]
    end

    def path
      if ENV['RAILS_ENV'] == 'development'
        "#{ansible_vars['path']}"
      else
        "#{ansible_vars['path']}/current"
      end
    end

    def ssh_command
      if ENV['RAILS_ENV'] == 'development'
        "cd railsbox/development && vagrant ssh -c "
      else
        "ssh -C #{ansible_vars['user_name']}@#{ansible_vars['host']} "
      end
    end

    def db_dump_file_path(path=nil)
      File.expand_path("tmp/dump.sql")
    end

    def get_db_host
      if ENV['RAILS_ENV'] == 'development'
        host = 'localhost'
      else
        n = false
        host = ''
        kind = ENV['DB_KIND']
        File.open(File.join('railsbox', ENV['RAILS_ENV'], 'inventory'), "r").each_line do |line|
          if n
            host = line.strip
            break
          end

          n = true if line.gsub(/\[|\]/, '').strip == kind
        end
      end
      host
    end

  end
end
