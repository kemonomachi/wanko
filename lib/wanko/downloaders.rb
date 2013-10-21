require 'json'

module Wanko
  module Downloaders
    module Stdout
      def download(torrents)
        $stdout.write JSON.pretty_generate(torrents)
      end
    end

    module Transmission
      def download(torrents)
        torrents.each do |torrent|
          %x(transmission-remote -a "#{torrent[:link]}" -w "#{torrent[:dir]}")
        end
      end
    end
  end
end

