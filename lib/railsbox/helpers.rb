module Helpers
  def db_dump_file_path
    File.expand_path("#{Rails.root}/tmp/dump.sql")
  end

  def get_ansible_db_vars(env, db_type)
    ansible_vars = Psych.load_file(Rails.root.join('railsbox', 'ansible', 'group_vars', 'all', 'config.yml'))
    name = ansible_vars["#{db_type}_db_name"]
    user = ansible_vars["#{db_type}_db_user"]
    password = ansible_vars["#{db_type}_db_password"]
    ansible_env_vars = Psych.load_file(Rails.root.join('railsbox', 'ansible', 'group_vars', env, 'config.yml'))
    name = ansible_env_vars["#{db_type}_db_name"] if ansible_env_vars["#{db_type}_db_name"]
    user = ansible_env_vars["#{db_type}_db_user"] if ansible_env_vars["#{db_type}_db_user"]
    password = ansible_env_vars["#{db_type}_db_password"] if ansible_env_vars["#{db_type}_db_password"]
    abort "Missing #{env} database name" if name.blank?
    abort "Missing #{env} database user" if user.blank?
    [name, user, password]
  end

  def get_ansible_db_host(env)
    n = false
    host = ''
    File.open(Rails.root.join('railsbox', env, 'inventory'), "r").each_line do |line|
      n = true if line.gsub(/\[|\]/, '').strip == 'postgresql'
      host = line.strip if n
    end
    host
  end

  def which_env(envs = ['staging', 'production'])
    which_env = choose_from_list("which env do you want to pull the db from:", ['staging', 'production'])
    abort 'You must choose a valid env' unless which_env[0]
    which_env[0]
  end

  def import_setup
    config = Rails.application.config.database_configuration
    abort "Missing dev database config" if config['development'].blank?
    abort "no pg dumpfile located in #{db_dump_file_path}" unless File.exist?(db_dump_file_path)
    input = ask_yes_no('Are you sure you want to delete your dev db?', nil)
    abort 'Good call ;-)' unless input
    Rake::Task['db:drop'].invoke
    Rake::Task['db:create'].invoke

    config['development']
  end
end
