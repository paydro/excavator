module Excavator
  # Needs to depend on the runner
  module DSL
    def namespace(name)
      Excavator.runner.in_namespace(name) do
        yield
      end
    end

    def desc(description)
      Excavator.runner.last_command.desc = description
    end

    def param(name, options = {})
      Excavator.runner.last_command.add_param(Param.new(name, options))
    end

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


