namespace :insanity do

desc 'any sane users?'
task :check_peers => :environment do
  SanityCheck.peers_by_time
end

end
