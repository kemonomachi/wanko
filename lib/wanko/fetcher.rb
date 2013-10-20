require 'json'
require 'open-uri'
require 'rss'
require 'timeout'

module Wanko
  class Fetcher
    def initialize(config_dir, config)
      @config_dir = config_dir
      @config = config
      @item_log_file = File.join @config_dir, 'read_items'

      @item_log = begin
        JSON.parse File.read @item_log_file
      rescue Errno::ENOENT
        {}
      end
      @item_log.default_proc = proc {|item_log,url| item_log[url] = []}

      @rules = Hash[@config[:rules].map {|rule, dir| [/#{rule}/i, dir]}]

      case @config[:torrent_client]
      when 'transmission'
        alias :download :transmission
      when 'dummy_downloader'
        alias :download :dummy_downloader
      else
        raise ArgumentError, "Unknown torrent client: '#{@config[:torrent_client]}'"
      end
    end

    def fetch()
      @config[:feeds].each do |url|
        begin
          feed = open(url, read_timeout: 10) { |rss|
            RSS::Parser.parse rss
          }
        rescue OpenURI::HTTPError, Timeout::Error, Errno::ECONNREFUSED
          next
        end

        download feed.items.reject { |item|
          @item_log[url].include? item.guid.content
        }.each_with_object([]) { |item,matches|
          @rules.each do |rule,dir|
            matches << {link: item.link, dir: dir} if rule =~ item.title
          end
        }

        @item_log[url] = feed.items.map {|item| item.guid.content}
      end

    ensure
      File.write @item_log_file, JSON.pretty_generate(@item_log)
    end

    def dummy_downloader(torrents)
      output_file = File.join @config_dir, 'output.json'

      output = begin
        JSON.parse File.read(output_file), symbolize_names: true
      rescue Errno::ENOENT
        []
      end

      output += torrents

      File.write output_file, JSON.pretty_generate(output)
    end

    def transmission(torrents)
      torrents.each do |torrent|
        %x(transmission-remote -a "#{torrent[:link]}" -w "#{torrent[:dir]}")
      end
    end
  end
end

