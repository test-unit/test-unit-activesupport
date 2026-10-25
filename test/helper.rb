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

require "test/unit/testresult"

module RunTestCase
  # Runs one test of a test case class defined inside a test, so that
  # the auto runner doesn't collect it.
  def run_test_case(test_case_class, method_name)
    test = test_case_class.new(method_name)
    result = Test::Unit::TestResult.new
    test.run(result) {}
    result
  end
end
