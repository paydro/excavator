module Excavator

  # Internal: Namespace is a container for other Namespaces and Commands.
  #
  # Examples
  #
  #   ns = Namespace.new
  #
  #   # Add a command
  #   ns << Command.new(:log)
  #
  #   # Add a namespace
  #   ns << Namespace.new(:database)
  #
  #   # Lookup a command
  #   ns.command(:log)
  #
  #   # Lookup a namespace
  #   ns.namespace(:namespace)
  #
  class Namespace

    # Public: A String/Symbol name for the namespace. This is used to build
    # a Command's full name used on the command line.
    attr_reader :name

    # Internal: A pointer to the parent Namespace (if any).
    attr_accessor :parent

    def initialize(name = nil, options = {})
      @name = name.to_sym if name
      @namespaces = {}
      @commands = {}
    end

    # Public: Add a Namespace or Command instance to this namespace.
    #
    # When adding namespaces, it will automatically set #parent attribute
    # on the new object.
    #
    # obj - A Command or Namespace to add to the namespace.
    #
    # Examples
    #
    #   ns = Namespace.new(:test)
    #
    #   # Add a namespace. The added namespace will have #parent set to 'ns'.
    #   recent = Namespace.new(:recent)
    #   ns << recent
    #   recent.parent
    #   # => ns
    #
    #   # Add a command.
    #   ns << Command.new(:name)
    #
    # Returns itself (Namespace).
    def <<(obj)
      if self.class === obj
        obj.parent = self
        @namespaces[obj.name] = obj
      else
        @commands[obj.name] = obj
      end

      self
    end

    # Public: Look up a command within this namespace. It does not look into
    # child namespaces.
    #
    # name - A String or Symbol name of the command to look up.
    #
    # Examples
    #
    #   ns = Namespace.new(:test)
    #   ns << Command.new(:run)
    #   ns.command("run")
    #   # => <Command :run>
    #
    # Returns a Command if the command exists in the namespace.
    # Returns nil if the command does not exist.
    def command(name)
      @commands[name.to_sym]
    end

    # Public: Look up a child namespace within this namespace.
    #
    # name - A String or Symbol name of the namespace to look up.
    #
    # Examples
    #
    #   ns = Namespace.new(:test)
    #   ns << Namespace.new(:recent)
    #   ns.namespace(:recent)
    #   # => <Namespace :recent>
    #
    # Returns a Namespace if it exists in the namespace.
    # Returns nil if the namespace does not exist.
    def namespace(name)
      @namespaces[name.to_sym]
    end

    # Public: The full name of the namespace. This returns a string of the
    # namespace name and it's ancestor's name joined by ":". A namespace with
    # no parent will return an emptry String.
    #
    # command_name - An optional String or Symbol name of a command to append
    #                to the end of the namespace's full name.
    #
    # Examples
    #
    #   ns_a = Namespace.new(:a)
    #   ns_b = Namespace.new(:b)
    #   ns_c = Namespace.new(:c)
    #
    #   ns_a << ns_b
    #   ns_b << ns_c
    #
    #   ns_a.full_name
    #   # => ""
    #
    #   ns_b.full_name
    #   # => "a:b"
    #
    #   ns_c.full_name
    #   # => "a:b:c"
    #
    #   ns_c.full_name("zebra")
    #   # => "a:b:c:zebra"
    #
    # Returns a String.
    def full_name(command_name = nil)
      return "#{command_name}" if parent.nil?

      parts = []
      parts << parent.full_name if parent.full_name != ""
      parts << name.to_s
      parts << command_name.to_s if command_name

      parts.compact.join(":")
    end

    # Public: An array of full command names and their description. This will
    # include all commands in child namespaces as well.
    #
    # Examples
    #
    #   # Setup
    #   ns_a = Namespace.new(:a)
    #   ns_b = Namespace.new(:b)
    #   ns_c = Namespace.new(:c)
    #
    #   # A > B > C
    #   ns_a << ns_b
    #   ns_b << ns_c
    #
    #   ns_b << Command.new(:foo, :desc => "Foo Desc")
    #   ns_c << Command.new(:bar, :desc => "Bar Desc")
    #
    #   ns_a.commands_and_descriptions
    #   # => [
    #   #   ["a:b:foo", "Foo Desc"],
    #   #   ["a:b:c:bar", "Bar Desc"
    #   # ]
    #
    # Returns an Array of two item Arrays.
    def commands_and_descriptions
      items = []
      @commands.each do |cmd_name, cmd|
        items << [
          cmd.full_name,
          cmd.desc
        ]
      end

      @namespaces.each do |ns_name, ns|
        items.push(*ns.commands_and_descriptions)
      end

      items.sort
    end
  end
end
