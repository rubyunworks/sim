require 'sim/contract'
require 'test/unit'

class TContractDelegation < Test::Unit::TestCase

  def test_should_delegate_to_methods_without_arguments
    dbc = Sim::Contract.new
    dbc.upcase do |x|
      assert_equal(x, "HELLO")
    end
    obj = "hello"
    objc = obj.contract(dbc)
    objc.upcase
  end

  def test_should_delegate_to_methods_with_arguments
    dbc = Sim::Contract.new
    dbc.gsub('l', '') do |x|
      assert_equal(x, "heo")
    end
    dbc.gsub('o', '') do |x|
      assert_equal(x, "hell")
    end
    obj = "hello"
    objc = obj.contract(dbc)
    objc.gsub('l', '')
    objc.gsub('o', '')
  end

  def test_should_raise_an_Assertion_if_contract_fails
    dbc = Sim::Contract.new
    dbc.upcase do |x|
      assert_equal(x, "HELLo")
    end
    obj = "hello"
    objc = obj.contract(dbc)
    assert_raises(Test::Unit::AssertionFailedError){ objc.upcase }
  end

  def test_should_delegate_to_methods_with_arguments
    dbc = Sim::Contract.new
    dbc.gsub('l', '') do |x|
      assert_equal(x, "heo")
    end
    dbc.gsub('o', '') do |x|
      assert_equal(x, "hell")
    end
    obj = "hello"
    objc = obj.contract(dbc)
    objc.gsub('l', '')
    objc.gsub('o', '')
  end

end
