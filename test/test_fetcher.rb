require 'minitest/autorun'
require 'minitest/pride'

require 'fileutils'
require 'json'

require_relative '../lib/wanko/fetcher'

require_relative 'expected_data'

CONFIG_DIR = File.expand_path 'config', File.dirname(__FILE__)
ITEM_LOG = File.join CONFIG_DIR, 'read_items'

def get_item_log()
  log = JSON.parse File.read(ITEM_LOG)
  Hash[log.map {|feed,items| [File.basename(feed), items]}]
end

describe Wanko::Fetcher do
  alias :mute_stdout :capture_io

  before do
    @config = JSON.parse File.read(File.join CONFIG_DIR, 'config'), symbolize_names: true

    @config[:feeds] = @config[:feeds].map { |feed|
      File.expand_path File.join('feed_data', feed), File.dirname(__FILE__)
    }

    @fetcher = Wanko::Fetcher.new CONFIG_DIR, @config
  end

  after do
    File.delete ITEM_LOG rescue nil
  end

  describe 'when fetching torrents' do
    it 'follows the specified rules' do
      out, _ = capture_io {@fetcher.fetch}

      JSON.parse(out, symbolize_names: true).must_equal ExpectedData::FETCH
    end

    it 'does not fetch torrents from already read items' do
      mute_stdout do @fetcher.fetch end
      out, _ = capture_io {@fetcher.fetch}

      JSON.parse(out).must_equal []
    end

    it 'keeps track of read items' do
      mute_stdout do @fetcher.fetch end

      get_item_log.must_equal ExpectedData::ITEM_LOG
    end

    it 'can handle new feeds' do
      new_feed = File.expand_path File.join('feed_data', 'new_dummy'), File.dirname(__FILE__)
      @config[:feeds] << new_feed
      mute_stdout do @fetcher.fetch end

      get_item_log.must_include 'new_dummy'
    end
  end
end

