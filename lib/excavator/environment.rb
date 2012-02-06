module Excavator
  class Environment

    def self.modify(*mods, &block)
      mods.each { |m| include m }
      instance_eval &block if block
    end

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
end
