# Copyright (C) 2015  Kouhei Sutou <kou@clear-code.com>
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

class TestAssertions < ActiveSupport::TestCase
  test "assert_not" do
    assert_not(false)
  end

  test "assert_difference" do
    x = 1
    assert_difference("x", 1) do
      x += 1
    end
  end

  test "assert_no_difference" do
    x = 1
    assert_no_difference("x") do
    end
  end

  test "message method" do
    delayed_message = message("test", "bernd") do
      "hans"
    end

    assert_equal("test.\nhansbernd", delayed_message.call)
  end
end
