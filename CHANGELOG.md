#Change Log
This project adheres to [Semantic Versioning](http://semver.org/).

This CHANGELOG follows the format listed at [Keep A Changelog](http://keepachangelog.com/)

## [Unreleased]
### Added
- check-aggregates.rb: Fixed ability to honor-stashed in Sensu 0.24
- handler-sensu-deregister.rb: Fix undefined variable in case of API error.

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

[Unreleased]: https://github.com/sensu-plugins/sensu-plugins-sensu/compare/1.0.0...HEAD
[1.0.0]: https://github.com/sensu-plugins/sensu-plugins-sensu/compare/0.1.0...1.0.0
[0.1.0]: https://github.com/sensu-plugins/sensu-plugins-sensu/compare/0.0.2...0.1.0
[0.0.2]: https://github.com/sensu-plugins/sensu-plugins-sensu/compare/0.0.1...0.0.2
