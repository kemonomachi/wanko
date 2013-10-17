require 'minitest/autorun'
require 'minitest/pride'

require 'fileutils'
require 'json'

$LOAD_PATH.unshift File.expand_path('../lib')

require 'wanko/client'

require_relative 'expected_data'

def get_config()
  JSON.parse File.read(File.join 'config', 'config'), symbolize_names: true
end

describe Wanko::Client do
  before do
    @client = Wanko::Client.new config_dir: 'config'
  end

  after do
    FileUtils.cp 'config/standard_config', 'config/config'
  end

  describe 'when called without action' do
    it 'fetches torrents' do
      @client.run! []

      output = JSON.parse File.read('output.json'), symbolize_names: true

      output.must_equal ExpectedData::FETCH

      ['output.json', File.join('config', 'read_items')].each do |f|
        File.delete f if File.exist? f
      end
    end
  end
  
  describe 'when called with action' do
    ['-a', '--add'].each do |action|
      describe "#{action} PATTERN" do
        describe 'with a directory' do
          it 'adds a rule' do
            @client.run! [action, 'test', '-d', '/specified/directory']
            config = get_config
            config[:rules].must_include :test
            config[:rules][:test].must_equal '/specified/directory'
          end
        end

        describe 'without a directory' do
          it 'adds a rule using the default directory' do
            @client.run! [action, 'test']
            config = get_config
            config[:rules].must_include :test
            config[:rules][:test].must_equal '/default/directory'
          end
        end
      end
    end

    ['-D', '--default-dir'].each do |action|
      describe action do
        it 'prints the default directory' do
          out, _ = capture_io {@client.run! [action]}
          out.rstrip.must_equal '/default/directory'
        end
      end

      describe "#{action} DIRECTORY" do
        it 'sets the default directory' do
          @client.run! [action, '/test/directory']
          get_config[:default_dir].must_equal '/test/directory'
        end
      end
    end

    ['-f', '--feed', '--feeds'].each do |action|
      describe action do
        it 'prints the feeds' do
          out, _ = capture_io {@client.run! [action]}
          out.must_match /tokyo_toshokan\.rss/
          out.must_match /nyaa_torrents\.rss/
        end
      end

      describe "#{action} URL" do
        it 'adds URL to the feed list' do
          @client.run! [action, 'testfeed']
          get_config[:feeds].must_include 'testfeed'
        end
      end
    end

    ['-l', '--list'].each do |action|
      describe action do
        it 'prints the rules' do
          out, _ = capture_io {@client.run! [action]}
          out.must_match /Toaru Kagaku no Railgun S/
          out.must_match /Hentai Ouji to Warawanai Neko/
        end
      end
    end

    index_tests = {
      '2' => ['a single number', [2]],
      '1,4,5' => ['a comma-separated list of numbers', [1,4,5]],
      '2-5' => ['a range of numbers', [2,3,4,5]],
      '0-2,5-6' => ['list of ranges', [0,1,2,5,6]],
      '0,2-4,6' => ['a mix of single numbers and ranges', [0,2,3,4,6]]
    }

    ['-r', '--remove'].each do |action|
      describe "#{action} INDEXES" do
        index_tests.each do |indexes,(desc,del_indexes)|
          describe "and INDEXES is #{desc}" do
            it "removes the specified rule#{'s' if del_indexes.length > 1}" do
              expected = Hash[get_config[:rules].to_a.reject.with_index {|_,i| del_indexes.include? i}]

              @client.run! [action, indexes]
              get_config[:rules].must_equal expected
            end
          end
        end
      end
    end

    ['-R', '--remove-feed', '--remove-feeds'].each do |action|
      describe "#{action} INDEXES" do
        index_tests.each do |indexes,(desc,del_indexes)|
          describe "and INDEXES is #{desc}" do
            it "removes the specified feed#{'s' if del_indexes.length > 1}" do
              5.times do |i|
                @client.run! ['--feed', "dummy#{i}"]
              end

              expected = get_config[:feeds].reject.with_index {|_,i| del_indexes.include? i}

              @client.run! [action, indexes]
              get_config[:feeds].must_equal expected
            end
          end
        end
      end
    end

    ['-T', '--torrent-client'].each do |action|
      describe action do
        it 'prints the client used for downloading torrents' do
          out, _ = capture_io {@client.run! [action]}
          out.rstrip.must_equal 'dummy_downloader'
        end
      end

      describe "#{action} CLIENT" do
        it "sets the torrent client" do
          @client.run! [action, 'test_client']
          get_config[:torrent_client].must_equal 'test_client'
        end
      end
    end

    ['-h', '--help'].each do |action|
      describe action do
        it 'prints the usage message' do
          out, _ = capture_io {@client.run! [action]}
          out.must_equal @client.help
        end
      end
    end
  end

  describe 'when called with incomplete switches' do
    it 'prints the usage message' do
      ['-a', '--add', '-r', '--remove', '-R', '--remove-feed', '--remove-feeds', '-d', '--directory'].each do |switch|
        out, _ = capture_io {@client.run! [switch]}
        out.must_equal @client.help
      end
    end
  end

  describe 'when called with invalid switches' do
    it 'prints the usage message' do
      ['-B', '--bad-switch'].each do |switch|
        out, _ = capture_io {@client.run! [switch]}
        out.must_equal @client.help
      end
    end
  end

  describe 'when called with multiple actions' do
    it 'prints the usage message' do
      [['-flT'], ['-f', '-l'], ['--list', '--feeds'], ['-T', '--list-']].each do |switches|
        out, _ = capture_io {@client.run! switches}
        out.must_equal @client.help
      end
    end
  end

end

