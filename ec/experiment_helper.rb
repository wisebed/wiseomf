require 'lrucache'
module WisebedClient
  class ExperimentHelper
    @@random = Random.new
    @@uid_cache = LRUCache.new(ttl: 30.minutes)
    @@callback_cache = LRUCache.new(ttl: 30.minutes)

    def self.messageUID
      uid = -1
      while true
        uid = @@random.rand(1.844674407e+19)
        break if @@uid_cache.fetch(uid).nil?
      end
      @@uid_cache.store(uid, 1)
      return uid
    end

  end
end