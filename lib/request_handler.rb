require 'lrucache'
require 'set'
module RequestHandler
  attr_accessor :nodeUrns, :cache
  @@uniqueRequestIdentifier = 0
  @cache
  @nodeUrns

  def requestId
    return @@uniqueRequestIdentifier += 1
  end

  def handle_response?(info)
    return !self.cache.fetch(info[:requestId]).nil? || (info[:requestId].nil? && self.nodeUrns == info[:nodeUrns])
  end

  def handle_event?(info)
    eventUrns = info[:nodeUrns]
    return false if eventUrns.nil?
    intersection = self.nodeUrns & eventUrns
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
    self.cache.store(id, {request: request, responses: responses})
  end

  # returns true if the testbed has sent a response for all nodes
  def collection_complete?(id)
    responses = self.cache.fetch(id)[:responses]
    return false unless responses.count >= self.nodeUrns.count
    self.nodeUrns.each { |urn| return false unless responses.include? urn }
    return true

  end

  def extract(payload)
    event = payload[:event]
    nodes = payload[:nodeUrns]
    id = payload[:requestId]
    unless id.nil?
      cached = self.cache.fetch(id)
      unless cached.nil?
        responses = cached[:responses]
        req = cached[:request]
      end
    else
      responses = nil
      req = nil
    end
    return id, req, responses, event, nodes
  end

  def build_inform(id, responses, type = :response)
    cleaned_responses = []

    responses.each {|k,v|
      arr = {}
      arr[:nodeUrn] = k
      arr.merge!(v) {|key, v1, v2| v1 }
      cleaned_responses << arr
    }

    return {requestId: id, type: type, responses: cleaned_responses}
  end

end