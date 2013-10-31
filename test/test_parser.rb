require 'minitest/autorun'
require 'minitest/pride'

require_relative '../lib/wanko/parser'

require_relative 'expected_data'

describe Wanko::Parser do
  before do
    @parser = Wanko::Parser.new
  end

  describe 'method parse!' do
    describe 'when called without action' do
      it 'signals fetching' do
        @parser.parse!([]).must_equal({actions: [:fetch]})
      end
    end
    
    ['-D', '--default-dir'].each do |action|
      describe "when called with action #{action}" do
        it 'signals printing of the default directory' do
          @parser.parse!([action]).must_equal({actions: [:show_default_dir]})
        end
      end
    end

    ['-f', '--feed', '--feeds'].each do |action|
      describe "when called with action #{action}" do
        it 'signals printing of the feeds' do
          @parser.parse!([action]).must_equal({actions: [:show_feeds]})
        end
      end
    end

    ['-l', '--list'].each do |action|
      describe "when called with action #{action}" do
        it 'signals printing of the rules' do
          @parser.parse!([action]).must_equal({actions: [:list]})
        end
      end
    end

    ['-T', '--torrent-client'].each do |action|
      describe "when called with action #{action}" do
        it 'signals printing of the client used for downloading torrents' do
          @parser.parse!([action]).must_equal({actions: [:show_client]})
        end
      end
    end

    ['-h', '--help'].each do |action|
      describe "when called with action #{action}" do
        it 'prints the help message' do
          out, _ = capture_io {@parser.parse! [action]}

          out.must_equal @parser.instance_variable_get(:@opt_parser).to_s
        end
      end
    end

    describe 'when called with invalid switches' do
      it 'prints the help message' do
        ['-B', '--bad-switch'].each do |switch|
          out, _ = capture_io {@parser.parse! [switch]}

          out.must_equal @parser.instance_variable_get(:@opt_parser).to_s
        end
      end
    end
  end
end

