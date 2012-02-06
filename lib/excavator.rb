require 'pathname'

module Excavator

  class ExcavatorError < ::StandardError; end

  class MissingParamsError < ExcavatorError
    attr_reader :params
    def initialize(params)
      @params = params
      super "Missing parameters: #{params.join(", ")}."
    end
  end

  def self.run(params)
    runner.run(params)
  end

  def self.runner
    @runner ||= Runner.new
  end

  def self.reset!
    @runner = nil
  end

  class TableView
    class InvalidDataForHeaders < StandardError; end

    DEFAULT_DIVIDER = " | "

    def initialize(options = {})
      @options = options
      @_title = ""
      @_headers = []
      @_records = []
      @col_widths = Hash.new { |hash, key| hash[key] = 0 }
      @divider = options[:divider] || DEFAULT_DIVIDER

      yield self if block_given?
    end

    def title(t = nil)
      if t.nil?
        @_title = t
      else
        @_title = t
      end
    end

    def header(*headers)
      headers.flatten!

      headers.each do |h|
        index = @_headers.size
        @_headers << h
        @col_widths[h] = h.to_s.size
      end
    end

    def divider(str)
      @divider = str
    end

    def record(*args)
      args.flatten!
      if args.size != @_headers.size
        raise InvalidDataForHeaders.new(<<-MSG)
          Number of columns for record (#{args.size}) does not match number
          of headers (#{@_headers.size})
        MSG
      end
      update_column_widths Hash[*@_headers.zip(args).flatten]
      @_records << args
    end

    def to_s
      out = ""
      out << @_title << "\n" if !@_title.nil? && @_title != ""

      print_headers out

      @_records.each_with_index do |record|
        record.each_with_index do |val, i|
          out << column_formats[i] % val
          out << @divider if i != (record.size - 1)
        end
        out << "\n"
      end
      out << "\n"

      out
    end

    def update_column_widths(hash)
      hash.each do |key, val|
        @col_widths[key] = val.size if val && val.size > @col_widths[key]
      end
    end

    def print_headers(out)
      @_headers.each_with_index do |h, i|
        out << column_formats[i] % h
        out << @divider if i != (@_headers.size - 1)
      end
      out << "\n"
    end

    # Internal
    def column_formats
      @col_widths.collect { |h, width| "%-#{width}s" }
    end
  end

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


  require 'optparse'
  class ParamParser

    attr_accessor :name
    attr_accessor :banner

    def initialize
      @parser = OptionParser.new
      @parsed_params = {}
      @params = []
    end

    def build(options = {})
      @name   = options[:name] if options[:name]
      @params = options[:params] if options[:params]
      @desc   = options[:desc] if options[:desc]

      required_params = []
      optional_params = []

      @parser.banner = @desc
      @parser.separator ""
      @parser.separator "USAGE: #{@name} [options]"
      @params.each do |param|
        opts = []

        # Long option
        opts << "--#{param.name}"

        # params require an argument (for now)
        opts << "=#{param.name.to_s.upcase}"

        # Short option
        opts << short_switch(param)

        opts << param.desc if param.desc
        opts << "Defaults to: #{param.default}" if param.default

        opts << Proc.new do |val|
          @parsed_params[param.name] = val
        end

        opts.compact!

        if param.required?
          required_params << opts
        else
          optional_params << opts
        end
      end

      if required_params.size > 0
        @parser.separator ""
        @parser.separator "REQUIRED:"
        required_params.each { |opts| @parser.on(*opts) }
      end

      if optional_params.size > 0
        @parser.separator ""
        @parser.separator "OPTIONAL:"
        optional_params.each { |opts| @parser.on(*opts) }
      end

      @parser.separator ""
      @parser.on_tail("-h", "--help", "This message.") do
        puts usage
        exit 1
      end
    end

    def parse!(args)
      @parsed_params = args.last.is_a?(Hash) ? args.pop : {}

      @parser.parse!(args)
      set_default_params
      detect_missing_params!

      @parsed_params
    end

    def detect_missing_params!
      missing_params = []
      @params.each do |p|
        if p.required? && !@parsed_params.has_key?(p.name)
          missing_params << p.name
        end
      end

      raise MissingParamsError.new(missing_params) if missing_params.size > 0
    end

    def usage
      @parser.to_s
    end

    protected

    def set_default_params
      @params.each do |param|
        next unless param.default
        unless @parsed_params.has_key?(param.name)
          @parsed_params[param.name] = param.default
        end
      end
    end

    def short_switch(param)
      # TODO Raise error for params with specified short switches that collide.
      #      For now, we'll assume the user knows if they have the same
      #      short switches when specifying them.
      return "-#{param.short}" if param.short

      param_name = param.name.to_s
      short = nil
      param_name.each_char do |c|
        short = c
        if @params.detect { |p| p != param && p.short == c }
          short = nil if c == param_name[-1]
          next
        else
          break
        end
      end

      return nil unless short

      # Set the param's short var so that later auto short switch creation
      # can determine a collision
      param.short = short

      "-#{short}"
    end

  end

  require 'timeout'
  class Command

    class Env
      attr_reader :runner, :params, :unparsed_params, :raw_params

      def initialize(options = {})
        @runner          = options[:runner]
        @params          = options[:params]
        @raw_params      = options[:raw_params]
        @unparsed_params = options[:unparsed_params]
      end

      # Execute another command
      def execute(command, params = {})
        command = runner.find_command(command)
        command.execute(params)
      end
    end

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
      @param_parser      = options[:param_parser] || ParamParser.new
      @params            = {}
    end

    def add_param(param_name, options = {})
      # TODO remove this coupling of Param
      self.param_definitions << Param.new(param_name, options)
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
      env = Env.new(
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


  class Namespace
    attr_reader :name
    attr_accessor :parent

    def initialize(name = nil, options = {})
      @name = name.to_sym if name
      @namespaces = {}
      @commands = {}
    end

    def <<(obj)
      if self.class === obj
        obj.parent = self
        @namespaces[obj.name] = obj
      else
        @commands[obj.name] = obj
      end
    end

    def command(name)
      @commands[name.to_sym]
    end

    def namespace(name)
      @namespaces[name.to_sym]
    end

    def full_name(command_name = nil)
      return "#{command_name}" if parent.nil?

      parts = []
      parts << parent.full_name if parent.full_name != ""
      parts << name.to_s
      parts << command_name.to_s if command_name

      parts.compact.join(":")
    end

    def commands_and_descriptions
      items = []
      @commands.each do |cmd_name, cmd|
        items << [
          full_name(cmd_name),
          cmd.desc
        ]
      end

      @namespaces.each do |ns_name, ns|
        items.push(*ns.commands_and_descriptions)
      end

      items.sort
    end
  end


  # Extractable class
  require 'pathname'
  class Runner

    # Runner specific vars
    attr_accessor :basedir
    attr_accessor :command_paths
    attr_accessor :commands
    attr_reader :current_namespace

    def initialize
      @basedir = Pathname.new(__FILE__).join("..", "..").expand_path
      @command_paths = [
        basedir.join("commands")
      ]

      @namespace = Namespace.new(:default)
      @current_namespace = @namespace
    end

    def cwd
      Pathname.new(Dir.pwd)
    end

    def namespaces
      @namespaces
    end

    def namespace
      @namespace
    end

    def current_namespace
      @current_namespace
    end

    def in_namespace(name)
      ns = @current_namespace.namespace(name)
      ns = @current_namespace << Namespace.new(name) unless ns
      @current_namespace = ns
      yield
      @current_namespace = ns.parent
    end

    def clear_commands!
      self.commands = {}
    end

    def run(*args)
      args.flatten!

      name = args.delete_at(0)
      load_commands

      if (name.nil? && args.size == 0) || display_help?(name)
        display_help
        return
      end

      command = find_command name
      command.execute *args
    end

    def find_command(cmd)
      *namespaces, command_name = cmd.to_s.split(':').collect {|c| c.to_sym }
      cur_namespace = current_namespace
      namespaces.each do |n|
        cur_namespace = cur_namespace.namespace(n)
      end

      cur_namespace.command(command_name)
    end

    def display_help?(command_name)
      ["-h", "-?", "--help", "help"].include?(command_name)
    end

    def display_help
      table_view = Bulldozer::TableView.new do |t|
        t.title "Bulldozer commands:\n"
        t.header "Command"
        t.header "Description"
        t.divider "\t"

        namespace.commands_and_descriptions.sort.each do |command|
          t.record *command
        end
      end

      puts table_view
    end

    def load_commands
      command_paths.each do |path|
        Dir["#{path.to_s}/**/*.rb"].each { |file| load file }
      end
    end

    def last_command
      @last_command ||= Command.new(self, :namespace => current_namespace)
    end

    def clear_last_command!
      @last_command = nil
    end
  end # Runner
end

require 'excavator/version'
require 'excavator/dsl'

