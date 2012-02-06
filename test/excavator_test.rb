require 'test_helper'

# Command runner tests ########################################################

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

context "ParamParser" do
  include Excavator

  setup do
    @parser = ParamParser.new
    @parser.name = "test-command"
  end

  test "parses params into a hash using long switches" do
    @parser.build(
      :params => [ Param.new(:region), Param.new(:size) ]
    )

    hash = @parser.parse!(["--region", "us-east-1", "--size", "large"])
    assert_equal({:region => "us-east-1", :size => "large"}, hash)
  end

  test "automatically assigns short switches via param name's first char" do
    param = Param.new(:region)
    @parser.build(:params => [param])
    hash = @parser.parse!(["-r", "us-east-1"])
    assert_equal({:region => "us-east-1"}, hash)
  end

  test "automatically detects short switch collisions" do
    param1 = Param.new(:region)
    param2 = Param.new(:rate)
    @parser.build(:params => [param1, param2])

    hash = @parser.parse!(["-r", "region", "-a", "rate"])
    assert_equal({:region => "region", :rate => "rate"}, hash)
  end

  test "use given short switch if specified" do
    param = Param.new(:region, :short => "n")
    @parser.build(:params => [param])
    hash = @parser.parse!(["-n", "us-east-1"])
    assert_equal({:region => "us-east-1"}, hash)
  end

  test "no switch is given if all possible switches are used" do
    param1 = Param.new(:abc)
    param2 = Param.new(:bcd)
    param3 = Param.new(:aabb) # No switch available
    @parser.build(:params => [param1, param2, param3])

    assert_nil param3.short
  end

  test "sets up defaults" do
    param = Param.new(:region, :default => "us-east-1")
    @parser.build(:params => [param])
    hash = @parser.parse!([])
    assert_equal({:region => "us-east-1"}, hash)
  end

  test "params can be optional" do
    param = Param.new(:region, :optional => true)
    @parser.build(:params => [param])
    hash = @parser.parse!([])
    assert_equal({}, hash)
  end

  test "pass parsed params in" do
    param1 = Param.new(:region)
    param2 = Param.new(:server)
    @parser.build(:params => [param1, param2])
    hash = @parser.parse!([{:region => 'us-west', :server => '111'}])

    assert_equal({:region => 'us-west', :server => '111'}, hash)
  end

  test "#usage" do
    required_param = Param.new(
      :server_id, :desc => "Server instance id"
    )
    param_with_default = Param.new(
      :image, :desc => "Image to use", :default => "ami-test"
    )
    optional_param = Param.new(
      :region, :optional => true, :desc => "A region to use"
    )
    @parser.build(
      :params => [ optional_param, required_param, param_with_default ],
      :name => "test-command",
      :desc => "test description"
    )

    assert_equal <<-USAGE, @parser.usage
test description

USAGE: test-command [options]

REQUIRED:
    -s, --server_id=SERVER_ID        Server instance id

OPTIONAL:
    -r, --region=REGION              A region to use
    -i, --image=IMAGE                Image to use
                                     Defaults to: ami-test

    -h, --help                       This message.
    USAGE
  end

  test "raises error when required params are missing" do
    param = Param.new(:region)
    @parser.build(:params => [param])

    assert_raises MissingParamsError do
      @parser.parse!([])
    end
  end

  test "MissingParam error has all the missing attributes" do
    param1 = Param.new(:arg1)
    param2 = Param.new(:arg2)
    @parser.build(:params => [param1, param2])

    exception = assert_raises MissingParamsError do
      @parser.parse!([])
    end

    assert_equal [:arg1, :arg2], exception.params
  end
end

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
      c.add_param :name
      c.add_param :server
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
      c.add_param :name
      c.add_param :server
      c.block = Proc.new do
        [params[:name], params[:server]]
      end
    end

    error = assert_raises MissingParamsError do
      cmd.execute_with_params :name => "paydro"
    end
    assert error.params.include?(:server)
  end
end

context "Command::Env" do
  include Excavator::DSL

  setup do
    Excavator.reset!
    Excavator.runner.tap do |r|
      # r.config_path = r.basedir.join("test", "fixtures", "bulldozer.yml")
      r.command_paths = [r.basedir.join("test", "fixtures", "commands")]
    end
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
end

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
      Excavator.runner.basedir.join("test", "fixtures", "commands")
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

context "TableView" do
  include Excavator

  test "prints table title" do
    table_view = TableView.new do |t|
      t.title "Table View"
    end

    out, error = capture_io { puts table_view }
    assert_match /^Table View$/, out
  end

  test "prints out headers" do
    table_view = TableView.new do |t|
      t.header "header1"
      t.header "header2"
    end

    out, error = capture_io do
      puts table_view
    end

    assert_match /^header1 \| header2$/, out
  end

  test "prints data aligned to headers" do
    table_view = TableView.new do |t|
      t.header :name
      t.header :url

      t.record "Google", "http://www.google.com"
    end

    out, error = capture_io { puts table_view }
    lines = out.split("\n")

    assert_match /^name\s\s \| url\s{18}$/, lines[0]
    assert_match %r{Google \| http://www\.google\.com}, lines[1]
  end

  test "changing divider" do
    table_view = TableView.new do |t|
      t.header :name
      t.header :url
      t.divider "\t"
    end

    out, error = capture_io { puts table_view }
    assert_match /^name\turl$/, out
  end

  test "complains when adding a record with not enough values" do
    assert_raises TableView::InvalidDataForHeaders do
      table_view = TableView.new do |t|
        t.header :name
        t.record 1, 2
      end
    end
  end
end


