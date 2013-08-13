# loading config hash from file
require 'yaml'
CONFIG = YAML.load_file "./config.yml"

# requiring WiseOMF classes and helpers
require File.dirname(__FILE__)+"/lib/wise_r_p.rb"

require File.dirname(__FILE__)+"/lib/resource_proxy_manager.rb"
