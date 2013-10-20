require 'minitest/autorun'
require 'minitest/pride'

require 'fileutils'
require 'json'

require_relative '../lib/wanko/client'
require_relative '../lib/wanko/parser'

require_relative 'expected_data'

CONFIG_DIR = File.expand_path 'config', File.dirname(__FILE__)
CONFIG_FILE = File.join CONFIG_DIR, 'config'
CONFIG_BACKUP = File.join CONFIG_DIR, 'config.bak'

def get_config()
  JSON.parse File.read(CONFIG_FILE), symbolize_names: true
end

describe Wanko::Client do
  before do
    FileUtils.cp CONFIG_FILE, CONFIG_BACKUP
    @client = Wanko::Client.new config_dir: CONFIG_DIR
  end

  after do
    FileUtils.mv CONFIG_BACKUP, CONFIG_FILE
  end

  describe 'method run' do
    describe 'when called with action :add' do
      describe 'with a directory' do
        it 'adds a rule' do
          @client.run({action: :add, pattern: 'test', directory: '/specified/directory'})

          config = get_config
          config[:rules].must_include :test
          config[:rules][:test].must_equal '/specified/directory'
        end
      end

      describe 'without a directory' do
        it 'adds a rule using the default directory' do
          @client.run({action: :add, pattern: 'test'})

          config = get_config
          config[:rules].must_include :test
          config[:rules][:test].must_equal '/default/directory'
        end
      end
    end

    describe 'when called with action :add_feed' do
      it 'adds a feed to the feed list' do
        @client.run({action: :add_feed, url: 'testfeed'})

        get_config[:feeds].must_include 'testfeed'
      end
    end

    describe 'when called with action :fetch' do
      it 'fetches torrents' do
        @client.instance_variable_get(:@config)[:feeds].map! do |feed|
          File.join File.dirname(__FILE__), 'feed_data', feed
        end

        out, _ = capture_io {@client.run({action: :fetch})}
        output = JSON.parse out, symbolize_names: true

        output.must_equal ExpectedData::FETCH

        File.delete File.join(CONFIG_DIR, 'read_items') rescue nil
      end
    end

    describe 'when called with action :help' do
      it 'prints the usage message' do
        out, _ = capture_io {
          @client.run({action: :help, message: Wanko::Parser.new.help})
        }

        out.must_equal Wanko::Parser.new.help
      end
    end

    describe 'when called with action :list' do
      it 'prints the rules' do
        out, _ = capture_io {@client.run({action: :list})}

        out.must_match /Toaru Kagaku no Railgun S/
        out.must_match /Hentai Ouji to Warawanai Neko/
      end
    end

    index_tests = [[2], [1,5], [2,4,5], [1,2,5,6], [0,2,3,4,6]]

    index_tests.each do |indexes|
      describe "when called with action :remove and indexes is #{indexes}" do
        it "removes the specified rule#{'s' if indexes.length > 1}" do
          expected = Hash[get_config[:rules].to_a.reject.with_index {|_,i| indexes.include? i}]

          @client.run({action: :remove, indexes: indexes})

          get_config[:rules].must_equal expected
        end
      end
    end

    index_tests.each do |indexes|
      describe "when called with action :remove_feed and indexes is #{indexes}" do
        it "removes the specified feed#{'s' if indexes.length > 1}" do
          expected = get_config[:feeds].reject.with_index {|_,i| indexes.include? i}

          @client.run({action: :remove_feed, indexes: indexes})

          get_config[:feeds].must_equal expected
        end
      end
    end

    describe 'when called with action :set_client' do
      it "sets the torrent client" do
        @client.run({action: :set_client, client: 'test_client'})

        get_config[:torrent_client].must_equal 'test_client'
      end
    end

    describe 'when called with action :set_default_dir' do
      it 'sets the default directory' do
        @client.run({action: :set_default_dir, directory: '/test/directory'})

        get_config[:default_dir].must_equal '/test/directory'
      end
    end

    describe 'when called with action :show_client' do
      it 'prints the client used for downloading torrents' do
        out, _ = capture_io {@client.run({action: :show_client})}

        out.rstrip.must_equal 'stdout'
      end
    end

    describe 'when called with action :show_default_dir' do
      it 'prints the default directory' do
        out, _ = capture_io {@client.run({action: :show_default_dir})}

        out.rstrip.must_equal '/default/directory'
      end
    end

    describe 'when called wiht action :show_feeds' do
      it 'prints the feeds' do
        out, _ = capture_io {@client.run({action: :show_feeds})}

        out.must_match /tokyo_toshokan\.rss/
        out.must_match /nyaa_torrents\.rss/
      end
    end

    [:bad, 'list', [:list, :fetch], 42].each do |action|
      describe "when called with unsupported action <#{action.inspect}>" do
        it 'raises an ArgumentError' do
          bad_action = proc {@client.run({action: action})}

          bad_action.must_raise ArgumentError
        end
      end
    end
  end
end

