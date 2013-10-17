require 'optparse'

module Wanko
  class Parser
    def initialize()
      @options = {}
      @opt_parser = self.build_option_parser @options
    end

    def parse_index_list(index_list)
      index_list.map { |index|
        if index.include? '-'
          Range.new(*index.split('-', 2).map {|n| Integer n}).to_a
        else
          Integer index
        end
      }.flatten
    end

    def build_option_parser(options)
      OptionParser.new do |parser|
        parser.banner = 'Usage: wanko [action] [options]'

        parser.separator ''
        parser.separator 'Actions:' 

        parser.on '-a', '--add PATTERN',
                'Add a new pattern to look for when fetching.',
                'PATTERN is a case-insensitve regexp.' do |pattern|
          self.set_action options, :add
          options[:pattern] = pattern
        end

        parser.on '-D', '--default-dir [DIR]',
                'Set the default directory for fetch rules.',
                'Show the current default if DIR not specified.' do |directory|
          if directory
            self.set_action options, :set_default_dir
            options[:directory] = directory
          else
            self.set_action options, :show_default_dir
          end
        end

        parser.on '-f', '--feed [URL]', '--feeds [URL]',
                'Add a new feed to watch for updates.',
                'Show current feeds if URL not specified.' do |url|
          if url
            self.set_action options, :add_feed
            options[:url] = url
          else
            self.set_action options, :show_feeds
          end
        end

        parser.on '-l', '--list',
                'Show current rules.' do
          self.set_action options, :list
        end

        parser.on '-r', '--remove INDEXES', Array,
                'Remove rules. INDEXES is a comma separated list',
                'of indexes or ranges of indexes to remove.',
                'Use -l to show rule indexes.' do |indexes|
          self.set_action options, :remove
          options[:indexes] = parse_index_list indexes
        end

        parser.on '-R', '--remove-feed INDEXES', '--remove-feeds INDEXES',  Array,
                'Remove feeds. INDEXES is a comma separated list',
                'of indexes or ranges of indexes to remove',
                'Use -f to show feed indexes.' do |indexes|
          self.set_action options, :remove_feed
          options[:indexes] = parse_index_list indexes
        end

        parser.on '-T', '--torrent-client [CLIENT]',
                  'Set the torrent client to use for downloading.',
                  'Show current client if CLIENT not specified.' do |client|
          if client
            self.set_action options, :set_client
            options[:client] = client
          else
            self.set_action options, :show_client
          end
        end

        parser.separator ''
        parser.separator 'Options:'

        parser.on '-d', '--directory DIR',
                'Optional target directory for fetch rules.',
                'If not specified, the default directory is used.' do |directory|
          options[:directory] = directory
        end

        parser.separator ''
        parser.separator 'Other:'

        parser.on '-h', '--help',
                'Show this message' do
          self.set_action options, :help
          options[:message] = self.help
        end
      end
    end
    
    def parse!(args)
      if args.empty?
        {action: :fetch}
      else
        begin
          @opt_parser.parse! args
          @options
        rescue OptionParser::InvalidOption, OptionParser::MissingArgument
          {action: :help, message: self.help}
        end
      end
    end

    def help()
      @opt_parser.to_s
    end

    def set_action(options, action)
      raise OptionParser::InvalidOption if options.has_key? :action
      options[:action] = action
    end
  end
end

