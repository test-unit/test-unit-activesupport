# test-unit-activesupport

[![](https://travis-ci.org/test-unit/test-unit-activesupport.svg?branch=master)](https://travis-ci.org/test-unit/test-unit-activesupport)

[Web site](https://test-unit.github.io/#test-unit-activesupport)

## Description

test-unit-activesupport is an ActiveSupport adapter for test-unit 3. You can use full test-unit 3 features with `ActiveSupport::TestCase`.

## Install

Require `test/unit/active_support`:

```ruby
require "test/unit/active_support"
require "active_support"
```

Now you can use full test-unit 3.x features with ActiveSupport.

```ruby

class YourTest < ActiveSupport::TestCase
  # ...
end
```

## License

LGPLv2.1 or later.

(Kouhei Sutou has a right to change the license including contributed patches.)

## Authors

* Kouhei Sutou
* Haruka Yoshihara

## Thanks

* Michael Grosser
* Shinta Koyanagi
