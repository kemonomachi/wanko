require 'minitest/autorun'
require 'minitest/pride'

require 'json'

require_relative '../lib/wanko/fetcher'
require_relative '../lib/wanko/exceptions'

require_relative 'mock_server.rb'

SERVER_THREAD = Thread.new {
  Thread.current[:server] = WankoTestHelpers::SERVER

  Thread.current[:server].start
}

describe Wanko::Downloaders::Transmission do
  before do
    @config_dir = File.expand_path 'config', File.dirname(__FILE__)
    config_file = File.join @config_dir, 'config'
    @config = JSON.parse File.read(config_file), symbolize_names: true

    @config[:torrent_client] = {name: 'transmission'}

    @fetcher = Wanko::Fetcher.new @config_dir, @config

    @server = SERVER_THREAD[:server]
  end

  after do
    @server.requests.clear
    @server.responses.clear
  end

  it 'can substitue defaults for all options' do
    @fetcher.download [{link: 'link', dir: 'dir'}]

    @server.requests.length.must_equal 2
  end

  it 'can connect using custom host, port and path' do
    @config[:torrent_client] = {
                                 name: 'transmission',
                                 host: 'localhost',
                                 port: 50091,
                                 path: '/torrent/'
                               }

    @fetcher.download [{link: 'link', dir: 'dir'}]
    
    @server.requests.length.must_equal 2
  end

  it 'can connect using Basic authentication' do
    @config[:torrent_client] = {
                                 name: 'transmission',
                                 path: '/transmission_with_auth/',
                                 user: 'YUKI.N',
                                 password: 'sinzite'
                               }

    @fetcher.download [{link: 'link', dir: 'dir'}]

    @server.responses.map {|res| res.status}.must_equal [409, 200]
  end

  it 'can handle expiration of the session token' do
    @config[:torrent_client][:path] = '/transmission_expire_session/'

    @fetcher.download [1,2].map {|n| {link: "link#{n}", dir: "dir#{n}"}}

    result = @server.requests.map {|req| req['X-Transmission-Session-Id']}
    
    result.must_equal [nil, 'session0', 'session0', 'session2']
  end

  it 'sends correct rpc commands' do
    @fetcher.download [1,2,3].map {|n| {link: "link#{n}", dir: "dir#{n}"}}

    expected = [1,2,3].map { |n|
      {
        "method" => "torrent-add",
        "arguments" => {
          "filename" => "link#{n}",
          "download-dir" => "dir#{n}"
        }
      }
    }

    @server.requests[1..-1].map {|req| JSON.parse req.body}.must_equal expected
  end

  it 'raises an AuthError when using the wrong credentials' do
    @config[:torrent_client] = {
                                 name: 'transmission',
                                 path: '/transmission_with_auth/',
                                 user: 'kyon',
                                 password: 'yareyare'
                               }
    
    bad_auth = proc {@fetcher.download [{link: 'link', dir: 'dir'}]}

    bad_auth.must_raise Wanko::AuthError
  end

  it 'raises a ConnectionError when trying to connect using the wrong host' do
    @config[:torrent_client][:host] = '127.0.0.13'

    bad_host = proc {@fetcher.download [{link: 'link', dir: 'dir'}]}

    bad_host.must_raise Wanko::ConnectionError
  end

  it 'raises a ConnectionError when trying to connect using the wrong port' do
    @config[:torrent_client][:port] = 52145

    bad_port = proc {@fetcher.download [{link: 'link', dir: 'dir'}]}

    bad_port.must_raise Wanko::ConnectionError
  end

  it 'raises a ConnectionError when trying to connect using the wrong path' do
    @config[:torrent_client][:path] = '/bad_path/'

    bad_path = proc {@fetcher.download [{link: 'link', dir: 'dir'}]}

    bad_path.must_raise Wanko::PathError
  end
end

Minitest.after_run do
  SERVER_THREAD[:server].shutdown
  SERVER_THREAD.join
end

