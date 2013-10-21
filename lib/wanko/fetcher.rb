require 'json'
require 'open-uri'
require 'rss'
require 'timeout'

require_relative 'downloaders'

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
        extend Wanko::Downloaders::Transmission
      when 'stdout'
        extend Wanko::Downloaders::Stdout
      else
        raise ArgumentError, "Unknown torrent client: '#{@config[:torrent_client]}'"
      end
    end

    def fetch()
      download @config[:feeds].map { |url|
        begin
          feed = open(url, read_timeout: 10) { |rss|
            RSS::Parser.parse rss
          }
        rescue OpenURI::HTTPError, Timeout::Error, Errno::ECONNREFUSED
          next
        end

        matches = feed.items.reject { |item|
          @item_log[url].include? item.guid.content
        }.product(@rules.to_a).select { |item,(rule,_)|
          rule =~ item.title
        }.map { |item,(_,dir)|
          {link: item.link, dir: dir}
        }

        @item_log[url] = feed.items.map {|item| item.guid.content}

        matches
      }.flatten

      File.write @item_log_file, JSON.pretty_generate(@item_log)
    end
  end
end

