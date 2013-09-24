# This script is used for testing small pieces of the implementation.


# loading config hash from file
require 'java'
require 'yaml'
require '../lib/reservation_watcher'
CONFIG = YAML.load_file "../config.yml"

