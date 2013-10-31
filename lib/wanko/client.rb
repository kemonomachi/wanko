require 'json'

require 'formatador'

require_relative 'fetcher'

module Wanko
  class Client
    def initialize(config_dir: File.join(Dir.home, '.wanko'), config_file: File.join(config_dir, 'config'))
      @config_dir = config_dir
      @config_file = config_file

      @config = begin
        JSON.parse File.read(@config_file), symbolize_names: true
      rescue Errno::ENOENT
        {
          default_dir: File.join(Dir.home, 'downloads'),
          feeds: [],
          rules: {},
          torrent_client: {name: 'stdout'}
        }
      end
    end

    def run(actions)
      actions.each do |action|
        case action
        when :fetch
          fetch
        when :list
          list :rules
        when :show_default_dir
          puts @config[:default_dir]
        when :show_client
          puts @config[:torrent_client][:name]
        when :show_feeds
          list :feeds
        else
          raise ArgumentError, "Unknown action <#{action}>"
        end
      end
    end

    def save_config()
      File.write @config_file, JSON.pretty_generate(@config)
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
  end
end

