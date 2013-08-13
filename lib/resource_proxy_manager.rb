# This init method will set up your run time environment,
# communication, eventloop, logging etc. We will explain that later.
#
OmfCommon.init(CONFIG[:env], communication: { url: CONFIG[:xmpp_url] }) do
  OmfCommon.comm.on_connected do |comm|
    info "ResourceProxyManager >> Connected to XMPP server"
    rpm = []
    rpm << OmfRc::ResourceFactory.create(:wiserp, uid: 'wisebed')


    comm.on_interrupted {
      rpm.each {|r| r.disconnect}
    }
  end
end