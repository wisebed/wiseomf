require 'lrucache'
require 'wise_omf/uid_helper'
require 'yaml'
module WiseOMF
  module Client
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

      def initialize(name, uid, intOps = {})
        @callback_cache = LRUCache.new(ttl: 30.minutes)
        @name = name
        @uid = uid
        if intOps[:id]
          group = OmfEc::Group.new(intOps[:id], {unique: false})
        else
          group = OmfEc::Group.new(name)
        end
        OmfEc.experiment.add_group(group)
        group.add_resource(uid)
        @group = group

        #@group = OmfEc::Group.new(uid, {unique: false}) { |g|
        #  info "Created Group #{name}: #{g.to_yaml}"
        #
        #  #yield self unless block.nil?
        #
        #}
        #OmfEc.experiment.add_group(@group)
        #@group.add_resource(name)
        warn "Finished init"
      end

      def init_callback

        while @group.topic.nil?
          info "Delaying callback creation for 0.5 seconds"
          sleep 0.5
        end
        info "Setting message callback for #{self.name}"
        @group.topic.on_message(:inform_status) { |msg|
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

      end

      def request(property, &block)
        mid = WiseOMF::Client::ExperimentHelper.messageUID
        unless block.nil?
          @callback_cache.store(mid, block)
        end
        fail "Can't request topic here" if property.to_sym.eql? 'topic'.to_sym
        @group.topic.configure({property => mid})
      end

      def configure(property, value, &block)
        mid = WiseOMF::Client::ExperimentHelper.messageUID
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

      def delete_callback(requestId)
        @callback_cache.delete(requestId)
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
        @@reservationGroup = WiseOMF::Client::WiseGroup.new('ReservationGroup', self.reservationID)
        @@reservationGroup.init_callback
        # Creating the all nodes group:
        self.allNodesGroup

        # Creating the single node groups:
        @@nodeUrns.each { |node|
          self.groupForNode(node)
        }

      end

      def self.reservationGroup
        @@reservationGroup
      end

      def self.createGroupForNodes(nodeUrns, name = nil, &block)
        groupId = WiseOMFUtils::UIDHelper.node_group_uid(@@reservation, nodeUrns)
        if @@nodeGroups[groupId].nil?
          if name.nil?
            group = WiseOMF::Client::WiseGroup.new(nodeUrns.to_s, groupId)
          else
            group = WiseOMF::Client::WiseGroup.new(name, groupId)
          end
          @@nodeGroups[groupId] = group
          group.init_callback
          group.group.topic.on_message(:wait_for_membership) { |msg|
            if msg.properties.membership && msg.properties.membership.include?(group.group.address)
              info "New group setup finished"
              group.group.topic.on_message(:wait_for_membership) {}
              #group.init_callback
              block.call(group) if block
            end

          }
          @@reservationGroup.group.topic.create(:wisebed_node, {uid: groupId, urns: nodeUrns, membership: group.group.address})

        end
      end

      # Returns a group to use when interacting with an arbitrary subset of the all nodes set
      #
      # @param[Array, Set, #read] a list of nodes to get the group for.
      def self.groupForNodes(nodeUrns)
        groupId = WiseOMFUtils::UIDHelper.node_group_uid(@@reservation, nodeUrns)
        @@nodeGroups[groupId]
      end

      # Returns a group to work with when interacting with all nodes of the reservation
      def self.allNodesGroup
        groupId = WiseOMFUtils::UIDHelper.node_group_uid(@@reservation, @@nodeUrns)
        if @@nodeGroups[groupId].nil?
          @@nodeGroups[groupId] = WiseOMF::Client::WiseGroup.new('AllNodes', groupId)
          @@nodeGroups[groupId].init_callback
        end
        @@nodeGroups[groupId]
      end

      # Returns a WiseGroup to talk to. This group should be used for interacting with single nodes.
      #
      # @param[String, #read] the node urn
      def self.groupForNode(nodeUrn)
        groupId = WiseOMFUtils::UIDHelper.node_group_uid(@@reservation, [nodeUrn])
        if @@nodeGroups[groupId].nil?
          @@nodeGroups[groupId] = WiseOMF::Client::WiseGroup.new(nodeUrn, groupId)
          @@nodeGroups[groupId].init_callback
        end
        @@nodeGroups[groupId]
      end

      # Getter for the reservation id of the current reservation
      def self.reservationID
        WiseOMFUtils::UIDHelper.reservation_uid(@@reservation)
      end


    end
  end
end
