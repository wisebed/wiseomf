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

  def handle_response?(info)
    return !@cache.fetch(info[:requestId]).nil? || (info[:requestId].nil? && @nodeUrns == info[:nodeUrns])
  end

  def handle_event?(info)
    eventUrns = info[:nodeUrns]
    return false if eventUrns.nil?
    intersection = @nodeUrns & eventUrns
    return !intersection.empty?
  end

  def handle?(info)
    unless info[:requestId].nil?
      return handle_response?(info)
    else
      return handle_event?(info)
    end
  end

  def store(id, request, responses={})
    @cache.store(id, {request: request, responses: responses})
  end

  # returns true if the testbed has sent a response for all nodes
  def collection_complete?(id)
    responses = @cache.fetch(id)[:responses]
    return false unless responses.count >= @nodeUrns.count
    @nodeUrns.each {|urn| return false unless responses.include? urn }
    return true

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