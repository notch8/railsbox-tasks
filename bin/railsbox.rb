#!/usr/bin/env ruby
require "rubygems" # ruby1.9 doesn't "require" it though
require "thor"
require "pry"
require "railsbox"

class RailsboxCommand < Thor
  include Thor::Actions
  include Railsbox::Helpers

  desc "foo", "Prints foo"
  def foo
    puts "foo"
  end

  def set_env(environment_name)
    ENV['RAILS_ENV'] = environment_name
    ENV['RACK_ENV'] = environment_name
  end

  desc "deploy", "deploy using ansible"
  method_option :environment, default: "development"
  def deploy
    set_env(options[:environment])
    run "cd #{File.join('railsbox', ENV['RAILS_ENV'])} && ./deploy.sh"
  end

  desc "provision", "provision using ansible"
  method_option :environment, default: "development"
  def provision
    set_env(options[:environment])
    run "cd #{File.join('railsbox', ENV['RAILS_ENV'])} && ./provision.sh"
  end

    desc 'dbcopy', 'Pull database FROM and put it in TO'
    method_option :from, required: true
    method_option :to, required: true
    method_option :db_kind
    def dbcopy
      dump(environment: options[:from])
      restore(environment: options[:to])
    end

    desc 'dbdump', 'Dump the database at ENVIRONMENT to a local file'
    method_option :environment, required: true
    method_option :db_kind
    def dbdump
      set_env(options[:environment])
      File.delete(db_dump_file_path) if File.exist?(db_dump_file_path)
      puts 'old db dump removed if exists'

      if options[:db_kind] == 'postgresql'
        cmd =  ssh_command
        # cmd << "PGPASSWORD=#{prod['password']} "
        cmd << "pg_dump --no-owner"
        cmd << " --username=#{db_user} #{db_name} > "
        cmd << db_dump_file_path
      end
      run cmd

    end

    desc 'dbrestore', 'Restore the database from a local file to ENVIRONMENT. Caution, this will destroy data in the database'
    method_option :environment, required: true
    method_option :db_kind
    def dbrestore
      import_setup

      cmd = ssh_command
      cmd << "'psql"
      cmd << " -U #{db_user}" if db_user.present?
      cmd << " #{db_name} < #{db_dump_file_path}'"

      run cmd
    
    end

end

RailsboxCommand.start
