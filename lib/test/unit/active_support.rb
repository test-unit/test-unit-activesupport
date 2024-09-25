# Copyright (C) 2012-2024  Sutou Kouhei <kou@clear-code.com>
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

require "test-unit"
require "active_support"
require 'active_support/core_ext/class/attribute'
require "active_support/testing/assertions"
begin
  require 'active_support/testing/file_fixtures'
rescue LoadError
  # Active Support < 5 doesn't have file_fixtures
end
begin
  require "active_support/testing/tagged_logging"
rescue LoadError
  # Active Support < 7 doesn't have tagged_logging
end

as_test_case_name = "active_support/test_case.rb"
unless $LOADED_FEATURES.any? {|feature| feature.end_with?(as_test_case_name)}
  $LOADED_FEATURES.size.times do |i|
    feature = $LOADED_FEATURES[i]
    if feature.end_with?("active_support/testing/assertions.rb")
      as_test_case_feature = feature.gsub(/testing\/assertions.rb\z/,
                                        "test_case.rb")
      $LOADED_FEATURES[i, 0] = as_test_case_feature
      break
    end
  end
end

module ActiveSupport
  if const_defined?(:TestCase)
    remove_const :TestCase
  end

  class TestCase < ::Test::Unit::TestCase
    alias_method :assert_nothing_raised_original, :assert_nothing_raised
    include ActiveSupport::Testing::Assertions
    alias_method :assert_nothing_raised, :assert_nothing_raised_original
    include ActiveSupport::Testing::FileFixtures if defined?(ActiveSupport::Testing::FileFixtures)
    include ActiveSupport::Testing::TaggedLogging if defined?(ActiveSupport::Testing::TaggedLogging)

    # shoulda needs ActiveSupport::TestCase::Assertion, which is not
    # set in test-unit 3
    Assertion = Test::Unit::AssertionFailedError

    setup :before => :prepend
    def before_setup
    end

    teardown :after => :append
    def after_teardown
    end

    # rails 4.1 (action dispatch assertions) needs the 'message'
    # method which is not defined in test-unit 3
    def message(msg=nil, ending=nil, &default)
      lambda do
        msg = msg.call if msg.respond_to?(:call)
        msg = msg.to_s.chomp(".") unless msg.nil?
        if msg.nil? or msg.empty?
          custom_message = ""
        else
          custom_message = "#{msg}.\n"
        end
        ending ||= "."
        "#{custom_message}#{default.call}#{ending}"
      end
    end

    private
    def mu_pp(object)
      AssertionMessage.convert(object)
    end

    if private_method_defined?(:_assert_nothing_raised_or_warn)
      def _assert_nothing_raised_or_warn(assertion, &block)
        assert_nothing_raised(&block)
      rescue Test::Unit::AssertionFailedError => e
        if tagged_logger &&
           tagged_logger.warn? &&
           e.message.start_with?("Exception raised:\n")
          inspected_exception = e.message.lines[1] || "Unknown exception"
          warning = <<-MSG.gsub(/^\s+/, "")
            #{self.class} - #{name}: #{inspected_exception.strip} raised.
            If you expected this exception, use `assert_raise` as near to the code that raises as possible.
            Other block based assertions (e.g. `#{assertion}`) can be used, as long as `assert_raise` is inside their block.
          MSG
          tagged_logger.warn warning
        end

        raise
      end
    end
  end
end
