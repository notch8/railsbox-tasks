require 'test_helper'

class Get::My::DbTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Get::My::Db::VERSION
  end

  def test_it_does_something_useful
    assert false
  end
end
