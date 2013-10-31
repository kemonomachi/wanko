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

describe Wanko::Client do
  before do
    FileUtils.cp CONFIG_FILE, CONFIG_BACKUP
    @client = Wanko::Client.new config_dir: CONFIG_DIR
  end

  after do
    FileUtils.mv CONFIG_BACKUP, CONFIG_FILE
  end

  describe 'method run' do
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

