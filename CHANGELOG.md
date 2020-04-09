# Change Log
This project adheres to [Semantic Versioning](http://semver.org/).

This CHANGELOG follows the format listed at [Our CHANGELOG Guidelines ](https://github.com/sensu-plugins/community/blob/master/HOW_WE_CHANGELOG.md).
Which is based on [Keep A Changelog](http://keepachangelog.com/)

## [Unreleased]

## [5.0.0] - 2020-04-09
### Breaking Changes
- bumped `sensu-plugin` dependency from `~> 2.6` to `~> 4.0` please consult the changelog for additional details. The notable breaking change [is](https://github.com/sensu-plugins/sensu-plugin/blob/master/CHANGELOG.md#v145---2017-03-07)

## [4.3.0] - 2019-07-02
### Changed
- update rest-client to 2.0.2 to fix rest-client issue with 1.8.0 and ruby > 2.4.x

## [4.2.0] - 2018-09-19
### Added
- check-stale-results.rb: added an option to pass read_timeout for http request. (@bkim8815)

## [4.1.0] - 2018-08-28
### Changed
- bumped dependency of `sensu-plugin` to `~> 2.6` to provide paginated HTTP get (@cwjohnston)
- check-stale-results.rb: use paginated HTTP get (@cwjohnston)
- handler-purge-stale-results.rb: use paginated HTTP get (@cwjohnston)

## [4.0.0] - 2018-07-18
### Security
- updated `yard` dependency to `~> 0.9.11` per: https://nvd.nist.gov/vuln/detail/CVE-2017-17042 which closes attacks against a yard server loading arbitrary files (@majormoses)
- updated rubocop dependency to `~> 0.51.0` per: https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2017-8418. (@majormoses)

### Breaking Changes
- removing ruby support for `< 2.3` versions as they are EOL (@majormoses)
- metrics-aggregate.rb: removed support for `sensu` api versions lower than `0.24` you can read about it [here](https://github.com/sensu/sensu/issues/1218) (@majormoses)

### Removed
- gemnasium badge as github offers native feature and they were bought by gitlab and no longer available as a standalone product (@majormoses)

### Added
- slack badge (@majormoses)

### Changed
- check-stale-results.rb: improve error message when there is no api key in sensu settings (@majormoses)
- bumped dependency of `sensu-plugin` to `~> 2.5`  (@majormoses)
- appeasing the cops (@majormoses)

## [3.0.0] - 2018-05-17
### Breaking Change
- bumped dependency of `sensu-plugin` to 2.x you can read about it [here](https://github.com/sensu-plugins/sensu-plugin/blob/master/CHANGELOG.md#v200---2017-03-29)

### Changed
- `bin/metrics-*`: Used `Sensu::Plugin::Metric::CLI::Generic` class instead of Graphite specific class for metrics. (@bergerx)

## [2.5.0] - 2018-03-06
### Changed
- check-stale-results.rb: support https protocol via api/host declaration

## [2.4.1] - 2018-01-23
### Fixed
- Removed brackets that were added around `subscribers` in the `trigger_remediation` method in #15. This resulted in a successful submission with an HTTP 202, however as this resulted in the subscribers key being an array of arrays which meant that the remediation never was actually scheduled. This fixes it by doing a couple of things, first we remove the extra brackets therefore solving the problem. That being said I decided to add some additional validation of the data to ensure that minimally what is being passed in is an array and the first element is a string, if that is not the case we either error out when unable to determine a fix with a helpful message or in the case of nested arrays attempt to flatten them. (@drhey) (@majormoses)

### Changed
- updated changelog guidelines location (@majormoses)

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

[Unreleased]: https://github.com/sensu-plugins/sensu-plugins-sensu/compare/5.0.0...HEAD
[5.0.0]: https://github.com/sensu-plugins/sensu-plugins-sensu/compare/4.3.0...5.0.0
[4.3.0]: https://github.com/sensu-plugins/sensu-plugins-sensu/compare/4.2.0...4.3.0
[4.2.0]: https://github.com/sensu-plugins/sensu-plugins-sensu/compare/4.1.0...4.2.0
[4.1.0]: https://github.com/sensu-plugins/sensu-plugins-sensu/compare/4.0.0...4.1.0
[4.0.0]: https://github.com/sensu-plugins/sensu-plugins-sensu/compare/3.0.0...4.0.0
[3.0.0]: https://github.com/sensu-plugins/sensu-plugins-sensu/compare/2.5.0...3.0.0
[2.5.0]: https://github.com/sensu-plugins/sensu-plugins-sensu/compare/2.4.1...2.5.0
[2.4.1]: https://github.com/sensu-plugins/sensu-plugins-sensu/compare/2.4.0...2.4.1
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
