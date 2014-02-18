require 'net/http'

module Mock
  class Transmission
    def initialize()
      @requests = []
    end

    attr_reader :requests

    def request(req)
      @requests << req

      response = if req['X-Transmission-Session-Id'] != 'OK'
        Net::HTTPConflict.new nil, '409', 'Conflict'
      else
        Net::HTTPOK.new nil, '200', 'OK'
      end

      response['X-Transmission-Session-Id'] = 'OK'

      response
    end
  end
end
