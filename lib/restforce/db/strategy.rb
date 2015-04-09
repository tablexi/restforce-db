module Restforce

  module DB

    # Restforce::DB::Strategy is an abstraction for the available
    # synchronization strategies, and provides a factory method by which to
    # obtain a strategy by name.
    class Strategy

      # Public: Get a Strategy by the requested name.
      #
      # name    - The Symbol or String name of the desired strategy.
      # options - A Hash of options to pass to the strategy's initializer.
      #
      # Returns a Restforce::DB::Strategies instance.
      def self.for(name, options = {})
        class_name = "Restforce::DB::Strategies::#{name.to_s.camelize}"
        class_name.constantize.new(options)
      end

    end

  end

end
