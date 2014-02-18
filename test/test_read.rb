require 'minitest/autorun'
require 'minitest/pride'

require 'fileutils'
require 'rss'

require 'wanko/fetch'
require 'wanko/read'

module Wanko
  module Fetch
    def self.fetcher_for(client)
      client
    end
  end
end

class TestRead < MiniTest::Unit::TestCase
  def test_config()
    # Empty config file
    FileUtils.touch File.join('config', 'config.yaml')

    result_empty = Wanko::Read.config 'config'

    expected_empty = {
      feeds: [],
      base_dir: File.join(Dir.home, 'downloads'),
      fetcher: {name: 'stdout'},
      rules: []
    }

    assert_equal expected_empty, result_empty

    # Full config file
    FileUtils.cp File.join('config', 'full_config.yaml'), File.join('config', 'config.yaml')

    result_full = Wanko::Read.config 'config'
    
    expected_full = {
      feeds: ['http://www.example.com/rss', 'http://www.example.org/more_rss'],
      base_dir: '/home/example/downloads',
      fetcher: {
        name: 'transmission',
        host: '127.0.0.1',
        port: 9091,
        path: '/transmission/',
        user: 'yuki',
        password: 'sinzite'
      },
      rules: [
        {regex: /Example Podcast/i, dir: '/home/example/downloads'},
        {regex: /.*\[FOSS\].*/i, dir: File.join('/home/example/downloads', 'foss/new')},
        {regex: /\[INDIE\] Colonel Panic and the Segfaults/i, dir: '/data/music/colonel_panic_and_the_segfaults'}
      ]
    }

    assert_equal expected_full, result_full

  ensure
    FileUtils.rm File.join('config', 'config.yaml')
  end

  def test_convert_rule()
    rule = {regex: '.*Eruruu.*', dir: 'utawarerumono'}

    result = Wanko::Read.convert_rule rule, '/test/downloads'

    expected = {
      regex: /.*Eruruu.*/i,
      dir: File.absolute_path('utawarerumono', '/test/downloads')
    }

    assert_equal expected, result
  end

  def test_history()
    Wanko::Read.history('config')
  end

  def test_feed()
    capture_io do
      assert_nil Wanko::Read.feed 'http://this.is.not.a.url'

      # This should 404
      assert_nil Wanko::Read.feed 'http://www.example.com/rss'
    end

    assert_kind_of RSS::Rss, Wanko::Read.feed('feed_data/tokyo_toshokan.rss')
  end
end

