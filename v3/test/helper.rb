require 'test/unit'
require 'eventmachine'
require 'sinatra'
require 'sinatra/async'
require "sinatra/async/test"
require 'uuid'
require 'json'
require 'hoccer'

class Test::Unit::TestCase
  include Hoccer

  unless defined?(Spec)
    # test "verify something" do
    #   ...
    # end
    def self.test(name, &block)
      test_name = "test_#{name.gsub(/\s+/,'_')}".to_sym
      defined = instance_method(test_name) rescue false
      raise "#{test_name} is already defined in #{self}" if defined
      if block_given?
        define_method(test_name, &block)
      else
        define_method(test_name) do
          flunk "No implementation provided for #{name}"
        end
      end
    end
  end

  def assert_difference(expression, difference = 1, message = nil, &block)
    b = block.send(:binding)
    exps = Array.wrap(expression)
    before = exps.map { |e| eval(e, b) }

    yield

    exps.each_with_index do |e, i|
      error = "#{e.inspect} didn't change by #{difference}"
      error = "#{message}.\n#{error}" if message
      assert_equal(before[i] + difference, eval(e, b), error)
    end
  end

  def with_events &blk
    EM.run do
      blk.call
      EM.stop
    end
  end

end
