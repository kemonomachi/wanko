require 'json'
require 'net/http'
require 'open-uri'
require 'yaml'

require 'wanko/exception'
require 'wanko/utility'

module Wanko
  
  # Functions for fetching torrents in different ways. Several functions have
  # side-effects, and ::fetcher_for returns Lambdas that have side-effects.
  module Fetch

    # Public: Create a lambda that fetches torrents when called.
    #
    # config - Hash with options for how to fetch torrents. :name is always
    #          required and should be one of 'stdout', 'watchdir' and
    #          'transmission'. Other options vary depending on the value of
    #          :name, as follows:
    #
    #          name: 'stdout'
    #            :format - Serialization format. See ::serialize for values.
    #          name: 'transmission'
    #            :host     - The daemon's host
    #            :port     - The daemon's port
    #            :path     - The daemon's path.
    #            :user     - Username for Basic auth (optional)
    #            :password - Password for Basic auth (optional)
    #
    # Returns a fetcher Lambda.
    # Raises Wanko::ConfigError if :name option is not recognized.
    def self.fetcher_for(config)
      case config[:name]
      when 'stdout'
        ->(torrents) {$stdout.puts serialize(config[:format], torrents)}
      when 'watchdir'
        ->(torrents) {to_watchdir torrents}
      when 'transmission'
        url = make_transmission_url config[:host], config[:port], config[:path]
   
        auth = if config[:user] || config[:password]
          config.select {|k, _| [:user, :password].include? k}
        end

        ->(torrents) {to_transmission url, auth, torrents}
      else
        raise Wanko::ConfigError, "Invalid fetcher name '#{config[:name]}'"
      end
    end

    # Internal: Serialize torrents for the stdout fetcher.
    #
    # format   - Name of serialization method to use. Should be either 'json',
    #            'simple' or 'yaml'.
    # torrents - Torrents to serialize.
    #
    # Returns a String representation of torrents, in the given format.
    # Raises Wanko::ConfigError if format is not recognized.
    def self.serialize(format, torrents)
      case format
      when 'json'
        torrents.to_json
      when 'simple'
        torrents.map {|t| t[:link]}.join "\n"
      when 'yaml', nil
        Utility.stringify_keys(torrents).to_yaml
      else
        raise Wanko::ConfigError, "Invalid format '#{format}' for stdout fetcher."
      end
    end

    # Internal: Download torrent files to watch directories. Creates any
    # nonexisting directories.
    #
    # torrents - Torrents to download.
    #
    # Returns nothing.
    def self.to_watchdir(torrents)
      torrents.each do |tor|
        FileUtils.mkdir_p tor[:dir]
        
        open tor[:link] do |rem|
          File.binwrite File.join(tor[:dir], "#{tor[:name]}.torrent"), rem.read
        end
      end
    end

    # Internal: Send RPC commands to Transmission daemon for downloading
    # torrents.
    #
    # url      - URI object containing the URL of the daemon
    # auth     - Hash with :user and :password for Basic auth, or falsey value
    #            for no authorization.
    # torrents - Array of torrents to download.
    #
    # Returns nothing.
    def self.to_transmission(url, auth, torrents)
      return if torrents.empty?

      requests = torrents.map {|torrent| make_post_request url, make_transmission_rpc_command(torrent), auth}

      Net::HTTP.start url.host, url.port do |transmission|
        send_transmission_requests transmission, requests
      end
    end

    # Internal: Send requests to a Transmission daemon. If a 409 Conflict
    # response is recieved, update the 'X-transmission-Session-Id' header of
    # the request and resend it.
    #
    # transmission - Net::HTTP connection to a Transmission daemon.
    # reqs         - Net::HTTP::Post requests to send to Transmission.
    #
    # Returns nothing.
    def self.send_transmission_requests(transmission, reqs)
      session_id = ''

      reqs.each do |req|
        req['X-Transmission-Session-Id'] = session_id

        response = transmission.request req

        case response
        when Net::HTTPConflict
          session_id = response['X-Transmission-Session-Id']
          redo
        end
      end
    end

    # Internal: Create a URI object for a Transmission daemon URL.
    #
    # host - Host part of the URL.
    # port - Port part of the URL.
    # path - Path part of the URL.
    #
    # Returns a URI object.
    def self.make_transmission_url(host, port, path)
      URI::HTTP.build host: host || '127.0.0.1', 
                      port: port || 9091, 
                      path: "#{path || '/transmission/'}rpc"
    end

    # Internal: Generate a JSON-encoded 'torrent-add' RPC command that can be
    # sent to a Transmission daemon.
    #
    # torrent - Torrent to generate command for. Should contain :link and :dir.
    #
    # Returns a String RPC command.
    def self.make_transmission_rpc_command(torrent)
      JSON.generate(
        {
          "method" => "torrent-add",
          "arguments" => {
            "filename" => torrent[:link],
            "download-dir" => torrent[:dir]
          }
        }
      )
    end

    # Internal: Create an HTTP POST request.
    #
    # url  - URL this request will be sent to.
    # body - String with body data.
    # auth - Hash with Basic auth data, or falsey value for no authorization.
    #
    # Returns a Net::HTTP::Post request
    def self.make_post_request(url, body, auth)
      request = Net::HTTP::Post.new url
      request.body = body
      request.basic_auth auth[:user], auth[:password] if auth
      request
    end
  end
end

