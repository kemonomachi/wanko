require 'optparse'

module Wanko
  class Parser
    def initialize()
      @options = {}

      @opt_parser = OptionParser.new do |parser|
        parser.banner = 'Usage: wanko [action]' 

        parser.separator ''
        parser.separator 'Actions:' 

        parser.on '-D', '--default-dir', 'Show default directory.' do
          self.set_action @options, :show_default_dir
        end

        parser.on '-f', '--feed', '--feeds', 'Show registered feeds.' do
          self.set_action @options, :show_feeds
        end

        parser.on '-l', '--list', 'Show current rules.' do
          self.set_action @options, :list
        end

        parser.on '-T', '--torrent-client', 'Show torrent client info.' do
          self.set_action @options, :show_client
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
        {action: :fetch}
      else
        begin
          @opt_parser.parse! args
        rescue OptionParser::InvalidOption
          puts @opt_parser
          @options[:help] = true
        end
        @options
      end
    end

    def set_action(options, action)
      raise OptionParser::InvalidOption if options.has_key? :action
      options[:action] = action
    end
  end
end

