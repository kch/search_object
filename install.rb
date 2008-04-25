this_path = File.dirname(__FILE__)
require this_path + '/../../../config/boot'

exit unless Dir["#{RAILS_ROOT}/db/migrate/*_install_search_object.rb"].empty?

require 'fileutils'

Dir.chdir(RAILS_ROOT)
`ruby script/generate migration install_search_object`
migration_src = "#{this_path}/install/migration.rb"
migration_dst = Dir["#{RAILS_ROOT}/db/migrate/*_install_search_object.rb"].first
FileUtils.cp migration_src, migration_dst

puts "Migration created: #{File.basename(migration_dst)}.\nRun rake db:migrate."
