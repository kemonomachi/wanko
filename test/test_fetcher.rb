require 'minitest/autorun'
require 'minitest/pride'

require 'json'
require 'fileutils'

require_relative '../lib/wanko/fetcher'

require_relative 'expected_data'

describe Wanko::Fetcher do
  before do
    @config_dir = 'config'
    @config = JSON.parse File.read(File.join @config_dir, 'config'), symbolize_names: true
    @fetcher = Wanko::Fetcher.new @config_dir, @config
  end

  after do
    ['output.json', File.join(@config_dir, 'read_items')].each do |f|
      File.delete f if File.exist? f
    end
  end

  it 'fetches torrents according to the specified rules' do
    @fetcher.fetch
    
    output = JSON.parse File.read('output.json'), symbolize_names: true

    output.must_equal ExpectedData::FETCH
  end

  it 'keeps track of read items' do
    @fetcher.fetch

    read_items = JSON.parse File.read(File.join @config_dir, 'read_items')

    read_items.must_equal ExpectedData::READ_ITEMS
  end

  it 'does not fetch torrents from already read items' do
    @fetcher.fetch
    File.delete 'output.json'
    @fetcher.fetch

    output = JSON.parse File.read('output.json'), symbolize_names: true

    output.must_equal []
  end

  it 'can handle new feeds' do
    @config[:feeds] << 'feed_data/new_dummy'
    @fetcher.fetch

    read_items = JSON.parse File.read(File.join @config_dir, 'read_items')

    read_items.must_include 'feed_data/new_dummy'
  end
end

