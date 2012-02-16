# -*- encoding: utf-8 -*-

require 'excavator'

module Excavator

  # Public: Runner is the entry point into an Excavator script library. When
  # running an Excavator script from the command line, a Runner object is
  # created.
  #
  # Runner duties:
  #
  # * Load all Excavator commands.
  # * Provides the object that Excavator::DSL manipulates.
  # * Finds the command from the command line arguments and executes.
  # * Creates a useful help message to list all commands defined in the
  #   library.
  #
  class Runner

    # Public: An Array of filesystem paths where Excavator commands are found.
    attr_writer :command_paths

    # Public: A pointer to the current namespace.
    attr_reader :current_namespace

    def initialize
      @namespace = Namespace.new(:default)
      @current_namespace = @namespace
    end

    # Public: Return the current working directory for the script.
    def cwd
      Excavator.cwd
    end

    # Public: A pointer to the current namespace being worked on.
    def current_namespace
      @current_namespace
    end

    # Public: An Array of filesystem paths where Excavator commands are found.
    # Defaults to the current directory's "command/" directory.
    def command_paths
      @command_paths = Excavator.command_paths || [cwd.join("commands")]
    end

    # Public: A helper to move the current_namespace pointer to new namespace,
    # yield, and then return the pointer back to the previous namespace. If the
    # namespace argument already exists (e.g., created by another file), then
    # this points to the previously created namespace.
    #
    # name - A String/Symbol of the namespace to move the current_namespace
    #        pointer to.
    #
    # Examples
    #
    #   runner = Runner.new
    #   runner.in_namespace("test") do
    #     runner.current_namespace
    #     # => <Namespace "test">
    #   end
    #
    # Returns nothing.
    def in_namespace(name)
      ns = @current_namespace.namespace(name) ||
           Excavator.namespace_class.new(name)
      @current_namespace << ns

      @current_namespace = ns
      yield
      @current_namespace = ns.parent
    end

    # Public: The entry point into all commands. This will load all commands
    # from any external Excavator files, find the command from the command line,
    # and execute the command.
    #
    # This method is never called directly. See Excavator.run.
    #
    # Returns value returned from the Command.
    def run(*args)
      args = ARGV if args.nil?
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

    # Public: Find a command given it's full name.
    #
    # cmd - A String/Symbol full name of the Command to look up.
    #       (e.g., "server:test:integration")
    #
    # Returns a Command.
    def find_command(cmd)
      *namespaces, command_name = cmd.to_s.split(':').collect {|c| c.to_sym }
      cur_namespace = current_namespace
      namespaces.each do |n|
        cur_namespace = cur_namespace.namespace(n)
      end

      cur_namespace.command(command_name)
    end

    # Public: The last command being worked on. This is designed for use
    # with Excavator::DSL methods.
    def last_command
      @last_command ||= Excavator.command_class.new(
        self, :namespace => current_namespace
      )
    end

    # Public: Clear the last command being worked on. This is designed for use
    # with Excavator::DSL methods.
    def clear_last_command!
      @last_command = nil
    end

    # Internal: Display the list of all command names and their descriptions.
    def display_help
      table_view = Excavator::TableView.new do |t|
        t.title "#{File.basename($0)} commands:\n"
        t.header "Command"
        t.header "Description"
        t.divider "\t"

        namespace.commands_and_descriptions.sort.each do |command|
          t.record *command
        end
      end

      puts table_view
    end

    # Internal: The root namespace for all other commands and namespaces.
    def namespace
      @namespace
    end

    protected

    def display_help?(command_name)
      ["-h", "-?", "--help", "help"].include?(command_name)
    end

    # Internal: Loop through each command path and load all *.rb files.
    def load_commands
      command_paths.each do |path|
        Dir["#{path.to_s}/**/*.rb"].each { |file| load file }
      end
    end

  end # Runner
end
