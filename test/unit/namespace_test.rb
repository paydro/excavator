require 'test_helper'

context "Namespace" do
  include Excavator

  setup do
    @namespace = Namespace.new
  end

  test "add command to namespace" do
    cmd = MiniTest::Mock.new
    cmd.expect(:name, :cmd)
    @namespace << cmd
    assert_equal cmd.object_id, @namespace.command(:cmd).object_id
  end

  test "add namespace to namespace" do
    ns = Namespace.new("child")
    @namespace << ns
    assert_equal ns, @namespace.namespace(:child)
  end

  test "add namespace to namespace creates a connection" do
    ns = Namespace.new("child")
    @namespace << ns
    assert_equal ns.parent, @namespace
  end

  test "#fullname" do
    assert_equal "", @namespace.full_name

    ns1 = Namespace.new("first")
    @namespace << ns1
    assert_equal "first", ns1.full_name

    ns2 = Namespace.new("second")
    ns1 << ns2
    assert_equal "first:second", ns2.full_name
  end

  test "#commands_and_descriptions returns names and description" do
    cmd = MiniTest::Mock.new
    cmd.expect(:name, "command")
    cmd.expect(:desc, "command description")
    @namespace << cmd

    ns1 = Namespace.new("first")
    @namespace << ns1

    inner_cmd = MiniTest::Mock.new
    inner_cmd.expect(:name, "inner_command")
    inner_cmd.expect(:desc, "inner command description")
    ns1 << inner_cmd

    expected = [
      ["command", "command description"],
      ["first:inner_command", "inner command description"]
    ]
    assert_equal expected, @namespace.commands_and_descriptions
  end
end
