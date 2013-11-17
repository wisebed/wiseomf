require 'base64'
require 'json'
require 'protocol_buffers'

require 'wise_omf/protobuf'


module WiseOMFUtils
  class UIDHelper

    def self.reservation_uid(reservation)
      return to_uid(sort_secret_reservation_keys(reservation))
    end

    def self.node_group_uid(reservation, nodeUrns)
      return to_uid(sort_node_urns(nodeUrns)) #to_uid([sort_secret_reservation_keys(reservation), sort_node_urns(nodeUrns)])
    end


    def self.sort_node_urns(nodeUrns)
      result = nodeUrns.to_a.sort!{|a,b| a <=> b}
      return result
    end

    def self.sort_secret_reservation_keys(reservation)
      keys = reservation.to_hash[:secretReservationKeys]
      # we don't need the username. Delete it from al SRKs:
      keys.each{|k| k.delete(:username)}

      # Sort the keys:
      keys.sort!{|a,b|
        prefixComp = a.to_hash[:nodeUrnPrefix].downcase <=> b.to_hash[:nodeUrnPrefix].downcase
        if prefixComp != 0
          prefixComp
        else
          a.to_hash[:key] <=> b.to_hash[:key]
        end
      }
      return keys
    end

    def self.to_uid(object)
      return JSON.generate(object).gsub("\n", "-") #Base64.encode64(JSON.generate(object)).gsub("\n", "-")
    end

    def self.from_uid(uid)
      return JSON.parse(Base64.decode64(uid.gsub("-","\n")))
    end
  end
end