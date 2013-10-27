require 'json'
require 'net/http'

require_relative 'exceptions'

module Wanko
  module Downloaders
    module Stdout
      def download(torrents)
        $stdout.write JSON.pretty_generate(torrents)
      end
    end

    module Transmission
      def download(torrents)
        defaults = {
                     host: '127.0.0.1',
                     port: 9091,
                     path: '/transmission/'
                   }
        conf = defaults.merge @config[:torrent_client]

        use_auth = conf[:user] || conf[:password]

        url = URI("http://#{conf[:host]}:#{conf[:port]}#{conf[:path]}rpc")

        Net::HTTP.start url.host, url.port do |daemon|
          session_id = nil

          torrents.each do |torrent|
            body = {
                     "method" => "torrent-add",
                     "arguments" => {
                       "filename" => torrent[:link],
                       "download-dir" => torrent[:dir]
                     }
                   }

            request = Net::HTTP::Post.new url
            request.body = JSON.generate body
            request['X-Transmission-Session-Id'] = session_id
            request.basic_auth conf[:user], conf[:password] if use_auth

            response = daemon.request request

            case response
            when Net::HTTPConflict
              session_id = response['X-Transmission-Session-Id']
              redo
            when Net::HTTPUnauthorized
              raise Wanko::AuthError, 'Authorisation failed, please check your username and password.'
            when Net::HTTPNotFound
              raise Wanko::PathError, "Path '#{conf[:path]}' not found, please check your path settings."
            end
          end
        end

      rescue Errno::ECONNREFUSED
        raise Wanko::ConnectionError, "Couldn't connect to Transmission at #{url}. Please check your host and port settings, and make sure that the daemon is running."
      end
    end
  end
end

