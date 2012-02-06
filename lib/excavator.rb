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

  def self.runner=(runner)
    @runner = runner
  end

  def self.reset!
    @runner = nil
  end
end

require 'excavator/version'
require 'excavator/dsl'
require 'excavator/namespace'
require 'excavator/param'
require 'excavator/param_parser'
require 'excavator/command'
require 'excavator/runner'
require 'excavator/table_view'
