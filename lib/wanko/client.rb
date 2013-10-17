require 'json'

require 'formatador'

require 'wanko'
require 'wanko/parser'

module Wanko
  class Client
    def initialize(config_dir: File.join(Dir.home, '.wanko'))
      @parser = Parser.new

      @config_dir = config_dir
      @config_file = File.join @config_dir, 'config'

      @config = begin
        JSON.parse File.read(@config_file), symbolize_names: true
      rescue Errno::ENOENT
        {
          default_dir: File.join(Dir.home, 'downloads'),
          feeds: [],
          rules: {},
          torrent_client: 'transmission'
        }
      end
    end

    def run!(args)
      options = @parser.parse! args

      case options[:action]
      when :add
        if options[:directory]
          add options[:pattern], options[:directory]
        else
          add options[:pattern]
        end
      when :add_feed
        add_feed options[:url]
      when :fetch
        fetch
      when :help
        puts help
      when :list
        list :rules
      when :remove
        remove :rules, options[:indexes]
      when :remove_feed
        remove :feeds, options[:indexes]
      when :set_default_dir
        set_default_dir options[:directory]
      when :set_client
        set_torrent_client options[:client]
      when :show_default_dir
        puts @config[:default_dir]
      when :show_client
        puts @config[:torrent_client]
      when :show_feeds
        list :feeds
      end
    end

    def save_config()
      File.write @config_file, JSON.pretty_generate(@config)
    end

    def add(rule, dir=@config[:default_dir])
      @config[:rules][rule.to_sym] = File.absolute_path dir
      @config[:rules] = Hash[@config[:rules].sort]
      save_config
    end

    def add_feed(feed)
      @config[:feeds] << feed
      @config[:feeds] = @config[:feeds].sort
      save_config
    end

    def set_default_dir(dir)
      @config[:default_dir] = File.absolute_path dir
      save_config
    end

    def fetch()
      Fetcher.new(@config_dir, @config).fetch
    end

    def help()
      @parser.help
    end
    
    def list(type)
      if type == :rules
        headings = [:Pattern, :Directory, :Rule]
        order = [:Rule, :Pattern, :Directory]
      elsif type == :feeds
        headings = [:URL, :Feed]
        order = [:Feed, :URL]
      end

      rows = @config[type].map.with_index { |*data|
        Hash[headings.zip(data.flatten)]
      }

      Formatador.display_table rows, order
    end

    def remove(type, indexes)
      @config[type] = @config[type].reject.with_index {|_,i| indexes.include? i}
      save_config
    end

    def set_torrent_client(client)
      @config[:torrent_client] = client
      save_config
    end
  end
end

