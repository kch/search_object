require 'yaml'

namespace :search do
  namespace :reset do
    desc "Destroy and recreate all search objects."
    task :objects => :environment do
      SearchObject.destroy_all
      Dir["#{RAILS_ROOT}/app/models/**/*.rb"].map { |s| s.sub(%r[^.*app/models/], '').sub(/\.rb$/, '') }.map { |s| s.classify.constantize }
      Searchable.reset_all_search_objects!
    end
  end
end
