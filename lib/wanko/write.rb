require 'yaml'

module Wanko

  # Functions for writing data out to files or similar. All functions can be
  # considered to have destructive side-effects.
  module Write

    # Public: Write a YAML representation of an object to a file named
    # 'history.yaml'.
    #
    # This function _will_ clobber an existing file.
    #
    # dir     - Path of the directory to write the file in.
    # history - Object to write out. Responds to #to_yaml.
    #
    # Returns nothing
    def self.history(dir, history)
      File.write File.join(dir, 'history.yaml'), history.to_yaml
    end
  end
end

