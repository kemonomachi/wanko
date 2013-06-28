require 'json'

require 'formatador'

require 'wanko/fetcher'

module Wanko
  class Client
    def initialize()
      @config_dir = File.join Dir.home, '.wanko'
      @config_file = File.join @config_dir, 'config'

      @config = begin
        JSON.parse File.read(@config_file), symbolize_names: true
      rescue Errno::ENOENT
        {
          default_dir: File.join(Dir.home, 'downloads'),
          feeds: [],
          rules: {}
        }
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

    def default_dir()
      @config[:default_dir]
    end

    def default_dir=(dir)
      @config[:default_dir] = File.absolute_path dir
      save_config
    end

    def fetch()
      Fetcher.new(@config_dir, @config).fetch
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
  end
end

