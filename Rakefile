# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require(File.join(File.dirname(__FILE__), 'config', 'boot'))

require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

require 'tasks/rails'

task :publish_web do
  system "git push ssh://xadmin@hoccer.com/var/www/throwdata-server master"
end

task :publish_beta_web do
  system "git push ssh://xadmin@hoccer.com/var/www/beta.hoccer.com master"
end

task :publish_service do
  system "git push ssh://xadmin@hoccer.com/var/www/throwdata-server master"
  system "ssh xadmin@hoccer.com -x 'rake db:migrate'"
  system "ssh xadmin@hoccer.com -x 'touch tmp/restart.txt'"
end

task :publish_beta_service do
  system "git push ssh://xadmin@hoccer.com/var/www/beta.hoccer.com master"
  system "ssh xadmin@hoccer.com -x 'rake db:migrate'"
  system "ssh xadmin@hoccer.com -x 'touch tmp/restart.txt'"
end
