require 'json'
require 'open-uri'
require 'time'

require 'nokogiri'

module Wanko
  class Fetcher
    def initialize(config_dir, config)
      @item_log = File.join config_dir, 'read_items'
      @config = config

      @download_method = case @config[:torrent_client]
      when 'transmission'
        method :transmission
      else
        raise ArgumentError, "Unknown torrent client: '#{@config['torrent_client']}'"
      end
    end

    def fetch()
      read_items = begin
        JSON.parse File.read @item_log
      rescue Errno::ENOENT
        {}
      end

      read_items.default_proc = proc {|read_items,key| read_items[key] = []}

      rules = @config[:rules].each_with_object({}) { |(rule, dir), rules|
        rules[/#{rule}/i] = dir
      }

      @config[:feeds].each do |url|
        begin
          open url, read_timeout: 10 do |feed_xml|
            new_read_items = []
            matches = []

            Nokogiri::XML(feed_xml).xpath('rss/channel/item').each do |item|
              item_id = item.at_xpath('guid').content

              unless read_items[url].include? item_id
                rules.each do |rule, dir|
                  if rule =~ item.at_xpath('title').content
                    matches << {link: item.at_xpath('link').content, dir: dir}
                  end
                end
                new_read_items << item_id
              end
            end

            @download_method.call matches
            read_items[url] = (new_read_items + read_items[url]).first 50
          end

        rescue OpenURI::HTTPError, Timeout::Error, Errno::ECONNREFUSED
          next
        end
      end

      File.write @item_log, JSON.pretty_generate(read_items)
    end

    def transmission(torrents)
      torrents.each do |torrent|
        %x(transmission-remote -a "#{torrent[:link]}" -w "#{torrent[:dir]}")
      end
    end
  end
end

