require 'optparse'
require 'rss'

require 'wanko/command'
require 'wanko/data'
require 'wanko/read'

module Wanko

  # Public: Parse cli switches. Exits and prints a usage message when given
  # -h, --help or an invalid switch.
  #
  # args - Array of switches to parse. Will not be altered.
  #
  # Returns a Hash containing the parsed options.
  def self.parse_cli_switches(args)
    options = {
                command: Command.method(:fetch),
                config_dir: File.join(Dir.home, ".wanko")
              }

    parser = OptionParser.new do |parser|
      parser.banner = 'Usage: wanko [options]'

      parser.separator ''
      parser.separator 'Options:' 

      parser.on '-c DIR', '--config_dir', 'Use a different config directory' do |dir|
        options[:config_dir] = File.absolute_path dir
      end

      parser.on '-a REGEX', '--add', 'Add a fetch rule' do |regex|
        options[:command] = Command.method :add
        options[:regex] = regex
      end

      parser.on '-d DIR', '--directory', 'Optional directory for fetch rules added with -a' do |dir|
        options[:dir] = dir
      end

      parser.on '-l', '--list', 'List all rules' do
        options[:command] = Command.method :list
      end

      parser.on '-r ID', '--remove', Integer, 'Remove a fetch rule' do |id|
        options[:command] = Command.method :remove
        options[:ids] = [id]
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

  # Public: Check RSS feeds for new torrents matching a set of rules, excluding
  # already read items.
  #
  # urls    - Array of feed urls to check.
  # rules   - Array of Rules to match against.
  # history - Hash with urls mapped to Arrays of already read items. Will be
  #           accessed using the urls in the urls parameter. If a url is
  #           missing, an empty Array will be substituted.
  #
  # Returns a pair [[Torrent], Hash] of matched items and an updated history
  def self.check_feeds(urls, rules, history)
    matches, new_history = urls.map { |url|
      feed = Read.feed(url) or next [[], {url => history[url]}]

      [
        match(feed, rules, Array(history[url])),
        {url => feed.items.map {|item| item.guid.content}}
      ]
    }.transpose

    [matches.flatten, new_history.reduce(:merge)]
  end

  # Internal: Match a set of rules against the items of an RSS feed, excluding
  # already read items.
  #
  # feed    - RSS object which items to search through.
  # rules   - Array of Rules.
  # history - Array of GUIDs. Items found in this array will be rejected.
  #
  # Returns an Array of Torrents representing the matched items.
  def self.match(feed, rules, history)
    feed.items
    .reject {|item| history.include? item.guid.content}
    .product(rules)
    .select {|item, rule| rule =~ item.title}
    .map { |item, rule|
      Data::Torrent.new item.title, item.link, rule.dir
    }
  end
end

