require 'albacore/paths'

module Albacore
  # a small DSL to mix into your configuration classes
  module ConfigDSL
    # creates a new attr_writer for the symbols passed,
    # such that a write to that method will normalise the paths
    # of the written value: you can pass an optional callback
    def attr_path *syms, &block
      given = block_given?

      syms.each do |sym|

        # this is the callback method when the value is set
        self.send(:define_method, :"__on_#{sym}") do |val|
          instance_exec(val, &block) if given
        end

        # this is the setter, it also calls the callback method
        # defined above.
        self.class_eval(
%{def #{sym}= val
  @#{sym} = ::Albacore::Paths.normalise_slashes val
  __on_#{sym} @#{sym}
end})
      end 
    end

    # read/write attribute with rewriting of set values to
    # match the system's paths
    def attr_path_accessor *syms, &block
      given = block_given?

      syms.each do |sym|

        # this is the callback method when the value is set
        self.send(:define_method, :"__on_#{sym}") do |val|
          instance_exec(val, &block) if given
        end

        # this is the setter and getter. The setter also calls
        # the callback method defined above.
        self.class_eval(
%{def #{sym}= val
  @#{sym} = ::Albacore::Paths.normalise_slashes val
  __on_#{sym} @#{sym}
end})
        self.class_eval(
%{def #{sym}
  @#{sym}
end})
      end 
    end
  end
end
