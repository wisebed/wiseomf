require 'base64'
require 'json'

require_relative '../protobuf/external-plugin-messages.pb'
require_relative '../protobuf/internal-messages.pb'
require_relative '../protobuf/iwsn-messages.pb'


module Utils
  class UIDHelper

    def self.reservation_uid(reservation)
      return to_uid(sort_secret_reservation_keys(reservation))
    end

    def self.node_group_uid(reservation, nodeUrns)
      return to_uid([sort_secret_reservation_keys(reservation), sort_node_urns(nodeUrns)])
    end


    def self.sort_node_urns(nodeUrns)
      result = nodeUrns.to_a.sort!{|a,b| a <=> b}
      return result
    end

    def self.sort_secret_reservation_keys(reservation)
      keys = reservation.secretReservationKeys
      keys.sort!{|a,b|
        prefixComp = a.nodeUrnPrefix.downcase <=> b.nodeUrnPrefix.downcase
        userComp = a.username <=> b.username
        if prefixComp != 0
          prefixComp
        elsif userComp != 0
         userComp
        else
          a.key <=> b.key
        end
      }
      return keys
    end

    def self.to_uid(object)
      return Base64.encode64(JSON.generate(object))
    end

    def self.from_uid(uid)
      return JSON.parse(Base64.decode64(uid))
    end
  end
end