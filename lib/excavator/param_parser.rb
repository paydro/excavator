require 'optparse'
module Excavator
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
      @parser.separator "USAGE: #{@name.to_s} [options]"
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
end
