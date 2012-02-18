# -*- encoding: utf-8 -*-

require 'optparse'
module Excavator

  # Public: ParamParser is a strategy object to integrate Command, Param, and
  # OptionParser to parse commandline arguments.
  #
  # ParamParser is the heart of Excavator. It takes Params and a Command and
  # creates a command line parser that:
  #
  # * automatically assigns short and long switches for params
  #   (e.g. :name => --name or -n)
  # * parsers arguments into named parameters
  # * assigns default values to parameters if specified
  # * creates a help message
  # * verifies required params are passed - throws an error if they are not
  #
  # Examples
  #
  #   parser = Excavator::ParamParser.new
  #   parser.build(
  #     :name => "command_name",
  #     :desc => "command description",
  #     :params => [ <Param>, <Param>, ... ]
  #   )
  #
  #   parser.parse!(ARGV)
  #   # => { :param1 => "val", :param2 => "val2", ... }
  #
  class ParamParser

    class InvalidShortSwitch < ExcavatorError; end

    attr_accessor :name

    def initialize
      @parser = OptionParser.new
      @parsed_params = {}
      @params = []
    end

    # Public: Builds the parser up with the name, description and Params
    # passed in.
    #
    # This builds an OptionParser object with a "-h" and "--help" option.
    #
    # options - A Hash of parameters needed to build the parser.
    #           :name - A String/Symbol name of the Command.
    #           :desc - A String description of the command.
    #           :params - An Array of Params.
    #
    # Examples
    #
    #   ParamParser.new.build({
    #     :name => "test_command",
    #     :desc => "description",
    #     :params => [<Param>, <Param>]
    #   })
    #
    # Returns nothing.
    def build(options = {})
      @name   = options[:name] #if options[:name]
      @params = options[:params] #if options[:params]
      @desc   = options[:desc] #if options[:desc]

      required_params = []
      optional_params = []

      @parser.banner = @desc
      @parser.separator ""
      @parser.separator "USAGE: #{@name} [options]"
      @params.each do |param|
        opts = []

        # Long option
        opts << "--#{param.name.to_s.gsub("_", "-")}"

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

    # Public: Parses command line arguments. Any argument matching Params are
    # removed from the argument list (destructive!) and returned in a hash.
    #
    # args - An Array of command line arguments. This is usually ARGV.
    #        If the last argument in the Array is a Hash, it is used as the
    #        default parameters. This is a convience method to pass arguments
    #        in a Hash form rather than an Array like ARGV.
    #
    # Examples
    #
    #   parser = ParamParser.new
    #   parser.build({...})
    #
    #   # Standard usage - assuming there is :name param.
    #   args = ["command", "--name", "hello"]
    #   parser.parse!(args)
    #   # => {:name => "hello"},
    #   # => args is now ["command"]
    #
    #   # Same as above, but the hash is checked to see whether or not
    #   # the required params are met.
    #   parser.parse!([{:name => "hello"}])
    #   # => {:name => "hello"}
    #
    #   # Assume :name is required
    #   parser.parse!(["command"])
    #   # => Raises MissingParamsError
    #
    # Returns a Hash of Symbol names to values.
    # Raises Excavator::MissingParamsError if args is missing required params.
    def parse!(args)
      @parsed_params = args.last.is_a?(Hash) ? args.pop : {}

      @parser.parse!(args)
      set_default_params
      detect_missing_params!

      @parsed_params
    end

    # Public: Print out a help message for this parser.
    def usage
      @parser.to_s
    end

    protected

    def detect_missing_params!
      missing_params = []
      @params.each do |p|
        if p.required? && !@parsed_params.has_key?(p.name)
          missing_params << p.name
        end
      end

      raise MissingParamsError.new(missing_params) if missing_params.size > 0
    end


    def set_default_params
      @params.each do |param|
        next unless param.default
        unless @parsed_params.has_key?(param.name)
          @parsed_params[param.name] = param.default
        end
      end
    end

    def short_switch(param)
      if param.short == "h"
        raise InvalidShortSwitch.new(<<-ERRMSG.strip!)
          The '-h' short switch is reserved for help.
        ERRMSG
      end

      # TODO Raise error for params with specified short switches that collide.
      #      For now, we'll assume the user knows if they have the same
      #      short switches when specifying them.
      return "-#{param.short}" if param.short

      param_name = param.name.to_s
      short = nil
      param_name.each_char do |c|
        next if c == "h"
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
end
