# -*- coding: utf-8 -*-
#
# Copyright (C) 2012  Kouhei Sutou <kou@clear-code.com>
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

require "test/unit/active_support/version"

require "test-unit"
require "active_support/testing/setup_and_teardown"

module ActiveSupport::Testing::SetupAndTeardown
  if const_defined?(:ClassMethods)
    module ClassMethods
      remove_method :setup
      remove_method :teardown
    end
  end

  if const_defined?(:ForClassicTestUnit)
    module ForClassicTestUnit
      remove_method :run
    end
  end
end

unless ActiveSupport::Testing::SetupAndTeardown.const_defined?(:ForClassicTestUnit)
  module MiniTest
    Assertion = Test::Unit::Assertions
  end
end

require 'active_support/test_case'

class Test::Unit::Error
  if method_defined?(:message_without_silenced_deprecation)
    undef_method :message
    alias_method :message, :message_without_silenced_deprecation
  end
end

class ActiveSupport::TestCase
  def valid?
    return false if @method_name == "default_test"
    super
  end
end

class Test::Unit::TestCase
  # REMOVE ME after https://github.com/freerange/mocha/pull/89 is merged.
  if method_defined?(:run_before_mocha) and not method_defined?(:cleanup_mocha)
    alias_method :run, :run_before_mocha
    remove_method :run_before_mocha

    exception_handler(:handle_mocha_expectation_error)

    cleanup :cleanup_mocha, :after => :append
    teardown :teardown_mocha, :after => :append

    private
    def cleanup_mocha
      assertion_counter = Mocha::Integration::TestUnit::AssertionCounter.new(current_result)
      mocha_verify(assertion_counter)
    end

    def teardown_mocha
      mocha_teardown
    end

    def handle_mocha_expectation_error(exception)
      return false unless exception.is_a?(Mocha::ExpectationError)
      problem_occurred
      add_failure(exception.message, exception.backtrace)
      true
    end
  end
end
