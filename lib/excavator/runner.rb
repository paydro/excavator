require 'excavator'
module Excavator
  class Runner

    # Runner specific vars
    attr_accessor :command_paths
    attr_accessor :commands
    attr_reader :current_namespace

    def initialize
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
      ns = @current_namespace << Excavator.namespace_class.new(name) unless ns
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

    def load_commands
      command_paths.each do |path|
        Dir["#{path.to_s}/**/*.rb"].each { |file| load file }
      end
    end

    def last_command
      @last_command ||= Excavator.command_class.new(
        self, :namespace => current_namespace
      )
    end

    def clear_last_command!
      @last_command = nil
    end

    def command_paths
      @command_paths = Excavator.command_paths || [cwd.join("commands")]
    end
  end # Runner
end
