require 'minitest/autorun'
require 'minitest/pride'

$LOAD_PATH.unshift File.expand_path('../lib')

require 'wanko/parser'

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
    
    ['-a', '--add'].each do |action|
      describe "when called with action #{action} and option -d DIR" do
        it 'signals adding of a rule with DIR as download directory' do
          result = @parser.parse! [action, 'test', '-d', '/specified/directory']
          
          expected = {
            action: :add,
            pattern: 'test',
            directory: '/specified/directory'
          }

          result.must_equal expected
        end
      end

      describe "when called with action #{action} without -d" do
        it 'signals adding of a rule using the default directory' do
          result = @parser.parse!([action, 'test'])
          
          result.must_equal({action: :add, pattern: 'test'})
        end
      end
    end

    ['-D', '--default-dir'].each do |action|
      describe "when called with action #{action} without a directory" do
        it 'signals printing of the default directory' do
          @parser.parse!([action]).must_equal({action: :show_default_dir})
        end
      end

      describe "when called with action #{action} with a directory" do
        it 'signals setting of the default directory' do
          result = @parser.parse! [action, '/test/directory']

          expected = {action: :set_default_dir, directory: '/test/directory'}

          result.must_equal expected
        end
      end
    end

    ['-f', '--feed', '--feeds'].each do |action|
      describe "when called with action #{action} without a URL" do
        it 'signals printing of the feeds' do
          @parser.parse!([action]).must_equal({action: :show_feeds})
        end
      end

      describe "when called with action #{action} with a URL" do
        it 'signals adding of the URL to the feed list' do
          result = @parser.parse!([action, 'testfeed.rss'])

          result.must_equal({action: :add_feed, url: 'testfeed.rss'})
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

    ['-r', '--remove'].each do |action|
      describe "when called with action #{action} INDEXES" do
        it 'signals removal of the rules specified by INDEXES' do
          result = @parser.parse! [action, '0,2-4,6']

          result.must_equal({action: :remove, indexes: [0,2,3,4,6]})
        end
      end
    end

    ['-R', '--remove-feed', '--remove-feeds'].each do |action|
      describe "when called with action #{action} INDEXES" do
        it "signals removal of the feeds specified by INDEXES" do
          result = @parser.parse! [action, '1-3,6']

          result.must_equal({action: :remove_feed, indexes: [1,2,3,6]})
        end
      end
    end

    ['-T', '--torrent-client'].each do |action|
      describe "when called with action #{action} without a client" do
        it 'signals printing of the client used for downloading torrents' do
          @parser.parse!([action]).must_equal({action: :show_client})
        end
      end

      describe "when called with action #{action} with a client" do
        it "signals setting of the torrent client" do
          result = @parser.parse! [action, 'test_client']

          result.must_equal({action: :set_client, client: 'test_client'})
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

    describe 'when called with incomplete switches' do
      it 'signals printing of the help message' do
        ['-a', '--add', '-r', '--remove', '-R', '--remove-feed', '--remove-feeds', '-d', '--directory'].each do |switch|
          result = @parser.parse! [switch]

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

  describe 'method parse_index_list' do
    index_tests = {
      ['2'] => [2],
      ['1','4','5'] =>  [1,4,5],
      ['2-5'] => [2,3,4,5],
      ['0-2','5-6'] => [0,1,2,5,6],
      ['0','2-4','6'] => [0,2,3,4,6]
    }

    it 'parses index lists correctly' do
      index_tests.each do |indexes,expected|
        @parser.parse_index_list(indexes).must_equal expected
      end
    end
  end
end

