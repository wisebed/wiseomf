# loading config hash from file
require 'yaml'
CONFIG = YAML.load_file './config.yml'

# requiring WiseOMF classes and helpers:
# Need omf_rc gem to be required, this will load all dependencies

require 'omf_rc'
require "#{File.dirname(__FILE__)}/lib/wise_r_p.rb"
require "#{File.dirname(__FILE__)}/lib/wise_reservation_p.rb"
require "#{File.dirname(__FILE__)}/lib/resource_proxy_manager.rb"
