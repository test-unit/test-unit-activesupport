#!/usr/bin/env ruby
#
# Copyright (C) 2015-2022  Kouhei Sutou <kou@clear-code.com>
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

base_dir = File.expand_path(File.join(__dir__, ".."))
lib_dir = File.join(base_dir, "lib")
$LOAD_PATH.unshift(lib_dir)

require "test/unit/active_support"

test_dir = File.join(base_dir, "test")
exit(Test::Unit::AutoRunner.run(true, test_dir))
