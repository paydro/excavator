require 'test_helper'

context "Environment" do
  include Excavator
  include Excavator::DSL

  setup do
    Excavator.reset!
    Excavator.command_paths = [
      basedir.join("test", "fixtures", "commands")
    ]
  end

  test "execute another command" do
    cmd = command(:first) { execute :second }
    command(:second) { "called from second" }
    assert_equal "called from second", cmd.execute
  end

  test "execute command with params" do
    cmd = command(:run_another_cmd) do
      execute :my_name, :name => 'paydro'
    end

    param :name
    command(:my_name) { params[:name] }

    assert_equal "paydro", cmd.execute
  end

end # Environment

context "Environment#modify" do
  include Excavator

  module OtherCommands
    def hello
      "world"
    end
  end

  setup do
    env_class = Class.new(Excavator::Environment)
    Excavator.environment_class = env_class
    @class = env_class
  end

  teardown do
    Excavator.environment_class = nil
  end

  test "modify environment with modules" do
    @class.modify OtherCommands
    assert_equal "world", @class.new.hello
  end

  test "modify environment with a block" do
    @class.modify do
      include OtherCommands
    end

    assert_equal "world", @class.new.hello
  end
end
