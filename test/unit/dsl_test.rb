require 'test_helper'

context "DSL command creation and execution" do
  include Excavator::DSL

  setup do
    Excavator.reset!
    @runner = Excavator.runner
  end

  test "create a command" do
    refute @runner.find_command("test")
    cmd = command(:test) { puts "test" }
    assert cmd = @runner.find_command("test")
  end

  test "creating command clears out #last_command for a new command" do
    cmd1 = command(:first) {}
    refute_equal cmd1.object_id, @runner.last_command.object_id
  end

  test "adding a description to a command" do
    desc "test desc"
    command(:test) {}
    assert_equal "test desc", @runner.find_command("test").desc
  end

  test "create a namespaced command" do
    cmd = nil
    namespace :outer do
      cmd = command(:test) { }
    end

    assert found_cmd = @runner.find_command("outer:test")
    assert_equal cmd.object_id, found_cmd.object_id
  end

  test "command has access to it's namespace" do
    cmd = nil
    b = nil
    namespace :a do
      namespace :b do
        cmd = command(:inside) {}
      end
    end
    assert_equal :inside, cmd.name
    assert_equal :b, cmd.namespace.name
  end
end
