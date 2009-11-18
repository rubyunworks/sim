require 'facets/functor'

warn "sim/mock is still a work in progress"

module Sim

  #
  class Mock #< Module
    public_instance_methods(true).each{ |m| private m unless /^__/ =~ m }

    def initialize(object)
      @__object = object
      @__stats  = Statistics.new
    end

    def __tally(name, *args, &blk)
      ret = @__object.__send__(name, *args, &blk)
      @__stats << [name, args, blk, ret]
      ret
    end

    #
    def method_missing(name, *args, &blk)
      __tally(name, *args, &blk)
      #define_method(name) do |*margs|
      #end
    end

    def tellme
      stats = @__stats
      Functor.new do |op, *margs|
        Functor.new do |sop, *vargs|
          stats.__send__(sop, op, *(margs + vargs))
        end
      end
    end

    #
    class Statistics
      attr :callstack

      def initialize
        @callstack = []
      end

      def <<(trace)
        @callstack.unshift(trace)
      end

      #def does
      #  Functor.new(op, *args)
      #    __send__(op, *args)
      #  end
      #end
      #alias_method :was, :does
      #alias_method :is, :does

      def returns(meth, *args)
        trace = @callstack.find{|t| t[0] == meth && t[1] == args}
        return false unless trace
        trace.last
      end
      #alias_method :return, :returns

      def returns?(meth, *args_and_val)
        args = args_and_val[0...-1]
        val  = args_and_val.last
        returns(meth, *args) == val
      end
      alias_method :return?, :returns?

      #
      def last_returns(meth)
        trace = @callstack.find{|t| t[0] == meth}
        raise unless trace
        trace.last
      end

      #
      def last_returned?(meth, val)
        last_returns(meth) == val
      end

      def count(meth)
        @callstack.map{ |t| t[0] == meth }.size
      end

      def called?(meth)
        trace = @callstack.find{ |t| t[0] == meth }
        !trace.empty?
      end

    end

  end

end

__END__

=begin
    # Recorder keeps track of all calls made against it.
    # The Recorder class can record any message call, however it
    # can not track keyword invocations such as =, |, and &.
    #
    class Recorder
      #alias_method :__respond_to?, :respond_to?
      public_instance_methods(true).each{ |m| private m unless /(^__|^repond_to\?$)/ =~ m }

      def initialize
        @__callstack__  = []
      end

      # TODO: Need a real public send (Ruby 1.9)
      def __replay__(object)
        x = object
        @__callstack__.each do |s, a, b|
          if x.respond_to?(s) # is it an existent public method ?
            x = b ? x.__send__(s, *a, &b) : x.__send__(s, *a)
          else
            x = b ? x.__send__(:method_missing, s, *a, &b) : x.__send__(:method_missing, s, *a)
          end
        end
        x
      end

      def __callstack__
        @__callstack__
      end

      #def __clear__
      #  @__callstack__ = []
      #end

      def method_missing(meth, *args, &block)
        @__callstack__ << [meth, args, block]
        self
      end
    end
=end

    # = Mock::Delegator
    #
    class Delegator
      instance_methods(true).each{ |m| protected m unless m.to_s =~ /^__/ }

      def initialize(object, mock_module)
        @instance_delegate = object
        extend(mock_module)
      end

      # Notice that __send__ calls at the private level, which is why #method_missing
      # is not ever invoked as defined by the mock extension. On the other hand, it
      # should probably be making public calls, in which case the mock would need to
      # delegate to a module instead of being one.
      def method_missing(s, *a, &b)
        if @instance_delegate.respond_to?(s)
          @instance_delegate.__send__(s, *a, &b)
        else
          raise NoMethodError, "undefined method `#{s}' for #{@instance_delegate}:#{@instance_delegate.class}"
        end
      end
    end#class Delegator

  end#class Mock

  class ::Object #:nodoc:
    # Create mock object.
    def mock(mock_module=nil)
      if mock_module
        Mock::Delegator.new(self, mock_module)
      else
        @_mock ||= Mock.new
        extend(@_mock)
        @_mock
      end
    end

    # We can't remove the module per-say.  So we have to
    # just neuter it. This is a very weak solution, but
    # it will suffice for the moment.
    #--
    # TODO: Use #unmix (Carats?).
    #++
    def remove_mock(mock_module=nil)
      mock_module ||= @_mock
      #mock_module.__method_table__.each{ |rec| rec.__clear__ }  # OLD WAY
      #meths = mock_module.__method_table__.uniq
      meths = mock_module.instance_methods(false)
      meths.each do |meth|
        mock_module.module_eval do
          remove_method(meth) #define_method(meth){ |*args| super }
        end
      end
      #extend(mock_module)
    end
  end#class ::Object

end
