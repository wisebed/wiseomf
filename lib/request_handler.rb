require 'lrucache'
require 'set'
module RequestHandler
  attr_accessor :nodeUrns
  @@uniqueRequestIdentifier = 0
  @cache = LRUCache.new(ttl: 30.minutes)
  @nodeUrns = Set.new

  def requestId
    return @@uniqueRequestIdentifier += 1
  end

  def handle?(info)
    return !@cache.fetch(info[:requestId]).nil? || (info[:requestId].nil? && @nodeUrns == info[:nodeUrns])
  end

  def store(id, request, responses={})
    @cache.store(id, {request: request, responses: responses})
  end

  # returns true if the testbed has sent a response for all nodes
  def collection_complete?(id)
    return @cache.fetch(id)[:responses].count == @nodeUrns.count
  end

  def extract(payload)
    event = payload[:event]
    nodes = payload[:nodeUrns]
    id = payload[:requestId]
    unless id.nil?
      cached = @cache.fetch(id)
      responses = cached[:responses]
      req = cached[:request]
    else
      responses = nil
      req = nil
    end
    return id, req, responses, event, nodes
  end

  def build_inform(id, responses)
    return {requestId: id, responses: responses}
  end

end