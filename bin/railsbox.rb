#!/usr/bin/env ruby
require "rubygems" # ruby1.9 doesn't "require" it though
require "thor"
#require "pry"
require "railsbox"
require 'psych'

class RailsboxCommand < Thor
  include Thor::Actions
  include Railsbox::Helpers

  def set_env(environment_name)
    ENV['RAILS_ENV'] = environment_name
    ENV['RACK_ENV'] = environment_name
  end

  desc "deploy", "deploy using ansible"
  method_option :environment, default: "development", aliases: '-e'
  def deploy
    set_env(options[:environment])
    run "cd #{File.join('railsbox', ENV['RAILS_ENV'])} && ./deploy.sh"
  end

  desc "provision", "provision using ansible"
  method_option :environment, default: "development", aliases: '-e'
  def provision
    set_env(options[:environment])
    run "cd #{File.join('railsbox', ENV['RAILS_ENV'])} && ./provision.sh"
  end

  desc 'dbdump', 'Dump the database at ENVIRONMENT to a local file'
  method_option :environment, required: true, aliases: '-e'
  def dbdump
    set_env(options[:environment])
    File.delete(db_dump_file_path) if File.exist?(db_dump_file_path)
    puts 'old db dump removed if exists'

    if db_kind == 'postgresql'
      cmd =  ssh_command
      # cmd << "PGPASSWORD=#{prod['password']} "
      cmd << "pg_dump --no-owner"
      cmd << " --username=#{db_user} #{db_name} > "
      cmd << db_dump_file_path
    elsif db_kind == 'mysql'
      cmd = ssh_command
      cmd << "'mysqldump "
      cmd << "-u #{db_user} " if db_user && !db_user.empty?
      cmd << "--password='#{db_pass}' " if db_pass && !db_pass.empty?
      cmd << "#{db_name}' > #{db_dump_file_path}"
    end
    run cmd

  end

  desc 'dbrestore', 'Restore the database from a local file to ENVIRONMENT. Caution, this will destroy data in the database'
  method_option :environment, required: true, aliases: '-e'
  def dbrestore
    raise 'You must have a database dump first' if !File.exists?(db_dump_file_path)
    input = yes?("Are you sure you want to delete your #{ENV['RAILS_ENV']} db?")
    if !input
      say "Good call ;-)"
      exit 1
    end
    set_env(options[:environment])

    cmd = "#{ssh_command} 'cd #{path} && bundle exec rake db:drop db:create' "
    run cmd

    if db_kind == 'postgresql'
      cmd = ssh_command
      cmd << "'psql"
      cmd << " -U #{db_user}" if db_user.present?
      cmd << " #{db_name}' < #{db_dump_file_path}"
    elsif db_kind == 'mysql'
      cmd = "#{ssh_command} 'cd #{path} && "
      cmd << "mysql"
      cmd << " -u #{db_user}" if db_user && !db_user.empty?
      cmd << " --password=#{db_pass}" if db_pass && !db_pass.empty?
      cmd << " #{db_name}' < #{db_dump_file_path(path)} "
    end
    run cmd

  end

end

RailsboxCommand.start
