require 'minitest/autorun'
require 'minitest/pride'

require 'fileutils'
require 'json'
require 'set'
require 'yaml'

require 'fakeweb'
require_relative 'mock'

require 'wanko/fetch'
require 'wanko/utility'

class TestFetch < MiniTest::Unit::TestCase
  def setup()
    @torrents = [
      {name: 'test1', link: 'http://www.test.com/1', dir: 'temp'},
      {name: 'test2', link: 'http://www.test.com/2', dir: 'temp'}
    ]
  end

  def test_fetcher_for()
    result_stdout = Wanko::Fetch.fetcher_for name: 'stdout', format: 'yaml'
    result_watchdir = Wanko::Fetch.fetcher_for name: 'watchdir'
    result_transm = Wanko::Fetch.fetcher_for name: 'transmission', host: '127.0.0.1', port: 9091, path: '/transmission/'

    assert result_transm.binding.local_variable_defined? :url

    assert_raises(Wanko::ConfigError) do
      Wanko::Fetch.fetcher_for name: 'bad_fetcher'
    end
  end

  def test_serialize()
    results = ['json', 'simple', 'yaml', nil].inject({}) { |memo, format|
      memo.merge format => Wanko::Fetch.serialize(format, @torrents)
    }

    assert_equal @torrents, JSON.parse(results['json'], symbolize_names: true)
    assert_equal @torrents.map {|t| t[:link]}.to_set, Set[*results['simple'].split("\n")]
    assert_equal @torrents, Wanko::Utility.symbolize_keys(YAML.load(results['yaml']))
    assert_equal @torrents, Wanko::Utility.symbolize_keys(YAML.load(results[nil]))

    assert_raises(Wanko::ConfigError) do
      Wanko::Fetch.serialize 'bad_format', @torrents
    end
  end

  def test_to_watchdir()
    FakeWeb.allow_net_connect = false
    FakeWeb.register_uri :any, 'http://www.test.com/1', body: "Response #1"
    FakeWeb.register_uri :any, 'http://www.test.com/2', body: "Response #2"

    Wanko::Fetch.to_watchdir @torrents

    assert_equal 'Response #1', File.read('temp/test1.torrent')
    assert_equal 'Response #2', File.read('temp/test2.torrent')

  ensure
    FileUtils.rm_r 'temp'
  end

  def test_send_transmission_requests()
    requests = (1..5).map {Wanko::Fetch.make_post_request 'http://www.test.com', '', nil}

    transmission = Mock::Transmission.new

    Wanko::Fetch.send_transmission_requests transmission, *requests

    assert_equal transmission.requests.length, 6
    assert_same transmission.requests[0], transmission.requests[1]
    assert transmission.requests.all? { |req|
      req['X-Transmission-Session-Id'] == 'OK'
    }
  end

  def test_make_transmission_url()
    result = Wanko::Fetch.make_transmission_url '127.0.0.1', 9091, '/transmission/'

    assert_equal '127.0.0.1', result.host
    assert_equal 9091, result.port
    assert_equal '/transmission/rpc', result.path
  end

  def test_make_transmission_rpc_command()
    torrent = @torrents.first

    result = Wanko::Fetch.make_transmission_rpc_command(torrent)

    expected = {
      "method" => "torrent-add",
      "arguments" => {
        "filename" => torrent[:link],
        "download-dir" => torrent[:dir]
      }
    }

    assert_equal expected, JSON.parse(result)
  end

  def test_make_post_request()
    url = 'http://www.test.com'
    body = 'test'
    auth = {user: 'yuki', password: 'sinzite'}

    result = Wanko::Fetch.make_post_request url, body, nil

    assert_equal body, result.body
    assert_nil result['authorization']

    result_with_auth = Wanko::Fetch.make_post_request url, body, auth

    refute_nil result_with_auth['authorization']
  end
end

