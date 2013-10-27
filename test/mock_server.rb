require 'webrick'

module WankoTestHelpers
  class MockTransmission < WEBrick::HTTPServlet::AbstractServlet
    def initialize(server)
      super server

      @server = server
    end

    def do_POST(request, response)
      if request['X-Transmission-Session-Id'] == 'test_id'
        #must call body, otherwise it is not read
        request.body

        response.status = 200
      else
        response.status = 409
        response['X-Transmission-Session-Id'] = 'test_id'
      end

      @server.requests << request
      @server.responses << response
    end
  end

  class MockTransmissionWithAuth < MockTransmission
    def do_POST(request, response)
      WEBrick::HTTPAuth.basic_auth(request, response, 'torrent') do |user,pass|
        user == 'YUKI.N' && pass == 'sinzite'
      end
      super
    end
  end

  class MockTransmissionExpireSession < MockTransmission
    def do_POST(request, response)
      if @server.requests.length % 2 == 0
        response.status = 409
        response['x-Transmission-Session-Id'] = "session#{@server.requests.length}"
      else
        #must call body, otherwise it is not read
        request.body

        response.status = 200
      end

      @server.requests << request
      @server.responses << response
    end
  end

  SERVER = WEBrick::HTTPServer.new AccessLog: [], Logger: WEBrick::Log::new("/dev/null", 7), BindAddress: '127.0.0.1', Port: 9091
  SERVER.listen '127.0.0.1', 50091

  class << SERVER
    attr_accessor :requests, :responses
  end
  SERVER.requests = []
  SERVER.responses = []

  SERVER.mount '/transmission/rpc', MockTransmission
  SERVER.mount '/torrent/rpc', MockTransmission
  SERVER.mount '/transmission_with_auth/rpc', MockTransmissionWithAuth
  SERVER.mount '/transmission_expire_session', MockTransmissionExpireSession
end

