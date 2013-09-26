# This script is used for testing small pieces of the implementation.


# loading config hash from file
require 'yaml'
require '../protobuf/internal-messages.pb'
include De::Uniluebeck::Itm::Tr::Iwsn::Messages

test = ReservationEvent.new(:type => ReservationEvent::Type::STARTED)
test.key = "1234"
test.username = "test"
test.interval_start = "1234"
test.interval_end = "12234"

encoded = test.to_s

puts encoded


result = ReservationEvent.parse(encoded)

puts result == test

CONFIG = YAML.load_file "../config.yml"

