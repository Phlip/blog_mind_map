require "rubygems"

# Add the local gems dir if found within the app root; any dependencies loaded
# hereafter will try to load from the local gems before loading system gems.
if (local_gem_dir = File.join(File.dirname(__FILE__), '..', 'gems')) && $BUNDLE.nil?
  $BUNDLE = true; Gem.clear_paths; Gem.path.unshift(local_gem_dir)
end

# require "merb-core"
require 'pathname'
require "spec" # Satisfies Autotest and anyone else not using the Rake tasks
require 'fixture_dependencies/test_unit/sequel'
require 'fixture_dependencies/sequel'

HomeRoot = (Pathname.new(__FILE__).dirname + '..').expand_path

FixtureDependencies.fixture_path = (HomeRoot + 'spec/fixtures').to_s
require HomeRoot + 'lib/rails3_mind_maps'

# this loads all plugins required in your init file so don't add them
# here again, Merb will do it for you
#Merb.start_environment(:testing => true, :adapter => 'runner', :environment => ENV['MERB_ENV'] || 'test')

# Spec::Runner.configure do |config|
#   config.include(Merb::Test::ViewHelper)
#   config.include(Merb::Test::RouteHelper)
#   config.include(Merb::Test::ControllerHelper)
# end