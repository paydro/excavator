require 'timeout'
module Excavator

  # Public: A Command is building block in Excavator. Commands are built
  # incrementally (normally via methods in Excavator::DSL).
  class Command
    # Descriptors
    attr_accessor :name, :desc, :namespace

    # The logic for the command
    attr_accessor :block

    # A list of Param objects
    attr_reader :param_definitions

    # Public: Parsed params (parsed using ParamParser)
    attr_reader :params

    # Public: An Array copy of arguments passed into this command
    # (i.e, before ParamParser#parse! is called)
    attr_reader :raw_params

    # Public: An Array of unparsed parameters. These are the left over arguments
    # after ParamParser#parse! is called.
    attr_reader :unparsed_params

    # Public: Reference to the Runner
    attr_reader :runner

    def initialize(runner, options = {})
      @runner            = runner
      @name              = options[:name]
      @desc              = options[:desc]
      @block             = options[:block]
      @param_definitions = options[:param_definitions] || []
      @namespace         = options[:namespace]
      @param_parser      = options[:param_parser] ||
                           Excavator.param_parser_class.new
      @params            = {}
    end

    # Public: Add a Param to this command.
    #
    # Examples
    #
    #   command = Command.new
    #   command.add_param(Param.new(:test))
    #
    # Returns nothing.
    def add_param(param)
      self.param_definitions << param
    end

    # Public: Execute the Command's block within a Excavator::Environment
    # instance. Arguments are parsed, setup with default values, and checked
    # to ensure the Command has all the proper parameters.
    #
    # args - An Array of arguments to pass into the block. This is normally
    #        the same format as ARGV.
    #
    # Examples
    #
    #   command = Command.new( ... )
    #   command.execute(["-a", "abc", "--foo", "bar"])
    #
    # Returns the value returned by the Command's block.
    def execute(*args)
      args.flatten!
      parse_params args
      run
    end

    # Public: Execute this command. This is like #execute except the parameters
    # is a Hash.
    #
    # parsed_params - A Hash of params to pass into the Command's block.
    #
    # Examples
    #
    #   command = Command.new( ... )
    #   command.execute({:a => "abc", :foo => "bar})
    #
    # Returns the value returned by the Command's block.
    def execute_with_params(parsed_params = {})
      parse_params [parsed_params]
      run
    end

    # Public: The full name of the Command. This includes the Namespace's name
    # and the Namespace's ancestor's names.
    #
    # Returns a String.
    def full_name
      namespace.nil? ? name.to_s : namespace.full_name(name)
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
      @param_parser.build(
        :name   => full_name,
        :desc   => desc,
        :params => param_definitions
      )
      @parser_built = true
    end
  end # Command
end
