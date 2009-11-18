module Sim

  # = Stub
  #
  # TODO: Consider the rewrite of Mock and see if it can be used
  # to imporve the design of Stub.
  #
  class Stub < Module
    #attr :object

    def initialize
      super()
      @table = {}
    end

    #
    def __table__ ; @table ; end

    #
    def method_missing(meth, *args, &block)
      table     = @table
      interface = [meth, args, block_given?]

      table[interface] = nil

      define_method(meth) do |*args|
        table[[meth, args, block_given?]]
      end

      Setter.new(table, interface)
    end

    #
    class Setter
      def initialize(table, interface)
        @table     = table
        @interface = interface
      end

      def ==(result)
        @table[@interface] = result
      end
    end#class Setter

    # = Stub::Delegator
    #
    class Delegator
      instance_methods(true).each{ |m| protected m unless m.to_s =~ /^__/ }

      def initialize(object, stub_module)
        @instance_delegate = object
        extend(stub_module)
      end

      def method_missing(s, *a, &b)
        @instance_delegate.__send__(s, *a, &b)
      end
    end

  end#class Stub

  class ::Object

    # Create a new stub.
    def stub(stub_module=nil)
      if stub_module
        Stub::Delegator.new(self, stub_module)
      else
        @_stub ||= Stub.new
        extend(@_stub)
        @_stub
      end
    end

    # We can't remove the module per-say.  So we have to
    # just neuter it. This is a very weak solution, but
    # it will suffice for the moment.
    def remove_stub(stub_module=nil)
      stub_module ||= @_stub
      unextend(stub_module)
      #obj = self
      #mod = Module.new
      #stub_module.__table__.each do |interface, result|
      #  meth = interface[0]
      #  mod.module_eval do
      #    define_method(meth, &obj.class.instance_method(meth).bind(obj))
      #  end
      #end
      #extend(mod)
    end

    #--
    # TODO: Use Carats for #unmix ?
    #++
    def unextend(mod)
      meths = mod.instance_methods(false)
      meths.each do |meth|
        mod.module_eval do
          remove_method(meth) #define_method(meth){ |*args| super }
        end
      end
      #extend(stub_module)
    end

  end#class ::Object

end

