#!/usr/bin/ruby

require 'json'
require 'open-uri'
require 'time'

require 'formatador'
require 'nokogiri'

module Wanko
  @config_dir = File.join Dir.home, '.wanko'

  @config = begin
    JSON.parse File.read(File.join @config_dir, 'config'), symbolize_names: true
  rescue Errno::ENOENT
    {
     default_dir: File.join(Dir.home, 'downloads'),
     feeds: [],
     rules: {}
    }
  end

  def self.save(info, filename)
    File.write File.join(@config_dir, filename), JSON.pretty_generate(info)
  end

  def self.add(rule, dir=@config[:default_dir])
    @config[:rules][rule.to_sym] = File.absolute_path dir
    @config[:rules] = Hash[@config[:rules].sort]
    save @config, 'config'
  end

  def self.add_feed(feed)
    @config[:feeds] << feed
    @config[:feeds] = @config[:feeds].sort
    save @config, 'config'
  end

  def self.default_dir()
    @config[:default_dir]
  end

  def self.default_dir=(dir)
    @config[:default_dir] = File.absolute_path dir
    save @config, 'config'
  end

  def self.fetch()
    read_items = begin
      JSON.parse File.read(File.join @config_dir, 'read_items')
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

    save read_items, 'read_items'
  end

  def self.list(type)
    if type == :rules
      headings = [:Pattern, :Directory, :Rule]
      order = [:Rule, :Pattern, :Directory]
    elsif type == :feeds
      headings = [:URL, :Feed]
      order = [:Feed, :URL]
    end

    rows = @config[type].map.with_index { |*data|
      Hash[headings.zip(data.flatten)]
    }

    Formatador.display_table rows, order
  end

  def self.remove(type, indexes)
    @config[type] = @config[type].reject.with_index {|_,i| indexes.include? i}
    save @config, 'config'
  end
end

