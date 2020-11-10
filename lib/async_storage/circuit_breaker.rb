# frizen_string_literal: true

module AsyncStorage
  # This is not a real circuit breaker. We can improve it later.
  # Basicaly only call the fallback function when some known exception is thrown
  #
  # @see https://martinfowler.com/bliki/CircuitBreaker.html
  class CircuitBreaker
    def initialize(context, exceptions: [])
      @context = context
      @exceptions = exceptions || []
    end

    def run(fallback: nil)
      func = fallback.is_a?(Proc) ? fallback : Proc.new { fallback }
      yield
    rescue => err
      if exception?(err)
        func.arity == 0 ? @context.instance_exec(&func) : func.call(@context)
      else
        raise(err)
      end
    end

    private

    def exception?(error)
      AsyncStorage.config.circuit_breaker? && \
        (@exceptions.empty? || @exceptions.any? { |known_error| error.is_a?(known_error) })
    end
  end
end
