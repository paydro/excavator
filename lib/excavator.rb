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

  def self.cwd
    @cwd ||= Pathname.new(Dir.pwd).expand_path
  end

  def self.reset!
    self.runner = nil
  end

  def self.runner
    @runner ||= runner_class.new
  end

  def self.runner=(runner)
    @runner = runner
  end

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
  # Setup defaults classes
  config :command_paths,      []
  config :runner_class,       Runner
  config :namespace_class,    Namespace
  config :param_parser_class, ParamParser
  config :param_class,        Param
  config :command_class,      Command
  config :environment_class,  Environment
end
