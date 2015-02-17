## Sensu-Plugins-sensu

[![Build Status](https://travis-ci.org/sensu-plugins/sensu-plugins-sensu.svg?branch=master)](https://travis-ci.org/sensu-plugins/sensu-plugins-sensu)
[![Gem Version](https://badge.fury.io/rb/sensu-plugins-sensu.svg)](http://badge.fury.io/rb/sensu-plugins-sensu)
[![Code Climate](https://codeclimate.com/github/sensu-plugins/sensu-plugins-sensu/badges/gpa.svg)](https://codeclimate.com/github/sensu-plugins/sensu-plugins-sensu)
[![Test Coverage](https://codeclimate.com/github/sensu-plugins/sensu-plugins-sensu/badges/coverage.svg)](https://codeclimate.com/github/sensu-plugins/sensu-plugins-sensu)
[![Dependency Status](https://gemnasium.com/sensu-plugins/sensu-plugins-sensu.svg)](https://gemnasium.com/sensu-plugins/sensu-plugins-sensu)

## Functionality

## Files
 * bin/check-aggregate
 * bin/metrics-aggregate
 * bin/metrics-delete-expired-stashes
 * bin/handler-sensu

## Usage

## Installation

Add the public key (if you haven’t already) as a trusted certificate

```
gem cert --add <(curl -Ls https://raw.githubusercontent.com/sensu-plugins/sensu-plugins.github.io/master/certs/sensu-plugins.pem)
gem install sensu-plugins-sensu -P MediumSecurity
```

You can also download the key from /certs/ within each repository.

#### Rubygems

`gem install sensu-plugins-sensu`

#### Bundler

Add *sensu-plugins-disk-checks* to your Gemfile and run `bundle install` or `bundle update`

#### Chef

Using the Sensu **sensu_gem** LWRP
```
sensu_gem 'sensu-plugins-sensu' do
  options('--prerelease')
  version '0.0.1'
end
```

Using the Chef **gem_package** resource
```
gem_package 'sensu-plugins-sensu' do
  options('--prerelease')
  version '0.0.1'
end
```

## Notes
