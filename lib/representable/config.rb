module Representable
  # Config contains three independent, inheritable directives: features, options and definitions.
  # Inherit from parent with Config#inherit!(parent).
  class Config < Inheritable::Hash
    # Keep in mind that performance doesn't matter here as 99.9% of all representers are created
    # at compile-time.

    # Stores Definitions from ::property. It preserves the adding order (1.9+).
    # Same-named properties get overridden, just like in a Hash.
    class Definitions < Inheritable::Hash
      def <<(definition)
        warn "[Representable] Deprecation Warning: `representable_attrs <<` is deprecated and will be removed in 1.10. Please use representable_attrs[:title] = {} and keep it real."
        store(definition.name, definition)
      end

      def add(name, options)
        if options.delete(:inherit) # i like that: the :inherit shouldn't be handled outside.
          return get(name).merge!(options)
        end

        self[name.to_s] = Definition.new(name, options)
      end

      def get(name)
        self[name.to_s]
      end

      extend Forwardable
      def_delegators :values, :each # so we look like an array. this is only used in Mapper. we could change that so we don't need to hide the hash.
    end


    def initialize
        super
        merge!(:features    => @features     = Inheritable::Hash.new,
                :definitions => @definitions  = Definitions.new,
                :options     => @options      = Inheritable::Hash.new)
    end
    attr_reader :options

    def features
      @features.keys
    end

    def _features
      @features
    end

    # delegate #collect etc to Definitions instance.
    extend Forwardable

    def_delegators :@definitions, :get, :add, :each, :size # :[] , :<<
    # include Enumerable


    def wrap=(value)
      value = value.to_s if value.is_a?(Symbol)
      @wrap = Uber::Options::Value.new(value)
    end

    # Computes the wrap string or returns false.
    def wrap_for(name, context, *args)
      return unless @wrap

      value = @wrap.evaluate(context, *args)

      return infer_name_for(name) if value === true
      value
    end

  private
    def infer_name_for(name)
      name.to_s.split('::').last.
       gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
       gsub(/([a-z\d])([A-Z])/,'\1_\2').
       downcase
    end
  end
end
