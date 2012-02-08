module Excavator

  # Public: DSL is the primary interface for creating commands. When required,
  # the global scope is extended with helpers to create namespaces, parameters,
  # and commands.
  #
  # Examples
  #
  #   namespace :servers do
  #     desc "Create a new server"
  #     param :name, :desc => "Name of the server"
  #     param :region, :desc => "Region the server is created in"
  #     command :create do
  #       # ...
  #     end
  #   end
  #
  module DSL

    # Public: Create a namespace to group commands. Namespaces can be nested.
    # Namespace names are prefixed to the command name.
    #
    # This will create a new namespace if it doesn't exist. All commands defined
    # within the passed in block are added to the namespace.
    #
    # name  - A String or Symbol. This is used as a part of the command name.
    # block -
    #
    # Examples
    #
    #   # Creates the command "servers:create"
    #   namespace :servers do
    #     command :create do
    #       # ...
    #     end
    #   end
    #
    #   # Nesting namespaces
    #   namespace :public do
    #     namespace :instances do
    #       # ...
    #     end
    #   end
    #
    # Returns nothing.
    def namespace(name)
      Excavator.runner.in_namespace(name) do
        yield
      end
    end

    # Public: Adds a description to the next command declared.
    #
    # description - A String describing the command.
    #
    # Examples
    #
    #   desc "prints hello"
    #   command :print_hello { ... }
    #
    # Returns nothing.
    def desc(description)
      Excavator.runner.last_command.desc = description
    end

    # Public: Add a parameter to the next command declared. This passes all
    # parameters directly into Param#initialize.
    #
    # See the Param and ParamParser class for more details.
    #
    # name - A String or Symbol of the parameter name.
    # options - A Hash of Parameter options (default: {}).
    #           :desc     - A String describing the parameter.
    #           :default  - A default value for the parameter.
    #           :short    - A String (normally one character) to use as the
    #                       short switch for the parameter. For instance,
    #                       "param :test, :short => 'c'" will allow
    #                       the parameter to be used as "-c" on the command
    #                       line.
    #           :optional - A Boolean specifying whether the paramter is
    #                       optional.
    #
    # Examples
    #
    #   # A required parameter with the long switch "--name"
    #   param :name
    #
    #   # An optional parameter.
    #   param :name, :optional => true
    #
    #   # Set a description.
    #   param :name, :desc => "A name"
    #
    # Returns nothing.
    def param(name, options = {})
      param = Excavator.param_class.new(name, options)
      Excavator.runner.last_command.add_param(param)
    end

    # Public: Creates a command to add to Excavator.runner.
    #
    # name - A String or Symbole for the command.
    # block - A block of code to execute when the command is called. This block
    #         is executed within an instance of Excavator::Environment.
    #
    # Examples
    #
    #   command :hello do
    #     puts "hello"
    #   end
    #
    # Returns a Command.
    def command(name, &block)
      cmd = Excavator.runner.last_command
      cmd.name = name
      cmd.block = block
      Excavator.runner.current_namespace << cmd
      Excavator.runner.clear_last_command!
      cmd
    end

  end # DSL
end # Excavator

self.extend Excavator::DSL
