require 'lrucache'
require 'wise_omf/uid_helper'
require 'yaml'
require 'omf_common'
module WiseOMF
  module Client

    # The ExperimentHelper offers helper methods for the experiment.
    class ExperimentHelper
      @@random = Random.new
      @@uid_cache = LRUCache.new(ttl: 30.minutes)


      # Create an unique message id
      # NOTE: Message ids are guaranteed to be unique within 30 minutes.
      #
      # @return [Integer] an integer which can be used as messageUID.
      #   This integer is guaranteed to be unique within 30 minutes.
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


      # Creates a new WiseGroup which handles an OmfEc::Group for the given name And connects the resource with the given uid.
      # Speaking in OMF, the resource represented by the given uid becomes a member of the newly created Group.
      # The WiseGroup encapsulates the OMF group and handles the proper registration of callbacks for configure and request messages.
      #
      # However, you are free to use the OmfEc::Group directly, but it's highly recommended to use a WiseGroup as helper.
      #
      # @param name [String] the name for the OmfEc::Group.
      # @param uid [String] the uid of the resource represented by this group.
      #
      # @see OmfEc::Group
      def initialize(name, uid)
        @callback_cache = LRUCache.new(ttl: 30.minutes)
        @name = name
        @uid = uid
        group = OmfEc::Group.new(name)
        OmfEc.experiment.add_group(group)
        group.add_resource(uid)
        @group = group
        info "Finished intialization of WiseGroup (#{name})"
      end

      # This method initializes the callback handler on the group topic.
      # The topic might be nil direct after the intialization.
      #
      # @param block a block that should be called after initializing the topic callback
      def init_callback(&block)
        if @group.topic.nil?
          info "Delaying callback creation for 1 seconds"
          OmfCommon.el.after(1) {
            info "Firing"
            init_callback(&block)
          }
          return
        end
        info "Setting message callback for WiseGroup (#{self.name})"
        @group.topic.on_message(:wise_group_callback_handler) { |msg|
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
        info "Callback: #{block}"
        block.call(self) if block

      end

      # Send a request message for the given property and callback
      #
      # @param property [String] the property to request
      # @param &block the callback to be called for responses to this request
      def request(property, &block)
        mid = WiseOMF::Client::ExperimentHelper.messageUID
        unless block.nil?
          @callback_cache.store(mid, block)
        end
        fail "Can't request topic here" if property.to_sym.eql? 'topic'.to_sym
        @group.topic.configure({property => mid})
      end

      # Send a configure message for the given property and callback
      #
      # @param property [String] the property to configure
      # @param &block the callback to be called for responses to this configuration attempt
      def configure(property, value, &block)
        mid = WiseOMF::Client::ExperimentHelper.messageUID
        unless block.nil?
          @callback_cache.store(mid, block)
        end
        @group.topic.configure({property => {requestId: mid, value: value}})
      end

      # This method translates calls to configure_xxx and request_xxx into proper FRCP messages (like in the OMF)
      #
      # @param name [String] the name of the method
      # @param *args [Array] an array of arguments (empty for request_xxx, containing one argument for configure_xxx)
      # @param &block a block which should be set as callback for the request/ configure message
      def method_missing(name, *args, &block)
        if name =~ /set_(.+)/
          configure($1, args[0], &block)
        else
          request(name, &block)
        end
      end

      # Method for deleting a callback from the callback cache.
      # After deleting the callback, it will not be called for messages arriving with the given requestId
      #
      # @param requestId [Integer] the requestId to delete the callback for
      def delete_callback(requestId)
        @callback_cache.delete(requestId)
      end

      # Terminates this group (unsubscribes topic...)
      def done
        self.group.topic.unsubscribe(:wise_group_callback_handler)
      end

    end

    # The reservation manager handles the creation and storage of node groups and stores all relevant information
    # for the current experiment. The manager is designed as factory, so that it only exists once in the experiment.
    # If you need to talk to a single node, call the ResverationManager.groupForNode(nodeUrn) method.
    # If you want a custom subset of nodes, call the ReservationManager.groupForNodes(nodeUrnArray) method.
    # For talking to all nodes, you can get the approprita group bei calling ReservationManager.allNodesGroup.
    class ReservationManager
      @@reservation
      @@nodeUrns
      @@nodeGroups
      @@reservationGroup

      # Initializes the reservation manager class and creates the following WiseGroups:
      #   - The allNodesGroup (containing all nodes of this reservation)
      #   - One node group for each single node
      #   - One group for the reservation itself
      #
      # @param reservation [Hash] a hash explaining by the following YAML example:
      #     ---
      #     :secretReservationKeys:
      #       - :nodeUrnPrefix: "urn:wisebed:uzl1:"
      #         :key: "7601BE4781736B57BC6185D1AAF33A9F"
      #       - :nodeUrnPrefix: "..."
      #         :key: "..."
      # @param nodeUrns [Set, Array] a set of node urns beeing part of this reservation.
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
          info 'Creating new group'
          group.init_callback {
            info 'Topic initialized'
            group.group.topic.on_message(:wait_for_membership) { |msg|
              info "Wait for Membership: #{msg.to_yaml}"
              if msg.properties.membership && msg.properties.membership.include?(group.group.address)
                info 'New group setup finished'
                group.group.topic.unsubscribe(:wait_for_membership)
                block.call(group) if block
              end

            }
            @@reservationGroup.group.topic.create(:wisebed_node, {uid: groupId, urns: nodeUrns, membership: group.group.address})
          }


        end
      end

      # Returns a group to use when interacting with an arbitrary subset of the all nodes set
      #
      # @param nodeUrns [Array, Set, #read] a list of nodes to get the group for.
      # @return [WiseOMF::Client::WiseGroup] the WiseGroup for the node urns if one was found, nil otherwise
      def self.groupForNodes(nodeUrns)
        groupId = WiseOMFUtils::UIDHelper.node_group_uid(@@reservation, nodeUrns)
        @@nodeGroups[groupId]
      end

      # Returns a group to work with when interacting with all nodes of the reservation
      #
      # @return [WiseOMF::Client::WiseGroup] the group containing the resource representing all nodes in the reservation
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
      # @return[WiseOMF::Client::WiseGroup] the group for a single resource
      def self.groupForNode(nodeUrn)
        groupId = WiseOMFUtils::UIDHelper.node_group_uid(@@reservation, [nodeUrn])
        if @@nodeGroups[groupId].nil?
          @@nodeGroups[groupId] = WiseOMF::Client::WiseGroup.new(nodeUrn, groupId)
          @@nodeGroups[groupId].init_callback
        end
        @@nodeGroups[groupId]
      end

      # Getter for the reservation id of the current reservation
      # @return[String] the reservation id for this reservation
      def self.reservationID
        WiseOMFUtils::UIDHelper.reservation_uid(@@reservation)
      end

      # Finalizes all node groups and the reservation group.
      # Call this method at the end of your experiment just before calling OmfEc::Experiment.done
      def self.done
        info 'Cleaning Reservation Resources'
        @@nodeGroups.each_value { |group| group.done }
        @@reservationGroup.done
      end


    end
  end
end
