require 'json'

module Wanko

  # Data representations.
  module Data

    # Class for torrent data. Contains the name of and the link to a torrent,
    # as well as the directory the torrent will be downloaded to.
    class Torrent
      def initialize(name, link, dir)
        @name = name
        @link = link
        @dir = dir
      end

      attr_reader :name, :link, :dir

      # Returns a Hash representation of this Torrent
      def to_h()
        {
          name: name,
          link: link,
          dir: dir
        }
      end

      # Returns a JSON representation of this Torrent
      def to_json(state = nil)
        to_h.to_json state
      end
    end

    # Rule for matching against RSS items. Contains a regex for matching and a
    # directory to download matched torrents to.
    class Rule

      # Public: Initialize a Rule object.
      #
      #regex - String or Regexp for matching.
      #dir   - Directory to download matched torrents to.
      def initialize(regex, dir)
        @regex = Regexp.new regex, Regexp::IGNORECASE
        @dir = dir
      end

      attr_reader :regex, :dir

      # Public: Match the regex of this Rule against a String
      #
      # str - String to match.
      #
      # Returns true if str matches, false otherwise.
      def =~(str)
        regex =~ str
      end

      # Public: Compare this Rule to another object.
      #
      # other - Object to compare this Rule to.
      #
      # Returns true if the regex and dir fields of this Rule are equal to
      #   the corresponding fields in other, false otherwise.
      def ==(other)
        regex == other.regex && dir == other.dir
      end
    end
  end
end

