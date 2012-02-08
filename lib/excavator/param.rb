module Excavator

  # Internal: Param is an object to describe the attributes of a parameter.
  # There's never a need to instantiate these directly - instead use DSL#param.
  class Param

    # Public: The String/Symbol name of the Param.
    attr_reader :name

    # Public: An optional default value for the Param.
    attr_reader :default

    # Public: An optional String description for the Param.
    attr_reader :desc

    # Public: An optional String (normally one character) to use as the short
    # switch for the Param.
    attr_accessor :short

    def initialize(name, options = {})
      @name     = name
      @default  = options[:default]
      @optional = options[:optional]
      @desc     = options[:desc]
      @short    = options[:short]
    end

    # Public: Returns whether or not the Param is required.
    #
    # Returns a Boolean.
    def required?
      !optional?
    end

    # Public: Returns whether or not the Param is optional.
    #
    # Returns a Boolean.
    def optional?
      @default || (@default.nil? && @optional)
    end

  end # Param
end
