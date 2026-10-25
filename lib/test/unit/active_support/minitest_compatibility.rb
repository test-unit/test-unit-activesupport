# Copyright (C) 2012-2026  Sutou Kouhei <kou@clear-code.com>
# Copyright (C) 2026  Akira Matsuda <ronnie@dio.jp>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

require "monitor"
require "stringio"
require "test/unit"
begin
  require "minitest/mock"
rescue LoadError
  # Minitest::Mock comes with minitest 5 or the minitest-mock gem.
end

module Test
  module Unit
    module ActiveSupport
      # The Minitest-shaped surface that Rails' test helpers call on a
      # test case: the per-test assertion counter, the list of failures,
      # +skip+, +capture_io+ and friends. Including it into a
      # Test::Unit::TestCase subclass lets Active Support's testing
      # mixins run unchanged on Test::Unit.
      #
      # Only Minitest's vocabulary is mirrored here. The lifecycle roots
      # (+before_setup+ and +after_teardown+) are registered on
      # ActiveSupport::TestCase because they need Test::Unit's fixture
      # DSL on the class.
      module MinitestCompatibility
        # The counterpart of Minitest::UnexpectedError: an exception
        # raised inside a test, wrapped so that it can travel through
        # +failures+. Test::Unit reports it as an error of the wrapped
        # exception, not as a failure.
        class UnexpectedError < StandardError
          attr_reader :error

          def initialize(error)
            @error = error
            super("Unexpected exception")
          end

          def backtrace
            @error.backtrace
          end

          def message
            backtrace = self.backtrace || []
            if ::Test::Unit::Util::BacktraceFilter.respond_to?(:filter_backtrace)
              backtrace = ::Test::Unit::Util::BacktraceFilter.filter_backtrace(backtrace)
            end
            "#{@error.class}: #{@error.message}\n    #{backtrace.join("\n    ")}"
          end
        end

        CAPTURE_IO_MONITOR = Monitor.new

        # The number of assertions this test has made so far, like
        # Minitest::Test#assertions. Test::Unit counts assertions per
        # run; this keeps a per-test count next to it.
        def assertions
          @__assertions ||= 0
        end

        # Rails' assertions do +self.assertions += 1+ when they verify
        # something without calling an assertion method. Each added
        # assertion is also reported to Test::Unit.
        def assertions=(count)
          delta = count - assertions
          if delta > 0
            delta.times { add_assertion }
          else
            @__assertions = count
          end
        end

        # The failures recorded for this test so far, like
        # Minitest::Test#failures: assertion failures, omissions and
        # pendings as raised, and other exceptions wrapped in
        # {UnexpectedError}.
        def failures
          @__failures ||= []
        end

        # The first failure, like Minitest::Test#failure.
        def failure
          failures.first
        end

        # Whether this test has been omitted or pended, which is what
        # Minitest calls skipped.
        def skipped?
          failures.any? do |failure|
            failure.is_a?(OmittedError) or failure.is_a?(PendedError)
          end
        end

        # Whether an unexpected exception has been raised in this test.
        def error?
          failures.any? {|failure| failure.is_a?(UnexpectedError)}
        end

        # Minitest's +skip+: omits the rest of the test.
        def skip(message=nil, _ignored=nil)
          omit(message)
        end

        # Captures $stdout and $stderr while the block runs and returns
        # them as two strings, like Minitest::Assertions#capture_io.
        def capture_io
          CAPTURE_IO_MONITOR.synchronize do
            captured_stdout = StringIO.new
            captured_stderr = StringIO.new
            original_stdout = $stdout
            original_stderr = $stderr
            begin
              $stdout = captured_stdout
              $stderr = captured_stderr
              yield
              [captured_stdout.string, captured_stderr.string]
            ensure
              $stdout = original_stdout
              $stderr = original_stderr
            end
          end
        end

        # Asserts what the block writes to $stdout and $stderr, like
        # Minitest::Assertions#assert_output. A String must match
        # exactly, a Regexp must match somewhere and +nil+ accepts
        # anything.
        def assert_output(stdout=nil, stderr=nil)
          unless block_given?
            flunk("assert_output requires a block to capture output.")
          end
          out, err = capture_io do
            yield
          end
          assert_captured_output(stderr, err, "In stderr") if stderr
          assert_captured_output(stdout, out, "In stdout") if stdout
          true
        end

        if defined?(::MockExpectationError)
          # Verifies a Minitest::Mock, like Minitest::Assertions#assert_mock.
          def assert_mock(mock)
            assert(mock.verify)
          rescue ::MockExpectationError => error
            flunk(error.message)
          end
        end

        private
        def add_assertion
          @__assertions = assertions + 1
          super
        end

        def assert_captured_output(expected, actual, message)
          if expected.is_a?(Regexp)
            assert_match(expected, actual, message)
          else
            assert_equal(expected, actual, message)
          end
        end

        # Records what Test::Unit handles into +failures+, and reports a
        # raised {UnexpectedError} as an error of the wrapped exception.
        def handle_exception(exception)
          if exception.is_a?(UnexpectedError)
            problem_occurred
            add_error(exception.error)
            handled = true
          else
            handled = super
          end
          record_failure(exception) if handled
          handled
        end

        def record_failure(exception)
          case exception
          when AssertionFailedError, OmittedError, PendedError, UnexpectedError
            failures << exception
          when NotifiedError
            # notify() isn't a failure
          else
            failures << UnexpectedError.new(exception)
          end
        end
      end
    end
  end
end
