require 'optparse'
require 'rss'

require 'wanko/read'

module Wanko
  def self.parse_cli_switches(args)
    options = {config_dir: File.join(Dir.home, ".wanko")}

    parser = OptionParser.new do |parser|
      parser.banner = 'Usage: wanko [-c DIR]'

      parser.separator ''
      parser.separator 'Options:' 

      parser.on '-c DIR', '--config_dir', 'Use a different config directory' do |dir|
        options[:config_dir] = File.absolute_path dir
      end

      parser.separator ''
      parser.separator 'Other:'

      parser.on '-h', '--help',
              'Show this message' do
        puts parser
        exit
      end
    end

    begin
      parser.parse args
    rescue OptionParser::InvalidOption
      puts parser
      exit
    end

    options
  end

  def self.check_feeds(urls, rules, history)
    matches, new_history = urls.map { |url|
      feed = Read.feed(url) or next [[], {}]

      [
        match(feed, rules, Hash history[url]),
        {url => feed.items.map {|item| item.guid.content}}
      ]
    }.transpose

    [matches.flatten, new_history.reduce(:merge)]
  end

  def self.match(feed, rules, history)
    feed.items
    .reject {|item| history.include? item.guid.content}
    .product(rules)
    .select {|item, rule| rule[:regex] =~ item.title}
    .map { |item, rule|
      {name: item.title, link: item.link, dir: rule[:dir]}
    }
  end
end

