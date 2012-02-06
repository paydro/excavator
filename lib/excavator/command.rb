require 'timeout'
module Excavator
  class Command
    # Descriptors
    attr_accessor :name, :desc, :namespace

    # Block to run when command is executed
    attr_accessor :block

    # A list of Param objects
    attr_reader :param_definitions

    attr_reader :params
    attr_reader :raw_params
    attr_reader :unparsed_params

    attr_reader :runner

    def initialize(runner, options = {})
      @runner            = runner
      @name              = options[:name]
      @block             = options[:block]
      @param_definitions = options[:param_definitions] || []
      @namespace         = options[:namespace]
      @param_parser      = options[:param_parser] ||
                           Excavator.param_parser_class.new
      @params            = {}
    end

    def add_param(param)
      self.param_definitions << param
    end

    def execute(*inputs)
      inputs.flatten!
      parse_params inputs
      run
    end

    def execute_with_params(parsed_params = {})
      parse_params [parsed_params]
      run
    end

    protected

    # Internal
    def run
      env = Excavator.environment_class.new(
        :runner          => runner,
        :params          => params,
        :unparsed_params => unparsed_params,
        :raw_params      => raw_params
      )
      env.instance_eval(&block)
    end

    # Internal
    def parse_params(inputs)
      build_parser
      @raw_params = inputs.dup
      @params = @param_parser.parse!(inputs) if param_definitions.size > 0
      @unparsed_params = inputs
    end

    def build_parser
      return if @parser_built
      command_name = ""
      command_name << "#{namespace.full_name}:" if namespace
      command_name << name.to_s
      @param_parser.build(
        :name   => command_name,
        :desc   => desc,
        :params => param_definitions
      )
      @parser_built = true
    end
  end # Command
end
