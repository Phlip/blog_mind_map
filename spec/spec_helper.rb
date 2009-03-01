require 'rubygems'

# Add the local gems dir if found within the app root; any dependencies loaded
# hereafter will try to load from the local gems before loading system gems.
if (local_gem_dir = File.join(File.dirname(__FILE__), '..', 'gems')) && $BUNDLE.nil?
  $BUNDLE = true; Gem.clear_paths; Gem.path.unshift(local_gem_dir)
end

# require 'merb-core'
require 'pathname'
require 'spec' # Satisfies Autotest and anyone else not using the Rake tasks
require 'active_record'
require 'fixture_dependencies/test_unit'
require 'fixture_dependencies'

HomeRoot = (Pathname.new(__FILE__).dirname + '..').expand_path
FixtureDependencies.fixture_path = (HomeRoot + 'spec/fixtures').to_s
require HomeRoot + 'lib/blog_mind_map'

ActiveRecord::Schema.verbose = false
ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :dbfile => ':memory:')
ActiveRecord::Base.configurations = true

ActiveRecord::Schema.define(:version => 1) do
  create_table :posts do |t|
    t.string   :title
    t.string   :author
    t.text     :body
  end

  create_table :tags do |t|
    t.string   :name
  end
  
  create_table :posts_tags, :id => false do |t|
    t.integer  :post_id
    t.integer  :tag_id
  end
end

class Post < ActiveRecord::Base
  has_and_belongs_to_many :tags
end

class Tag < ActiveRecord::Base
  has_and_belongs_to_many :posts
end

# this loads all plugins required in your init file so don't add them
# here again, Merb will do it for you
#Merb.start_environment(:testing => true, :adapter => 'runner', :environment => ENV['MERB_ENV'] || 'test')

# Spec::Runner.configure do |config|
#   config.include(Merb::Test::ViewHelper)
#   config.include(Merb::Test::RouteHelper)
#   config.include(Merb::Test::ControllerHelper)
# end
