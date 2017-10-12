# Change Log
This project adheres to [Semantic Versioning](http://semver.org/).

This CHANGELOG follows the format listed at [Our CHANGELOG Guidelines ](https://github.com/sensu-plugins/community/blob/master/HOW_WE_CHANGELOG.md).
Which is based on [Keep A Changelog](http://keepachangelog.com/)

## [Unreleased]

## [2.4.0] - 2017-10-12
### Added
- `--debug` Option to display results hash at end of output message.
### Changed
- Previously the results hash were always displayed before the message, now they are displayed at the end of the message and only if the `--debug` option is used.

## [2.3.1] - 2017-10-06
### Changed
- check-stale-results.rb: update the require order for json so that it comes after sensu_plugin (@barryorourke)
- handler-purge-stale-results.rb: fix invalid hash syntax resulting in NameError (@cwjohnston)

## [2.3.0] - 2017-10-03
### Changed
- handler-sensu.rb: more log info, with creator and reason included in json. Check name information (REMEDIATION:) at sensu server logs. Tested on sensu > 0.29. (@betorvs)

## [2.2.2] - 2017-09-26
### Changed
- handler-sensu.rb: In sensu version [0.26](https://github.com/sensu/sensu/blob/v1.0.0/CHANGELOG.md#features-4) clients create and subscribes to a unique client subscription named after it. Adding new internal sensu client name in addition to old defaults keeping backwards compatibility. (@Ssawa)

## [2.2.1] - 2017-09-25
### Fixed
- check-stale-results.rb: Removed broken and unnecessary block argument that stopped the plugin from running (@portertech)

## [2.2.0] - 2017-09-16
### Changed
- check-aggregates.rb: Add options `--stale-percentage` and `--stale-count` to warn on stale data (@rbanffy)

## [2.1.1] - 2017-00-09
### Fixed
- metrics-aggregates.rb: Refactored to support new named aggregates introduced in Sensu 0.24 (@oba11)

### Changed
- check-stale-results.rb: made invocation of ok more idiomatic (@rbanffy)
- updated the location for our changelog guidelines (@majormoses)

## [2.1.0] - 2017-08-29
### Added
- check-stale-results.rb: new script to check for stale results in sensu (@m4ce)
- handler-purge-stale-results.rb: new handler to purge stale results from sensu (@m4ce)

## [2.0.0] - 2017-08-20
### Breaking Changes
- check-aggregates.rb: Changed the default behavior to alert with the severity of the aggregated checks. (@Moozaliny)

### AddedMoozaliny
- check-aggregates.rb: Added new flag to ignore severities. If --ignore-severity is supplied all non-ok will count for critical, critical_count, warning and warning_count option.

### Fixed
- handler-sensu-deregister.rb: Fix undefined variable in case of API error.

## [1.1.1] - 2017-08-01
### Added
- Ruby 2.4 testing (@Evesy)

### Fixed
- bin/check-aggregate.rb: Fix acquire_aggregate to make it work with sensu-server 1.x.x (@nishiki)

## [1.1.0] - 2017-06-25
### Added
- Add support for client invalidation on deregister handler (@Evesy)

### Fixed
- handler-sensu-deregister.rb: Fix undefined variable in case of API error. (@cyrilgdn)

## [1.0.0] - 2016-07-13
### Added
- metrics-events.rb: new plugin to track number of warnings/critical overtime
- check-aggregates.rb: Added support for new named aggregates introduced in Sensu 0.24
- check-aggregates.rb: Added misconfiguration check to guard against returning 'ok' status when provided parameters are insufficient
- check-aggregates.rb: Added new flag to honor stashed checks. If -i is supplied and the threshold alert is being used it will remove any checks that are stashed
- check-aggregates.rb: Added -k for https insecure mode
- check-aggregates.rb: Added config option to use environment var SENSU_API=hostname or SENSU_API_URL=hostname:port for -a
- check-aggregates.rb: Added ability to use node down count instead of percentages

### Changed
- check-aggregates.rb: If summarize is set and the threshold output is being used the alert will contain the summarized results
- handler-sensu-deregister.rb: Overrode sensu-plugin's default `filter` method to make it a noop; deregistration events are one-time and shouldn't be filtered

### Removed
- Remove Ruby 1.9.3 support; add Ruby 2.3.0 support

## [0.1.0] - 2016-01-08
### Added
- added sensu-deregister handler for deregistering a sensu client upon request (see https://github.com/sensu/sensu-build/pull/148 for example).

### Changed
- rubocop cleanup

## [0.0.2] - 2015-07-14
### Changed
- updated sensu-plugin gem to 1.2.0

### Removed
- Remove JSON gem dep that is not longer needed with Ruby 1.9+

## 0.0.1 - 2015-06-04
### Added
- initial release

[Unreleased]: https://github.com/sensu-plugins/sensu-plugins-sensu/compare/2.3.1...HEAD
[2.4.0]: https://github.com/sensu-plugins/sensu-plugins-sensu/compare/2.3.1...2.4.0
[2.3.1]: https://github.com/sensu-plugins/sensu-plugins-sensu/compare/2.3.0...2.3.1
[2.3.0]: https://github.com/sensu-plugins/sensu-plugins-sensu/compare/2.2.2...2.3.0
[2.2.2]: https://github.com/sensu-plugins/sensu-plugins-sensu/compare/2.2.1...2.2.2
[2.2.1]: https://github.com/sensu-plugins/sensu-plugins-sensu/compare/2.2.0...2.2.1
[2.2.0]: https://github.com/sensu-plugins/sensu-plugins-sensu/compare/2.1.0...2.2.0
[2.1.1]: https://github.com/sensu-plugins/sensu-plugins-sensu/compare/2.1.0...2.1.1
[2.1.0]: https://github.com/sensu-plugins/sensu-plugins-sensu/compare/2.0.0...2.1.0
[2.0.0]: https://github.com/sensu-plugins/sensu-plugins-sensu/compare/1.1.1...2.0.0
[1.1.1]: https://github.com/sensu-plugins/sensu-plugins-sensu/compare/1.1.0...1.1.1
[1.1.0]: https://github.com/sensu-plugins/sensu-plugins-sensu/compare/1.0.0...1.1.0
[1.0.0]: https://github.com/sensu-plugins/sensu-plugins-sensu/compare/0.1.0...1.0.0
[0.1.0]: https://github.com/sensu-plugins/sensu-plugins-sensu/compare/0.0.2...0.1.0
[0.0.2]: https://github.com/sensu-plugins/sensu-plugins-sensu/compare/0.0.1...0.0.2
