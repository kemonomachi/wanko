module Wanko
  module Parsing
    def self.parse_index_list(index_list)
      index_list.map { |index|
        if index.include? '-'
          Range.new(*index.split('-', 2).map {|n| Integer n}).to_a
        else
          Integer index
        end
      }.flatten
    end
  end
end

