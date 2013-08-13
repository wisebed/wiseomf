# Use omf_common communicator directly
require 'omf_common'

# loading config hash from file
CONFIG = YAML.load_file "../config.yml"

# As seen previously, this init will set up various run time options for you.
#
# First line simply indicates:
# * Use :development as default environment,
#   this will use Eventmachine by default, set logging level to :debug
# * Use XMPP as default communication layer and XMPP server to connect to is localhost
# * By default username:password will be auto generated
#
# OmfCommon.comm returns a communicator instance,
# and this will be your entry point to interact with XMPP server.
#
# OmfCommon.eventloop returns Eventmachine runtime instance since it is default.
#
OmfCommon.init(:development, communication: { url: CONFIG[:xmpp_url] }) do
  # Event :on_connected will be triggered when connected to XMPP server
  #
  OmfCommon.comm.on_connected do |comm|
    info "Engine test script >> Connected to XMPP"

    # Subscribe to a XMPP topic represents :garage, the name was set in the controller code if you wonder.
    # Once triggered, it will yield a Topic object.
    #
    comm.subscribe('garage') do |garage|
      unless garage.error?
        # Request two properties from garage, :uid and :type
        #
        # This is asynchronous, the reply_msg will only get processed when garage received the request
        # and we actually received the inform message it issued.
        #
        # Once we got the reply, simply iterate two properties and print them
        #
        garage.request([:uid, :type]) do |reply_msg|
          reply_msg.each_property do |k, v|
            info "#{k} >> #{v}"
          end
        end
      else
        error garage.inspect
      end
    end

    # Eventloop allows to control the flow, in this case, we disconnect after 5 seconds.
    #
    OmfCommon.eventloop.after(5) { comm.disconnect }
    # If you hit ctrl-c, we will disconnect too.
    #
    comm.on_interrupted { comm.disconnect }
  end
end
