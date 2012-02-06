module Excavator
  class Param
    attr_reader :name
    attr_reader :default
    attr_reader :desc
    attr_accessor :short # Set by the ParamParser

    def initialize(name, options = {})
      @name     = name
      @default  = options[:default]
      @optional = options[:optional]
      @desc     = options[:desc]
      @short    = options[:short]
    end

    def required?
      !optional?
    end

    def optional?
      @default || (@default.nil? && @optional)
    end

  end # Param
end
