# -*- encoding: utf-8 -*-

module Excavator

  # Public: Environment instances are created for a Command's block to execute
  # in. It is designed for modification and manipulation. Adding other methods
  # into this class will allow all Commands to reference them.
  #
  # Examples
  #
  #   module Helpers
  #     def pretty_logger(msg)
  #       puts "*~*~*~*"
  #       puts msg
  #       puts "*~*~*~*"
  #     end
  #   end
  #
  #   # Add Helpers to Environment
  #   Excavator::Environment.modify Helpers
  #
  #   param :msg
  #   command :print do
  #     # #pretty_logger is now available
  #     pretty_logger params[:msg]
  #   end
  #
  class Environment

    # Public: A convenience method to include other modules in this class.
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

    # Public: Execute another command. This is a convenience method to execute
    # other commands defined in Excavator. #execute will return the value
    # of the executed command (useful for building reusable blocks of code).
    #
    # command - A String full name of a command. This should include namespaces.
    # params  - A Hash of Param name to values to pass to this command.
    #
    # Examples
    #
    #   namespace :test do
    #     command :prepare do
    #       puts params[:foo]
    #       # => "bar"
    #     end
    #
    #     command :run do
    #       execute "test:prepare", {:foo => "bar"}
    #     end
    #   end
    #
    # Returns value from executed command.
    def execute(command, params = {})
      command = runner.find_command(command)
      command.execute(params)
    end
  end
end
