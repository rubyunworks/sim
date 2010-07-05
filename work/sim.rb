#module Sim
#  VERSION="1.0.0"
#end

#require 'sim/stub'
#require 'sim/spy'
#require 'sim/mock'

#
class Sim

  # undef or private?
  instance_methods.each{ |m| undef_method(m) unless /^__/ =~ m.to_s }

  def initialize(obj)
    @__obj__ = obj
    @__rec__ = []
    @__ver__ = Verify.new(@__rec__)
  end

  def method_missing(s, *a, &b)
    r = @__obj__.send(s, *a, &b)
    @__rec__ << [s, a, b, r]
    r
  end

  def __ver__(&block)
    if block
      @__ver__.add(&block)
    end
    @__ver__
  end

  #
  class Verify

    #
    def initialize(rec)
      @__rec__ = rec
      @__chk__ = []
    end

    #
    def count(meth, args=nil)
      meth = meth.to_sym
      if args
        c = @__rec__.select{ |s, a, b, r| s == meth && a == args }
      else
        c = @__rec__.select{ |s, a, b, r| s == meth }
      end
      c.size
    end

    #
    def called?(meth, args=nil)
      meth = meth.to_sym
      if args
        @__rec__.find{ |s, a, b, r| s == meth && a == args }
      else
        @__rec__.find{ |s, a, b, r| s == meth }
      end
    end

    #
    def returns?(meth, value)
      @__rec__.all?{ |s, a, b, r| r == value }
    end

    #
    def add(&block)
      @__chk__ << block
    end

    #
    def verify
      @__chk__.each{ |l| instance_eval(&l) }
    end

  end

end


def sim(obj)
  Sim.new(obj)
end

def verify(sim, &block)
  sim.__ver__(&block)
end


if $0 == __FILE__

  require 'ae'

  obj = "test"

  spy = sim(obj)

  spy.to_s

  verify(spy).returned?(:to_s, "test")
  
end

