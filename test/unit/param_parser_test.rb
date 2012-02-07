require 'test_helper'

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
    -s, --server-id=SERVER_ID        Server instance id

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
