require 'test_helper'

context "Runner" do
  setup do
    @runner = Excavator::Runner.new
  end

  test "default namespace" do
    assert_equal :default, @runner.namespace.name
  end

  test "default namespace has no parent" do
    assert_nil @runner.namespace.parent
  end

  test "#current_namespace returns namespaced command scope" do
    first_namespace = nil
    second_namespace = nil
    @runner.in_namespace(:first) do
      first_namespace = @runner.current_namespace
      @runner.in_namespace(:second) do
        second_namespace = @runner.current_namespace
      end
    end

    assert_equal :first, first_namespace.name
    assert_equal :second, second_namespace.name
  end

  test "#last_command keeps track of the last command" do
    cmd1 = @runner.last_command
    cmd2 = @runner.last_command
    assert_equal cmd1.object_id, cmd2.object_id
  end

  test "#clear_last_command! does what it's name says" do
    cmd1 = @runner.last_command
    @runner.clear_last_command!
    cmd2 = @runner.last_command

    refute_equal cmd1.object_id, cmd2.object_id
  end

  test "add namespace" do
    ns = Excavator::Namespace.new(:servers)
    @runner.current_namespace << ns
    assert_equal ns, @runner.current_namespace.namespace(:servers)
  end

  test "add a command to the runner" do
    cmd = MiniTest::Mock.new
    cmd.expect(:name, :server)
    @runner.current_namespace << cmd
    assert_equal cmd.object_id, @runner.find_command(:server).object_id
  end

  test "add command and namespace with the same name" do
    ns = Excavator::Namespace.new(:server)
    cmd = MiniTest::Mock.new
    cmd.expect(:name, :server)

    @runner.current_namespace << ns
    @runner.current_namespace << cmd

    assert_equal cmd.object_id, @runner.find_command("server").object_id
    assert ns, @runner.current_namespace.namespace(:server)
  end
end


context "Loading excavator commands from files (Runner#run)" do
  setup do
    Excavator.reset!
    Excavator.runner.command_paths = [
      basedir.join("test", "fixtures", "commands")
    ]
  end

  test "execute a command" do
    out, error = capture_io do
      Excavator.runner.run("test")
    end
    assert_match /test command/, out
  end

  test "2-level namespace command" do
    out, error = capture_io do
      Excavator.runner.run("first:second:third")
    end
    assert_match /third/, out
  end

  test "execute command with default argument" do
    out, error = capture_io do
      Excavator.runner.run("command_with_arg")
    end
    assert_match /west/, out
  end

  test "execute command overriding default argument" do
    out, error = capture_io do
      Excavator.runner.run("command_with_arg", "-r", "east")
    end
    assert_match /east/, out
  end
end

