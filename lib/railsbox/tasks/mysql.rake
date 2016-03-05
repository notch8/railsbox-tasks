require 'rubygems/user_interaction'
include Gem::UserInteraction
require 'railsbox/helpers'

namespace :railsbox do
  namespace :mysql do
    include Helpers

    desc "download the mysqldump content into #{Helpers.db_dump_file_path}"
    task :mysql_dump_download do
      env = which_env
      mysql_name, mysql_user, mysql_password = Helpers.get_ansible_db_vars(env, 'mysql')
      mysql_host = Helpers.get_ansible_db_host(env)
      puts "host: #{mysql_host}\ndatabase: #{mysql_name}\nuser: #{mysql_user}"
      File.delete(Helpers.db_dump_file_path) if File.exist?(Helpers.db_dump_file_path)
      puts 'old db dump removed if exists'

      cmd = 'ssh -C '
      cmd << "#{mysql_user}@#{mysql_host} "
      cmd << "mysqldump "
      cmd << "-u #{mysql_user} "
      cmd << "--password='#{mysql_password}' " if mysql_password
      cmd << "> #{Helpers.db_dump_file_path}"

      puts "running #{cmd}"

      system `#{cmd}`
    end

    desc 'import into local mysql db'
    task :import_dump_into_dev_mysql_db do
      dev = Helpers.import_setup

      cmd = "mysql"
      cmd << " -u #{dev['username']}" unless dev['username'].blank?
      cmd << " #{dev['database']} < #{Helpers.db_dump_file_path}"

      puts "Running #{cmd}"
      system `#{cmd}`
    end
  end
end
