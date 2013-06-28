require 'json'
require 'open-uri'
require 'time'

require 'nokogiri'

module Wanko
  class Fetcher
    def initialize(config_dir, config)
      @item_log = File.join config_dir, 'read_items'
      @config = config
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
            Nokogiri::XML(feed_xml).xpath('rss/channel/item').each do |item|
              item_id = item.at_xpath('guid').content

              unless read_items[url].include? item_id
                rules.each do |rule, dir|
                  if rule =~ item.at_xpath('title').content
                    %x(transmission-remote -a "#{item.at_xpath('link').content}" -w #{dir})
                  end
                end
                new_read_items << item_id
              end
            end

            read_items[url] = (new_read_items + read_items[url]).first 50
          end

        rescue OpenURI::HTTPError, Net::ReadTimeout, Errno::ECONNREFUSED
          next
        end
      end

      File.write @item_log, JSON.pretty_generate(read_items)
    end
  end
end

