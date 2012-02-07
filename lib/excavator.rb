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

  # Public: The current working directory for the Excavator script.
  #
  # Returns a Pathname.
  def self.cwd
    @cwd ||= Pathname.new(Dir.pwd).expand_path
  end


  # Public: The global Runner object. This object is called from
  # Excavator.run to start the whole commandline parsing and command execution
  # process.
  #
  # Returns a Runner class.
  def self.runner
    @runner ||= runner_class.new
  end

  # Public: The global Runner assignment method.
  #
  # runner - Any Class that implements Excavator::Runner's public api.
  #
  def self.runner=(runner)
    @runner = runner
  end

  # Public: Start Excavator.
  #
  # On command error, this method will exit with a status of 1 and print
  # the error message to $stderr.
  #
  # params - An Array of parameters. This is normally ARGV.
  #
  # Examples
  #
  #   Excavator.run(ARGV)
  #   # => executes command passed in via ARGV
  #
  # Returns the object returned to by the command or exits with a status of 1.
  def self.run(params)
    begin
      runner.run(params)

    rescue => e
      $stderr.puts e.message
      if ENV['DEBUG'] == '1'
        e.backtrace.each { |line| $stderr.puts line }
      end

      exit 1
    end
  end

  # Internal: Setup class level configuration variables with defaults.
  #
  # Examples
  #
  #   module Excavator
  #     config :test, "test"
  #   end
  #
  #   Excavator.test
  #   # => "test"
  #
  #   Excavator.test = "123"
  #   Excavator.test
  #   # => "123"
  #
  # Returns nothing.
  def self.config(name, default)
    @config   ||= {}
    @defaults ||= {}
    @defaults[name.to_sym] = default
    module_eval <<-MOD, __FILE__, __LINE__  + 1
      def self.#{name}
        @config[:#{name}] || @defaults[:#{name}]
      end

      def self.#{name}=(val)
        @config[:#{name}] = val
      end
    MOD
  end

  # Internal: Resets the global Runner object. This is primarily used in
  # testing.
  #
  # Examples
  #
  #   Excavator.reset!
  #
  # Returns nothing.
  def self.reset!
    self.runner = nil
  end
end

require 'excavator/version'
require 'excavator/dsl'
require 'excavator/namespace'
require 'excavator/param'
require 'excavator/param_parser'
require 'excavator/command'
require 'excavator/environment'
require 'excavator/runner'
require 'excavator/table_view'

module Excavator
  config :command_paths,      []
  config :runner_class,       Runner
  config :namespace_class,    Namespace
  config :param_parser_class, ParamParser
  config :param_class,        Param
  config :command_class,      Command
  config :environment_class,  Environment
end
