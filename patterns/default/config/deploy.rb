require 'vendor/plugins/cap_gun/lib/cap_gun'

set :application, "#{current_app_name}"
set :repository,  "git@#{capistrano_repo_host}:#{current_app_name}.git"
set :user, "#{capistrano_user}"
set :deploy_via, :fast_remote_cache
set :copy_exclude, %w(.git doc test)
set :scm, :git

# Customize the deployment
set :tag_on_deploy, false # turn off deployment tagging, we have our own tagging strategy
set :compress_assets, false # turn off rubaidhstrano compression so we can use jammit instead
set :keep_releases, 6

set :cap_gun_action_mailer_config, {
  :address => "#{cap_gun_address}",
  :port => #{cap_gun_port},
  :user_name => "#{cap_gun_user_name}",
  :password => "#{cap_gun_password}",
  :authentication => :plain
}

# define the options for the actual emails that go out -- :recipients is the only required option
set :cap_gun_email_envelope, {
  :from => "#{cap_gun_user_name}", # Note, don't use the form "Someone project.deploy@example.com" as it'll blow up with ActionMailer 2.3+
  :recipients => #{cap_gun_recipients},
  :email_prefix => "[\##{current_app_name} \#deploy]"
}

# register email as a callback after restart
after "deploy:restart", "cap_gun:email"

before "deploy", "deploy:check_revision"
after "deploy:update", "deploy:cleanup"

# directories to preserve between deployments
# set :asset_directories, ['public/system/logos', 'public/system/uploads']

# re-linking for config files on public repos
# namespace :deploy do
#   desc "Re-link config files"
#   task :link_config, :roles => :app do
#     link "\#{current_path}/config/database.yml" => "\#{shared_path}/config/database.yml"
#   end
# end
#
# def link(link)
#   source, target = link.keys.first, link.values.first
#   run "ln -nfs \#{target} \#{source}"
# end
#
# Activate post-deploy re-linking
# after 'deploy:symlink', 'deploy:link_config'

namespace :deploy do
  desc "Make sure there is something to deploy"
  task :check_revision, :roles => [:web] do
    unless `git rev-parse HEAD` == `git rev-parse origin/\#{branch}`
      puts ""
      puts "  \033[1;33m********************************************#{'*' * branch.size}\033[0m"
      puts "  \033[1;33m* WARNING: HEAD is not the same as origin/#{branch} *\033[0m"
      puts "  \033[1;33m********************************************#{'*' * branch.size}\033[0m"
      puts ""

      exit
    end
  end
end

# If you want to automatically run populations on every deploy
# after 'deploy:symlink' 'db:populate'
# Or you may want to update migrations and run populations
# after 'deploy:symlink' 'db:migrate_and_populate'

# If you use whenever to manage cron jobs inside of your Rails app
# namespace :cron do
#   desc "Update the current crontab with the configuration in config/schedule.rb"
#   task :update, :roles => :db, :only => { :primary => true } do
#     rails_env = fetch(:rails_env, "production")
#     run "cd \#{release_path} && whenever --update-crontab --set environment=\#{rails_env} -i \#{application}"
#   end
# end
# after "deploy:symlink", "cron:update"

namespace :deploy do
  desc 'Bundle and minify the JS and CSS files'
  task :precache_assets, :roles => :app do
    root_path = File.expand_path(File.dirname(__FILE__) + '/..')
    assets_path = "\#{root_path}/public/assets"
    gem_path = ENV['GEM_PATH']
    run_locally "\#{gem_path}/bin/jammit"
    top.upload assets_path, "\#{current_release}/public", :via => :scp, :recursive => true
  end
end
after 'deploy:symlink', 'deploy:precache_assets'
