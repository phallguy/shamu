# Shamu

[![Gem Version](https://badge.fury.io/rb/shamu.svg)](http://badge.fury.io/rb/shamu)
[![Code Climate](https://codeclimate.com/github/phallguy/shamu.png)](https://codeclimate.com/github/phallguy/shamu)
[![Test Coverage](https://codeclimate.com/github/phallguy/shamu/badges/coverage.svg)](https://codeclimate.com/github/phallguy/shamu/coverage)
[![Inch CI](https://inch-ci.org/github/phallguy/shamu.svg?branch=master)](https://inch-ci.org/github/phallguy/shamu)
[![Circle CI](https://circleci.com/gh/phallguy/shamu.svg?style=svg)](https://circleci.com/gh/phallguy/shamu)

Have a whale of a good time adding Service Oriented Architecture to your ruby projects.

(Also check out [shog](http://github.com/phallguy/shog) for better rails logs)

# SOA

# Components

- {Shamu::Attributes}
- {Shamu::Entities}
- {Shamu::Services}
- {Shamu::Security}
- {Shamu::Sessions}
- {Shamu::Events}
- {Shamu::Auditing}
- {Shamu::Features}
- {Shamu::Rails}



# Dependency Injection

....
[Scorpion](http://github.com/phallguy/scorpion)

# Using with Rails


## Active Record

Shamu does not come with a hard dependency on ActiveRecord - it should work with
any persistence you've chosen to use in your project. It does come with some
convenience mixins to make it easier to work with AR.


- **{Shamu::Entities::ActiveRecord}** adds convenience methods for working with
  ActiveRecord models as entities.

## Controllers

- {Shamu::Rails::Controller}

# Contributing

See [LABELS](LABELS.md)