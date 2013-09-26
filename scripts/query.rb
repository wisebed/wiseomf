# loading config hash from file
require 'java'
require 'yaml'
CONFIG = YAML.load_file "../config.yml"

# Use omf_common communicator directly
require 'omf_common'

# As seen previously, this init will set up various run time options for you.
#
# First line simply indicates:
# * Use :development as default environment,
#   this will use Eventmachine by default, set logging level to :debug
# * Use XMPP as default communication layer and XMPP server to connect to defined in the config.yml (:xmpp_url)
# * By default username:password will be auto generated
#
# OmfCommon.comm returns a communicator instance,
# and this will be your entry point to interact with XMPP server.
#
# OmfCommon.eventloop returns Eventmachine runtime instance since it is default.
#
OmfCommon.init(CONFIG[:env], communication: { url: CONFIG[:xmpp_url] }) do
  # Event :on_connected will be triggered when connected to XMPP server
  #
  info "Here"
  OmfCommon.comm.on_connected do |comm|
    info "Engine test script >> Connected to XMPP"

    comm.subscribe('wisebed') do |wisebed|
      unless wisebed.error?
        # Request three properties from garage, :node_type, :position and :sensors
        #
        # This is asynchronous, the reply_msg will only get processed when wiserp received the request
        # and we actually received the inform message it issued.
        #
        # Once we got the reply, simply iterate the properties and print them
        #
        wisebed.request([:node_type, :position, :sensors]) do |reply_msg|
          reply_msg.each_property do |k, v|
            info "#{k} >> #{v}"
          end
        end
      else
        error wisebed.inspect
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
