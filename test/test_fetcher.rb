require 'minitest/autorun'
require 'minitest/pride'

require 'json'
require 'fileutils'

require_relative '../lib/wanko/fetcher'

require_relative 'expected_data'

CONFIG_DIR = File.expand_path 'config', File.dirname(__FILE__)
ITEM_LOG = File.join CONFIG_DIR, 'read_items'
OUTPUT = File.join CONFIG_DIR, 'output.json'

def get_output()
  JSON.parse File.read(OUTPUT), symbolize_names: true
end

def get_item_log()
  log = JSON.parse File.read(ITEM_LOG)
  Hash[log.map {|feed,items| [File.basename(feed), items]}]
end

describe Wanko::Fetcher do
  before do
    @config = JSON.parse File.read(File.join CONFIG_DIR, 'config'), symbolize_names: true

    @config[:feeds] = @config[:feeds].map { |feed|
      File.expand_path File.join('feed_data', feed), File.dirname(__FILE__)
    }

    @fetcher = Wanko::Fetcher.new CONFIG_DIR, @config
    @fetcher.fetch
  end

  after do
    [ITEM_LOG, OUTPUT].each do |f|
      File.delete f if File.exist? f
    end
  end

  it 'fetches torrents according to the specified rules' do
    get_output.must_equal ExpectedData::FETCH
  end

  it 'keeps track of read items' do
    get_item_log.must_equal ExpectedData::READ_ITEMS
  end

  it 'does not fetch torrents from already read items' do
    File.delete OUTPUT
    @fetcher.fetch

    get_output.must_equal []
  end

  it 'can handle new feeds' do
    new_feed = File.expand_path File.join('feed_data', 'new_dummy'), File.dirname(__FILE__)
    @config[:feeds] << new_feed
    @fetcher.fetch

    get_item_log.must_include 'new_dummy'
  end
end

