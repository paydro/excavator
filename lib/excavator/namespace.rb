module Excavator
  class Namespace
    attr_reader :name
    attr_accessor :parent

    def initialize(name = nil, options = {})
      @name = name.to_sym if name
      @namespaces = {}
      @commands = {}
    end

    def <<(obj)
      if self.class === obj
        obj.parent = self
        @namespaces[obj.name] = obj
      else
        @commands[obj.name] = obj
      end
    end

    def command(name)
      @commands[name.to_sym]
    end

    def namespace(name)
      @namespaces[name.to_sym]
    end

    def full_name(command_name = nil)
      return "#{command_name}" if parent.nil?

      parts = []
      parts << parent.full_name if parent.full_name != ""
      parts << name.to_s
      parts << command_name.to_s if command_name

      parts.compact.join(":")
    end

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
