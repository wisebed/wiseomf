# loading config hash from file
require 'yaml'
require '../lib/reservation_watcher'
CONFIG = YAML.load_file "../config.yml"

rw = ReservationWatcher.instance
ab = ReservationWatcher.instance

sleep(10)
