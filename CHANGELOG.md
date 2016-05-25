#Change Log
This project adheres to [Semantic Versioning](http://semver.org/).

This CHANGELOG follows the format listed at [Keep A Changelog](http://keepachangelog.com/)

## [Unreleased]
- check-aggregates.rb adding misconfiguration check to 
- check-aggregates.rb If summarize is set and the threshold output is being used the alert will be the summarized results
- check-aggregates.rb Added new flag to honor stashed checks. If -i is supplied and the threshold alert is being used it will remove any checks that are stashed
- check-aggregates.rb Adding -k for https insecure mode
- check-aggregates.rb Added config option to use environment var SENSU_API=hostname or SENSU_API_URL=hostname:port for -a 
- check-aggregates.rb Added ability to use node down count instead of percentages

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

[Unreleased]: https://github.com/sensu-plugins/sensu-plugins-sensu/compare/0.1.0...HEAD
[0.1.0]: https://github.com/sensu-plugins/sensu-plugins-sensu/compare/0.0.2...0.1.0
[0.0.2]: https://github.com/sensu-plugins/sensu-plugins-sensu/compare/0.0.1...0.0.2
