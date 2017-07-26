# -*- coding: utf-8 -*-
#
# Copyright (C) 2012-2015  Kouhei Sutou <kou@clear-code.com>
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
    include ActiveSupport::Testing::Assertions
    include ActiveSupport::Testing::FileFixtures if defined?(ActiveSupport::Testing::FileFixtures)

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
  end
end
