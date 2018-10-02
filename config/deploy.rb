# config valid for current version and patch releases of Capistrano

set :repo_url,        'git@bitbucket.org:tkxel/fambrands.git'
set :application,     'fambrands'
# set :use_sudo,        true
set :user,            "dev_team"

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, "/home/#{fetch(:user)}/apps/#{fetch(:application)}"


# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

## Linked Files & Directories (Default None):
set :linked_files, %w{config/database.yml config/application.yml config/schedule.yml config/secrets.yml config/sidekiq.yml}
# set :linked_dirs,  %w{log public/system }
set :linked_dirs, %w{log tmp/pids tmp/cache tmp/sockets }

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for local_user is ENV['USER']
# set :local_user, -> { `git config user.name`.chomp }

# Default value for keep_releases is 5
# set :keep_releases, 5

# Uncomment the following to require manually verifying the host key before first deploy.
# set :ssh_options, verify_host_key: :secure
