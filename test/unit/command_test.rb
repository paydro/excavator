require 'test_helper'
context "Command" do
  include Excavator

  setup do
    Excavator.reset!
    @runner = Excavator.runner
  end

  test "execute a command" do
    cmd = Command.new(@runner, :name => "test", :block => proc { puts "test"})
    out, error = capture_io do
      cmd.execute
    end
    assert_match /test/, out
  end

  test "command arguments available in #params" do
    cmd = Command.new(
      @runner,
      :name => "test",
      :param_definitions => [Param.new(:name)],
      :block => proc { puts params[:name] }
    )
    out, error = capture_io do
      cmd.execute("--name", "hello, world!")
    end
    assert_match /hello, world!/, out
  end

  test "passing in two named parameters" do
    cmd = Command.new(
      @runner,
      :name => "test",
      :param_definitions => [Param.new(:arg1), Param.new(:arg2)],
      :block => proc { puts "#{params[:arg1]}#{params[:arg2]}" }
    )
    out, error = capture_io do
      cmd.execute("--arg1", "1", "--arg2", "2")
    end
    assert_match /12/, out
  end


  test "#execute_with_params runs a command's block" do
    cmd = Command.new(Excavator.runner).tap do |c|
      c.name = "test"
      c.add_param(Param.new(:name))
      c.add_param(Param.new(:server))
      c.block = Proc.new do
        [params[:name], params[:server]]
      end
    end

    results = cmd.execute_with_params :name => "paydro", :server => "web"
    assert_equal ["paydro", "web"], results
  end

  test "#execute_with_params throws error when missing param" do
    cmd = Command.new(Excavator.runner).tap do |c|
      c.name = "test"
      c.add_param(Param.new(:name))
      c.add_param(Param.new(:server))
      c.block = Proc.new do
        [params[:name], params[:server]]
      end
    end

    error = assert_raises MissingParamsError do
      cmd.execute_with_params :name => "paydro"
    end
    assert error.params.include?(:server)
  end
end # Command

