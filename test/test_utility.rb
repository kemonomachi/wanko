require 'minitest/autorun'
require 'minitest/pride'

require'wanko/utility'

class TestUtility < MiniTest::Unit::TestCase
  def setup()
    @hash_with_symbol_keys = {cat: 'Hanekawa', dog: 'Eclaire', fox: 'Kuugen', wolf: 'Horo'}
    @hash_with_string_keys = {'cat' => 'Hanekawa', 'dog' => 'Eclaire', 'fox' => 'Kuugen', 'wolf' => 'Horo'}

  end

  def test_convert_keys()
    nested_hash = {
      cat: 'noir',
      'dog' => {
        princess: 'Millhi',
        'worker' => 'Kota'
      },
      %w{w o l f} => 'Liru',
      puppy: [
        {dog: 'Ricotta'},
        {'dog' => 'Silvie'},
        {dog: 'Mikan'}
      ]
    }

    expected = {
      CAT: 'noir',
      DOG: {
        PRINCESS: 'Millhi',
        WORKER: 'Kota'
      },
      WOLF: 'Liru',
      PUPPY: [
        {DOG: 'Ricotta'},
        {DOG: 'Silvie'},
        {DOG: 'Mikan'}
      ]
    }

    result = Wanko::Utility.convert_keys(nested_hash) { |key|
      Array(key).join.upcase.to_sym
    }

    assert_equal expected, result
  end

  def test_symbolize_keys()
    result = Wanko::Utility.symbolize_keys @hash_with_string_keys

    assert_equal @hash_with_symbol_keys, result
  end

  def test_stringify_keys()
    result = Wanko::Utility.stringify_keys @hash_with_symbol_keys

    assert_equal @hash_with_string_keys, result
  end
end

