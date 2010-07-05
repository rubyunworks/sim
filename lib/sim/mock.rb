require 'delegate'

module Sim

  # = Contract
  #
  class Contract < Module
    #public_instance_methods(true).each{ |m| private m unless /(^__|^repond_to\?$)/ =~ m }

    def initialize
      super
      @__contracts = {}
      @__delegating_module = Module.new
    end

    #
    def __delegating_module
      @__delegating_module
    end

    #
    def method_missing(name, *args, &blk)
      __c = @__contracts
      __c[[name, *args]] = blk

      define_method(name) do |*margs|
        b = __c[[name, *margs]]
        b ? b[super] : super
      end

      @__delegating_module.module_eval do
        define_method(name) do |*margs|
          b = __c[[name, *margs]]
          b ? b[@__object.__send__(name, *margs)] : @__object.__send__(name, *margs)
        end
      end
    end

    # = Mock::Delegator
    #
    class Delegator
      #instance_methods(true).each{ |m| private m unless m.to_s =~ /^__/ }

      def initialize(obj, mod)
        @__object = obj
        extend mod.__delegating_module
      end

      # Notice that __send__ calls at the private level, which is why #method_missing
      # is never invoked as defined by the module. On the other hand, it
      # should probably be making public calls, in which case it would need to
      # delegate to a module instead of being one.
      def method_missing(s, *a, &b)
        if @__object.respond_to?(s)
          @__object.__send__(s, *a, &b)
        else
          raise NoMethodError, "undefined method `#{s}' for #{@instance_delegate}:#{@instance_delegate.class}"
        end
      end
    end#class Delegator

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

  end#class Mock

  class ::Object #:nodoc:
    # Create mock object.
    def contract(mod=nil)
      if mod
        del = Sim::Contract::Delegator.new(self, mod)
        #del.extend(mod)
        del
      else
        @_contract ||= Contract.new
        extend(@_contract)
        @_contract
      end
    end

    # We can't remove the module per-say.  So we have to
    # just neuter it. This is a very weak solution, but
    # it will suffice for the moment.
    #--
    # TODO: Use #unmix (Carats?).
    #++
    def remove_contract(mod=nil)
      mod ||= @_contract
      #mock_module.__method_table__.each{ |rec| rec.__clear__ }  # OLD WAY
      #meths = mock_module.__method_table__.uniq
      meths = mod.instance_methods(false)
      meths.each do |meth|
        mod.module_eval do
          remove_method(meth) #define_method(meth){ |*args| super }
        end
      end
      #extend(mod)
    end
  end#class ::Object

end
