require 'optparse'

module Wanko
  class Parser
    def initialize()
      @options = {actions: []}

      @opt_parser = OptionParser.new do |parser|
        parser.banner = 'Usage: wanko [action] ...' 

        parser.separator ''
        parser.separator 'Actions:' 

        parser.on '-D', '--default-dir', 'Show default directory.' do
          @options[:actions] << :show_default_dir
        end

        parser.on '-f', '--feed', '--feeds', 'Show registered feeds.' do
          @options[:actions] << :show_feeds
        end

        parser.on '-l', '--list', 'Show current rules.' do
          @options[:actions] << :list
        end

        parser.on '-T', '--torrent-client', 'Show torrent client info.' do
          @options[:actions] << :show_client
        end

        parser.separator ''
        parser.separator 'Other:'

        parser.on '-h', '--help',
                'Show this message' do
          puts parser
          @options[:help] = true
        end
      end
    end
    
    def parse!(args)
      if args.empty?
        @options[:actions] << :fetch
      else
        begin
          @opt_parser.parse! args
        rescue OptionParser::InvalidOption
          puts @opt_parser
          @options[:help] = true
        end
      end

      @options
    end

  end
end

