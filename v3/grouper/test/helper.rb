$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), ".."))

require 'test/unit'

class Test::Unit::TestCase

  def new_message
    path = File.join(File.dirname(__FILE__), "fixtures", "dummy_messages.txt")
    File.open( path ) do |file|
      content = file.read
      @messages = content.split(/\n\n/)
    end

    @messages[rand(@messages.size)].strip
  end

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

  def create_env_with_locations lon, lat, bssids
    options = {
      :gps => {
        :longitude => lon,
        :latitude  => lat,
        :accuracy  => 100,
      },
      :client_uuid => UUID.generate,
      :wifi => { :bssids => bssids, :timestamp => Time.now.to_f }
    }

    Environment.create( options )
  end

end
