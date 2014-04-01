require 'yaml'

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

    # Internal: Convert a rule Hash by building a Regexp object and making
    # the path absolute.
    #
    # rule     - Rule to convert. Must have a :regex and a :dir entry.
    # base_dir - Directory to use as base for relative paths.
    #
    # Returns an Array of converted rules.
    def self.convert_rule(rule, base_dir)
      {
        regex: /#{rule[:regex]}/i,
        dir: File.absolute_path(rule[:dir] || '', base_dir)
      }
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
