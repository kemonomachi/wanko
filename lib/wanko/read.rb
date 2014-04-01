require 'yaml'

require 'wanko/data'
require 'wanko/fetch'
require 'wanko/utility'

module Wanko

  # Functions to read in data from files, urls and similar.
  # All functions can be considered to rely on external state.
  module Read

    # Public: Read a config file, convert values and supply some sensible
    # defaults.
    #
    # dir - Path to the directory containing the config file.
    #
    # Returns a Hash containing the configuration.
    def self.config(dir)
      config = Utility.symbolize_keys(YAML.load_file File.join(dir, 'config.yaml')) || {}

      base_dir = config[:base_dir] || File.join(Dir.home, 'downloads')

      {
        feeds: Array(config[:feeds]),
        base_dir: base_dir,
        fetcher: Fetch.fetcher_for({name: 'stdout'}.merge Hash config[:fetcher]),
        rules: Array(config[:rules]).map {|rule| convert_rule rule, base_dir}
      }
    end

    # Internal: Convert a rule Hash into a Rule object, making the path
    # absolute.
    #
    # rule     - Rule to convert. Has a required :regex entry and an optional
    #            :dir entry.
    # base_dir - Directory to use as base for relative paths, or as download
    #            dir if the rule has no :dir entry.
    #
    # Returns an Array of converted Rules.
    def self.convert_rule(rule, base_dir)
      Data::Rule.new rule[:regex], File.absolute_path(rule[:dir] ||'', base_dir)
    end

    # Public: Read an RSS feed history file.
    #
    # dir - Path to the directory containing the history file.
    #
    # Returns a Hash containing the history, or an empty Hash if the file does
    #   not exist.
    def self.history(dir)
      history = begin
        YAML.load_file File.join(dir, 'history.yaml')
      rescue Errno::ENOENT
        {}
      end

      # This is OK, since history is treated as read-only.
      history.default = []

      history
    end

    # Public: Read an RSS feed.
    #
    # url - Location of the feed. Must be openable by OpenURI.
    #
    # Returns an RSS::Rss object, or nil if the feed couldn't be read.
    def self.feed(url)
      begin
        open(url, read_timeout: 10) {|rss| RSS::Parser.parse rss}
      rescue OpenURI::HTTPError, Timeout::Error, Errno::ECONNREFUSED, SocketError => ex
        warn "WARN: #{url} --> #{ex}"
      end
    end
  end
end
