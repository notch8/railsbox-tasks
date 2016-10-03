require 'rubygems/user_interaction'
include Gem::UserInteraction
require 'railsbox/helpers'

namespace :railsbox do
  namespace :mysql do
    include Helpers

    desc "download the mysqldump content into #{Helpers.db_dump_file_path}"
    task :dump => :check_env do
      ENV['DB_KIND'] = db_kind = 'mysql'

      File.delete(Helpers.db_dump_file_path) if File.exist?(Helpers.db_dump_file_path)
      puts 'old db dump removed if exists'

      cmd = Helpers.ssh_command
      cmd << "mysqldump "
      cmd << "-u #{Helpers.db_user} " if Helpers.db_user.present?
      cmd << "--password='#{Helpers.db_pass}' " if Helpers.db_pass.present?
      cmd << "#{Helpers.db_name} > #{Helpers.db_dump_file_path}"

      sh cmd
    end

    desc 'import into local mysql db'
    task :restore => :check_env do
      ENV['DB_KIND'] = 'mysql'
      import_setup

      cmd = "#{Helpers.ssh_command} 'cd #{Helpers.path} && " 
      cmd << "mysql"
      cmd << " -u #{Helpers.db_user}" if Helpers.db_user.present?
      cmd << " --password=#{Helpers.db_pass}" if Helpers.db_pass.present?
      cmd << " #{Helpers.db_name} < #{Helpers.db_dump_file_path(Helpers.path)} '"

      sh cmd
    end

  end
end
