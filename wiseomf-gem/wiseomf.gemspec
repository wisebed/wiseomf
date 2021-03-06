Gem::Specification.new do |s|
  s.name        = 'wise_omf'
  s.version     = '0.9.4'
  s.date        = '2013-12-22'
  s.summary     = 'WiseOMF Utility Gem'
  s.description = 'This gem provides helpers for working with the testbed runtime via the OMF (Orbit Measurement Framework)'
  s.authors     = ['Tobias Mende']
  s.email       = 'mendet@informatik.uni-luebeck.de'
  s.files       = %w(lib/wise_omf.rb lib/wise_omf/protobuf.rb lib/wise_omf/server.rb lib/wise_omf/client.rb lib/wise_omf/uid_helper.rb lib/wise_omf/protobuf/external-plugin-messages.pb.rb lib/wise_omf/protobuf/internal-messages.pb.rb lib/wise_omf/protobuf/iwsn-messages.pb.rb)
  s.homepage    = 'https://github.com/wisebed/wiseomf'
  s.license     = 'MIT'
end