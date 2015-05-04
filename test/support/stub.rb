# Extend all objects with `#stub_any_instance`. Implementation taken from:
# https://github.com/codeodor/minitest-stub_any_instance
class Object

  # Public: Stub the specified method for any instance of the passed class
  # within the context of a block.
  #
  # name            - A String or Symbol method name.
  # val_or_callable - The value which the stubbed method should return.
  # block           - A block of code to execute in this context.
  #
  # Returns nothing.
  def self.stub_any_instance(name, val_or_callable)
    new_name = "__minitest_any_instance_stub__#{name}"

    class_eval do
      alias_method new_name, name

      define_method(name) do |*args|
        if val_or_callable.respond_to?(:call)
          instance_exec(*args, &val_or_callable)
        else
          val_or_callable
        end
      end
    end

    yield
  ensure
    class_eval do
      undef_method name
      alias_method name, new_name
      undef_method new_name
    end
  end

end
