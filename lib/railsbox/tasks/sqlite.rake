require 'rubygems/user_interaction'
include Gem::UserInteraction
require 'railsbox/helpers'

namespace :railsbox do

  namespace :sqlite do
    # desc 'remove unused statements and optimze sql for SQLite'
    # task :optimze_pg_dump_for_sqlite do
    #   result = []
    #   lines = File.readlines(db_dump_file_path)
    #   @version = 0
    #   lines.each do |line|
    #     next if line =~ /SELECT pg_catalog.setval/  # sequence value's
    #     next if line =~ /SET /                      # postgres specific config
    #     next if line =~ /--/                        # comment
    #
    #     if line =~ /INSERT INTO schema_migrations/
    #       @version = line.match(/INSERT INTO schema_migrations VALUES \('([\d]*)/)[1]
    #     end
    #
    #     # replace true and false for 't' and 'f'
    #     line.gsub!("true", "'t'")
    #     line.gsub!("false", "'f'")
    #     result << line
    #   end
    #
    #   File.open(db_dump_file_path, "w") do |f|
    #     # Add BEGIN and END so we add it to 1 transaction. Increase speed!
    #     f.puts("BEGIN;")
    #     result.each{|line| f.puts(line) unless line.blank?}
    #     f.puts("END;")
    #   end
    # end

  #   desc 'backup development.sqlite3 and create a new one with the dumped data'
  #   task :recreate_with_dump do
  #     # sqlite so backup
  #     database = Rails.configuration.database_configuration['development']['database']
  #     database_path = File.expand_path("#{Rails.root}/#{database}")
  #     # remove old backup
  #     File.delete(database_path + '.backup') if File.exist?(database_path + '.backup')
  #
  #     # copy current for backup
  #     FileUtils.cp database_path, database_path + '.backup' if File.exist?(database_path)
  #
  #     # dropping and re-creating db
  #     ENV['VERSION'] = @version
  #     Rake::Task['db:drop'].invoke
  #     Rake::Task["db:migrate"].invoke
  #
  #     puts "migrated to version: #{@version}"
  #     puts "importing..."
  #     # remove migration info
  #     system `sqlite3 #{database_path} "delete from schema_migrations;"`
  #     # import dump.sql
  #     system `sqlite3 #{database_path} ".read #{db_dump_file_path}"`
  #
  #     puts "DONE!"
  #     puts "NOTE: you're now migrated to version #{@version}. Please run db:migrate to apply newer migrations"
  #   end
  end

end
