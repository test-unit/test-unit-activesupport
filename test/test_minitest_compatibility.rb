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

require_relative "helper"
begin
  require "active_support/testing/method_call_assertions"
rescue LoadError
end

class TestMinitestCompatibility < ActiveSupport::TestCase
  include RunTestCase
  if defined?(ActiveSupport::Testing::MethodCallAssertions)
    include ActiveSupport::Testing::MethodCallAssertions
  end

  # Runs a test and returns what the test saw about itself in
  # after_teardown, when its failures are still recorded.
  def observe(&test_body)
    observed = {}
    test_case_class = Class.new(ActiveSupport::TestCase) do
      define_method(:after_teardown) do
        super()
        observed[:assertions] = assertions
        observed[:failures] = failures.dup
        observed[:failure] = failure
        observed[:skipped] = skipped?
        observed[:error] = error?
        observed[:passed] = passed?
      end
      define_method(:test_it, &test_body)
    end
    observed[:result] = run_test_case(test_case_class, "test_it")
    observed
  end

  test "assertions counts this test's assertions" do
    before = assertions
    assert(true)
    assert_equal(before + 1, assertions)
  end

  test "assertions= adds the difference as assertions" do
    result_before = send(:current_result).assertion_count
    before = assertions
    self.assertions += 2
    assert_equal(before + 2, assertions)
    assert_equal(result_before + 2 + 1, send(:current_result).assertion_count)
  end

  test "a passing test" do
    observed = observe do
      assert_equal(1, 1)
      assert_equal(2, 2)
    end
    assert_equal(2, observed[:assertions])
    assert_equal([], observed[:failures])
    assert_nil(observed[:failure])
    assert_equal(false, observed[:skipped])
    assert_equal(false, observed[:error])
    assert_equal(true, observed[:passed])
  end

  test "skip omits the test" do
    observed = observe do
      skip("later")
      flunk("not reached")
    end
    assert_equal(1, observed[:result].omission_count)
    assert_equal(true, observed[:skipped])
    assert_equal(false, observed[:error])
    assert_equal(true, observed[:passed])
    assert_kind_of(Test::Unit::OmittedError, observed[:failure])
    assert_equal("later", observed[:failure].message)
  end

  test "skip without a message" do
    observed = observe do
      skip
    end
    assert_equal(1, observed[:result].omission_count)
    assert_equal(true, observed[:skipped])
  end

  test "pend counts as skipped" do
    observed = observe do
      pend("later")
    end
    assert_equal(1, observed[:result].pending_count)
    assert_equal(true, observed[:skipped])
  end

  test "a failed assertion" do
    observed = observe do
      assert_equal(1, 2)
    end
    assert_equal(1, observed[:result].failure_count)
    assert_kind_of(Test::Unit::AssertionFailedError, observed[:failure])
    assert_equal([observed[:failure]], observed[:failures])
    assert_equal(false, observed[:skipped])
    assert_equal(false, observed[:error])
    assert_equal(false, observed[:passed])
  end

  test "an unexpected exception" do
    observed = observe do
      raise "boom"
    end
    assert_equal(1, observed[:result].error_count)
    assert_kind_of(ActiveSupport::TestCase::UnexpectedError, observed[:failure])
    assert_kind_of(RuntimeError, observed[:failure].error)
    assert_match(/\ARuntimeError: boom\n    /, observed[:failure].message)
    assert_equal(true, observed[:error])
    assert_equal(false, observed[:skipped])
    assert_equal(false, observed[:passed])
  end

  test "raising UnexpectedError reports the wrapped exception as an error" do
    observed = observe do
      raise ActiveSupport::TestCase::UnexpectedError.new(ArgumentError.new("wrapped"))
    end
    assert_equal(1, observed[:result].error_count)
    assert_kind_of(ArgumentError, observed[:result].errors.first.exception)
    assert_equal("wrapped", observed[:result].errors.first.exception.message)
    assert_equal(true, observed[:error])
    assert_kind_of(ActiveSupport::TestCase::UnexpectedError, observed[:failure])
  end

  test "an exception in teardown is a failure too" do
    observed = {}
    test_case_class = Class.new(ActiveSupport::TestCase) do
      def teardown
        raise "in teardown"
      end
      define_method(:after_teardown) do
        super()
        observed[:error] = error?
      end
      def test_it
      end
    end
    run_test_case(test_case_class, "test_it")
    assert_equal(true, observed[:error])
  end

  test "Assertion and UnexpectedError" do
    assert_equal(Test::Unit::AssertionFailedError, ActiveSupport::TestCase::Assertion)
    assert_equal(Test::Unit::ActiveSupport::MinitestCompatibility::UnexpectedError,
                 ActiveSupport::TestCase::UnexpectedError)
  end

  test "capture_io" do
    out, err = capture_io do
      puts("to stdout")
      $stderr.print("to stderr")
    end
    assert_equal(["to stdout\n", "to stderr"], [out, err])
  end

  test "capture_io can be nested" do
    outer, _ = capture_io do
      inner, _ = capture_io do
        print("inner")
      end
      print("outer #{inner}")
    end
    assert_equal("outer inner", outer)
  end

  test "capture_io restores the streams after an exception" do
    stdout = $stdout
    assert_raise(RuntimeError) do
      capture_io do
        raise "boom"
      end
    end
    assert_same(stdout, $stdout)
  end

  test "assert_output" do
    assert_output("out\n", /err/) do
      puts("out")
      $stderr.puts("stderr")
    end
    assert_output(nil, "") do
      print("anything on stdout")
    end
    assert_raise(Test::Unit::AssertionFailedError) do
      assert_output("expected") do
        print("actual")
      end
    end
    assert_raise(Test::Unit::AssertionFailedError) do
      assert_output(nil, /missing/) do
      end
    end
    assert_raise(Test::Unit::AssertionFailedError) do
      assert_output("needs a block")
    end
  end

  test "assert_mock" do
    omit("no Minitest::Mock") unless defined?(Minitest::Mock)

    mock = Minitest::Mock.new
    mock.expect(:call, 1)
    mock.call
    assert_mock(mock)

    unmet = Minitest::Mock.new
    unmet.expect(:call, 1)
    error = assert_raise(Test::Unit::AssertionFailedError) do
      assert_mock(unmet)
    end
    assert_match(/call/, error.message)
  end

  test "stub from minitest-mock" do
    omit("no Minitest::Mock") unless defined?(Minitest::Mock)

    object = Object.new
    object.stub(:to_s, "stubbed") do
      assert_equal("stubbed", object.to_s)
    end
    assert_not_equal("stubbed", object.to_s)
  end

  test "Active Support's method call assertions" do
    omit("no MethodCallAssertions") unless defined?(ActiveSupport::Testing::MethodCallAssertions)

    object = Object.new
    assert_called(object, :to_s, returns: "called") do
      assert_equal("called", object.to_s)
    end
    assert_called_with(object, :to_s, [], returns: "called") do
      object.to_s
    end
    assert_not_called(object, :to_s) do
    end
  end
end
