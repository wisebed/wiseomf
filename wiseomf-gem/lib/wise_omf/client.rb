require 'lrucache'
require 'wise_omf/uid_helper'
module WisebedClient
  class ExperimentHelper
    @@random = Random.new
    @@uid_cache = LRUCache.new(ttl: 30.minutes)


    # Create an unique message id
    # NOTE: Message ids are guaranteed to be unique within 30 minutes.
    def self.messageUID
      uid = -1
      while true
        uid = @@random.rand(2**32)
        break if @@uid_cache.fetch(uid).nil?
      end
      @@uid_cache.store(uid, 1)
      return uid
    end

  end

  # The WiseGroup is the representation of an omf resource group
  # which provides the ability to register callback for requests and configure messages.
  # You should not create an instance of this group directly. This can cause unwanted side effects.
  # The better way is to ask the ReservationManager (factory) for a group for a list of node urns.
  class WiseGroup
      # Message types to call callbacks for
      @@default_message_types = [:response, :inform]
    attr_accessor :name, :uid, :group, :default_callback
    @callback_cache
    @name
    @uid
    @group
    @default_callback

    def initialize(name, uid)
      @callback_cache = LRUCache.new(ttl: 30.minutes)
      @name = name
      @uid = uid
      @group = OmfEc::Group.new(name) {|g|
        g.topic.on_message(:inform_status) { |msg|
          rid = msg.content.properties.requestId
          if rid.nil? && @@default_message_types.include?(msg.content.type)
            self.default_callback.call(msg) unless self.default_callback.nil?
          else
            callback = @callback_cache.fetch(rid)
            unless callback.nil?
              callback.call(msg.content.properties)
            else
              if @@default_message_types.include? msg.content.type
                self.default_callback.call(msg) unless self.default_callback.nil?
              end
            end
          end
        }
      }
        OmfEc.experiment.add_group(@group)
        @group.add_resource(uid)
    end

    def request(property, &block)
      mid = WisebedClient::ExperimentHelper.messageUID
      unless block.nil?
        @callback_cache.store(mid, block)
      end
      @group.topic.configure({property => mid})
    end

    def configure(property, value, &block)
      mid = WisebedClient::ExperimentHelper.messageUID
      unless block.nil?
        @callback_cache.store(mid, block)
      end
      @group.topic.configure({property => {requestId: mid, value: value}})
    end

    def method_missing(name, *args, &block)
      if name =~ /set_(.+)/
        configure($1, args[0], &block)
      else
        request(name, &block)
      end
    end

  end

  # The reservation manager handles the creation and storage of node groups and stores all relevant information
  # for the current experiment.
  # If you need to talk to a single node, call the ResverationManager.groupForNode(nodeUrn) method.
  # If you want a custom subset of nodes, call the ReservationManager.groupForNodes(nodeUrnArray) method.
  # For talking to all nodes, you can get the approprita group bei calling ReservationManager.allNodesGroup.
  class ReservationManager
    @@reservation
    @@nodeUrns
    @@nodeGroups
    @@reservationGroup

    # Initializes the reservation manager class and creates all needed wise groups
    #
    # TODO explain parameters here
    def self.init(reservation, nodeUrns)
      @@nodeGroups = {}
      @@reservation = reservation
      @@nodeUrns = nodeUrns
      @@reservationGroup = WisebedClient::WiseGroup.new('ReservationGroup', self.reservationID)
      # Creating the all nodes group:
      self.allNodesGroup

      # Creating the single node groups:
      @@nodeUrns.each { |node|
        self.groupForNode(node)
      }

    end

    # Creates and returns a group to use when interacting with an arbitrary subset of the all nodes set
    #
    # @param[Array, Set, #read] a list of nodes to get the group for.
    def self.groupForNodes(nodeUrns, name = nil)
      groupId = WiseOMFUtils::UIDHelper.node_group_uid(@@reservation, nodeUrns)
      if @@nodeGroups[groupId].nil?
        @@reservationGroup.group.topic.create(:wisebed_node, {urns: nodeUrns}, nil) { |msg|
          # TODO: update groupID (WiseGroup)
          info "Creation Callback: #{msg}"
        }
        if name.nil?
          @@nodeGroups[groupId] = WisebedClient::WiseGroup.new(nodeUrns.to_s, groupId)
        else
          @@nodeGroups[groupId] = WisebedClient::WiseGroup.new(name, groupId)
        end
      end
      @@nodeGroups[groupId]
    end

    # Returns a group to work with when interacting with all nodes of the reservation
    def self.allNodesGroup
      groupId = WiseOMFUtils::UIDHelper.node_group_uid(@@reservation, @@nodeUrns)
      if @@nodeGroups[groupId].nil?
        @@nodeGroups[groupId] = WisebedClient::WiseGroup.new('AllNodes', groupId)
      end
      @@nodeGroups[groupId]
    end

    # Returns a WiseGroup to talk to. This group should be used for interacting with single nodes.
    #
    # @param[String, #read] the node urn
    def self.groupForNode(nodeUrn)
      groupId = WiseOMFUtils::UIDHelper.node_group_uid(@@reservation, [nodeUrn])
      if @@nodeGroups[groupId].nil?
        @@nodeGroups[groupId] = WisebedClient::WiseGroup.new(nodeUrn, groupId)
      end
      @@nodeGroups[groupId]
    end

    # Getter for the reservation id of the current reservation
    def self.reservationID
      WiseOMFUtils::UIDHelper.reservation_uid(@@reservation)
    end


  end
end