require 'minitest/autorun'
require 'minitest/pride'

require 'fileutils'
require 'yaml'

require 'wanko/write'

class TestWrite < MiniTest::Unit::TestCase
  def test_history()
    FileUtils.mkdir 'temp'

    history = {'feed' => ['guid3', 'guid2', 'guid1', 'guid0']}
    
    Wanko::Write.history 'temp', history

    assert_equal history, YAML.load_file(File.join('temp', 'history.yaml'))

    FileUtils.rm_r 'temp'
  end
end

