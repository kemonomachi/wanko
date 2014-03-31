require 'minitest/autorun'
require 'minitest/pride'

require 'fileutils'

require 'wanko/wanko'
require 'wanko/read'

require_relative 'expected_data'

class TestWanko < MiniTest::Unit::TestCase
  def test_match()
    FileUtils.cp 'config/real_config.yaml', 'config/config.yaml'

    feed = Wanko::Read.feed 'feed_data/tokyo_toshokan.rss'
    config = Wanko::Read.config 'config'
    history = Wanko::Read.history 'config'

    result = Wanko.match(feed, config[:rules], history['http://www.tokyotosho.info/rss.php?filter=7']).map &:to_h

    assert_equal EXPECTED::Match, result

  ensure
    FileUtils.rm 'config/config.yaml'
  end
end

