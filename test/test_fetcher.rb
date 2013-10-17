require 'minitest/autorun'
require 'minitest/pride'

require 'json'

require_relative '../lib/wanko/fetcher'

require_relative 'expected_data'

describe Wanko::Fetcher do
  before do
    @config_dir = 'config'
    @config = JSON.parse File.read(File.join @config_dir, 'config'), symbolize_names: true
  end

  after do
    ['output.json', File.join(@config_dir, 'read_items')].each do |f|
      File.delete f if File.exist? f
    end
  end

  it 'fetches torrents according to the specified rules' do
    Wanko::Fetcher.new(@config_dir, @config).fetch
    
    output = JSON.parse File.read('output.json'), symbolize_names: true

    output.must_equal ExpectedData::FETCH
  end

  it 'keeps track of read items' do
    Wanko::Fetcher.new(@config_dir, @config).fetch

    read_items = JSON.parse File.read(File.join @config_dir, 'read_items')

    read_items.must_equal ExpectedData::READ_ITEMS
  end

  it 'does not fetch torrents from already read items' do
    Wanko::Fetcher.new(@config_dir, @config).fetch
    File.delete 'output.json'
    Wanko::Fetcher.new(@config_dir, @config).fetch

    output = JSON.parse File.read('output.json'), symbolize_names: true

    output.must_equal []
  end
end

