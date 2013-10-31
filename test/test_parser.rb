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
        @parser.parse!([]).must_equal({action: :fetch})
      end
    end
    
    ['-D', '--default-dir'].each do |action|
      describe "when called with action #{action}" do
        it 'signals printing of the default directory' do
          @parser.parse!([action]).must_equal({action: :show_default_dir})
        end
      end
    end

    ['-f', '--feed', '--feeds'].each do |action|
      describe "when called with action #{action}" do
        it 'signals printing of the feeds' do
          @parser.parse!([action]).must_equal({action: :show_feeds})
        end
      end
    end

    ['-l', '--list'].each do |action|
      describe "when called with action #{action}" do
        it 'signals printing of the rules' do
          @parser.parse!([action]).must_equal({action: :list})
        end
      end
    end

    ['-T', '--torrent-client'].each do |action|
      describe "when called with action #{action}" do
        it 'signals printing of the client used for downloading torrents' do
          @parser.parse!([action]).must_equal({action: :show_client})
        end
      end
    end

    ['-h', '--help'].each do |action|
      describe "when called with action #{action}" do
        it 'signals printing of the help message' do
          result = @parser.parse! [action]

          result.must_equal({action: :help, message: @parser.help})
        end
      end
    end

    describe 'when called with invalid switches' do
      it 'signals printing of the help message' do
        ['-B', '--bad-switch'].each do |switch|
          result = @parser.parse! [switch]

          result.must_equal({action: :help, message: @parser.help})
        end
      end
    end

    describe 'when called with multiple actions' do
      it 'signals printing of the help message' do
        [['-f', '-l'], ['--list', '--feeds'], ['-T', '--list'], ['-D', '-D']].each do |switches|
          result = @parser.parse! switches

          result.must_equal({action: :help, message: @parser.help})
        end
      end
    end
  end
end

