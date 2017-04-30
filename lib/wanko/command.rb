require 'terminal-table'

require 'wanko/read'
require 'wanko/wanko'
require 'wanko/write'

module Wanko
  module Command
    def self.fetch(options)
      config = begin
        Wanko::Read.config options[:config_dir]
      rescue Errno::ENOENT
        abort 'Config file not found, aborting...'
      end

      [:feeds, :rules].each do |key|
        warn 'WARN: No #{key} specified.' if config[key].empty?
      end

      history = Wanko::Read.history options[:config_dir]

      torrents, new_history = Wanko::check_feeds config[:feeds], config[:rules], history

      config[:fetcher].call torrents

      Wanko::Write.history options[:config_dir], new_history
    end

    def self.add(options)
      config = begin
        Wanko::Read.raw_config options[:config_dir]
      rescue Errno::ENOENT
        abort 'Config file not found, aborting...'
      end

      id = if config[:rules].empty?
             0
           else
             config[:rules].map {|x| x[:id]}.max + 1
           end

      rule = [id: id, regex: options[:regex], dir: options[:dir] || config[:base_dir]]

      new_config = config.merge rules: config[:rules] + rule

      Wanko::Write.config options[:config_dir], Wanko::Utility.stringify_keys(new_config)
    end

    def self.list(options)
      config = begin
        Wanko::Read.raw_config options[:config_dir]
      rescue Errno::ENOENT
        abort 'Config file not found, aborting...'
      end

      puts Terminal::Table.new(rows: config[:rules].map {|r| [r[:id], r[:regex], r[:dir]]},
                               headings: ['ID', 'Regex', 'Directory']) {align_column 0, :right}
    end

    def self.remove(options)
      config = begin
        Wanko::Read.raw_config options[:config_dir]
      rescue Errno::ENOENT
        abort 'Config file not found, aborting...'
      end

      new_rules = config[:rules].reject {|rule| options[:ids].include? rule[:id]}

      Wanko::Write.config options[:config_dir], Wanko::Utility.stringify_keys(config.merge rules: new_rules)
    end
  end
end

