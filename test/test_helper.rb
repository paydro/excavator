# -*- encoding: utf-8 -*-

require 'pathname'
basedir = Pathname.new(File.dirname(__FILE__)).join("..").expand_path
$LOAD_PATH.unshift(basedir.join("lib").to_s)
require 'excavator'

gem 'minitest'
require 'minitest/spec'
require 'minitest/autorun'
require 'minitest/mock'

require 'ruby-debug'
Debugger.start

module TestHelpers
  def basedir
    Pathname.new(__FILE__).join("..", "..").expand_path
  end
end

# I like #context more than #describe
alias :context :describe

class MiniTest::Spec
  include TestHelpers
  class << self
    # Oh Rails, you have a strangle hold on my conventions ...
    alias :test :it
    alias :setup :before
    alias :teardown :after
  end
end

