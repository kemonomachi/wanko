require 'json'
require 'yaml'

require 'wanko/utility'

module Wanko

  # Data representations, with serialization methods.
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
  end
end

