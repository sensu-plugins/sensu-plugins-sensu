## Sensu-Plugins-sensu

[![Build Status](https://travis-ci.org/sensu-plugins/sensu-plugins-sensu.svg?branch=master)](https://travis-ci.org/sensu-plugins/sensu-plugins-sensu)
[![Gem Version](https://badge.fury.io/rb/sensu-plugins-sensu.svg)](http://badge.fury.io/rb/sensu-plugins-sensu)
[![Code Climate](https://codeclimate.com/github/sensu-plugins/sensu-plugins-sensu/badges/gpa.svg)](https://codeclimate.com/github/sensu-plugins/sensu-plugins-sensu)
[![Test Coverage](https://codeclimate.com/github/sensu-plugins/sensu-plugins-sensu/badges/coverage.svg)](https://codeclimate.com/github/sensu-plugins/sensu-plugins-sensu)
[![Dependency Status](https://gemnasium.com/sensu-plugins/sensu-plugins-sensu.svg)](https://gemnasium.com/sensu-plugins/sensu-plugins-sensu)

## Functionality

## Files
 * bin/check-aggregate.rb
 * bin/check-aggregate-output.rb
 * bin/check-stale-results.rb
 * bin/metrics-aggregate.rb
 * bin/metrics-delete-expired-stashes.rb
 * bin/metrics-events.rb
 * bin/handler-sensu.rb
 * bin/handler-sensu-deregister.rb
 * bin/handler-purge-stale-results.rb

## Usage

### check-aggregate-output.rb

A sensu plugin to monitor Sensu aggregates. Use it to alert on a number or percent of aggregate results being returned with a critical or warning severity, and get the associated output. The plugin accepts the following command line options:

```
Usage: ./check-aggregate-output.rb (options)
    -A, --age SECONDS                Minimum aggregate age in SECONDS, time since check request issued
    -a, --api URL                    Sensu API URL
    -c, --check CHECK                Aggregate CHECK name (required)
    -o, --output                     Collects all non-ok outputs
    -C, --critical PERCENT           PERCENT critical before critical (can be change with --ignore-severity)
        --critical_count INTEGER     number of node in critical before critical (can be change with --ignore-severity)
        --ignore-severity            Ignore severities, all non-ok will count for critical, critical_count, warning and warning_count option
    -k                               Enabling insecure connections
    -M, --message MESSAGE            A custom error MESSAGE
    -p, --password PASSWORD          Sensu API PASSWORD
    -t, --timeout SECONDS            Sensu API connection timeout in SECONDS
    -u, --user USER                  Sensu API USER
    -W, --warning PERCENT            PERCENT warning before warning (can be change with --ignore-severity)
        --warning_count INTEGER      number of nodes in warning before warning (can be change with --ignore-severity)
```

### check-stale-results.rb

A sensu plugin to monitor sensu stale check results. You can then implement an handler that purges the results after X days using the `handlers-purge-stale-results` handler.

The plugin accepts the following command line options:

```
Usage: check-stale-results.rb (options)
    -c, --crit <COUNT>               Critical if number of stale check results exceeds COUNT
    -s, --stale <TIME>               Elapsed time to consider a check result result (default: 1d)
    -v, --verbose                    Be verbose
    -w, --warn <COUNT>               Warn if number of stale check results exceeds COUNT (default: 1)
```

the --stale command line option accepts elapsed times formatted as documented in https://github.com/hpoydar/chronic_duration.

The handler accepts the following command line options:

### handler-purge-stale-results.rb

A sensu handler to purge stale check results. This handler can be invoked from a check that uses the the `check-stale-results` plugin.

```
Usage: handler-purge-stale-results.rb (options)
        --mail-recipient <ADDRESS>   Mail recipient (required)
        --mail-sender <ADDRESS>      Mail sender (default: sensu@localhost)
        --mail-server <HOST>         Mail server (default: localhost)
    -s, --stale <TIME>               Elapsed time after which a stale check result will be deleted (default: 7d)
```

the --stale command line option accepts elapsed times formatted as documented in https://github.com/hpoydar/chronic_duration.

## Installation

[Installation and Setup](http://sensu-plugins.io/docs/installation_instructions.html)

## Notes
