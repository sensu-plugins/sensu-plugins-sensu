#!/usr/bin/env ruby
# frozen_string_literal: false

#
# Aggregate Metrics
#
# Walks the /aggregates API to return metrics for
# the aggregated output states of each check.
#
# sensu.aggregates.some_aggregated_check.clients 1 1380251999
# sensu.aggregates.some_aggregated_check.checks 125 1380251999
# sensu.aggregates.some_aggregated_check.ok 125 1380251999
# sensu.aggregates.some_aggregated_check.warning  0 1380251999
# sensu.aggregates.some_aggregated_check.critical 0 1380251999
# sensu.aggregates.some_aggregated_check.unknown  0 1380251999
# sensu.aggregates.some_aggregated_check.total  125 1380251999
# sensu.aggregates.some_aggregated_check.stale  0 1380251999
# ===
#
# Authors
# ===
# Sean Porter, @portertech
# Nick Stielau, @nstielau
#
# Copyright 2013 Nick Stielau
# Copyright 2012 Sonian, Inc.
#
# Released under the same terms as Sensu (the MIT license); see
# LICENSE for details.

require 'sensu-plugin/metric/cli'
require 'json'
require 'net/http'
require 'net/https'

class AggregateMetrics < Sensu::Plugin::Metric::CLI::Generic
  option :api,
         short: '-a URL',
         long: '--api URL',
         description: 'Sensu API URL',
         default: 'http://localhost:4567'

  option :user,
         short: '-u USER',
         long: '--user USER',
         description: 'Sensu API USER'

  option :password,
         short: '-p PASSOWRD',
         long: '--password PASSWORD',
         description: 'Sensu API PASSWORD'

  option :timeout,
         short: '-t SECONDS',
         long: '--timeout SECONDS',
         description: 'Sensu API connection timeout in SECONDS',
         proc: proc(&:to_i),
         default: 30

  option :age,
         short: '-A SECONDS',
         long: '--age SECONDS',
         description: 'Minimum aggregate age in SECONDS, time since check request issued',
         default: 30,
         proc: proc(&:to_i)

  option :scheme,
         description: 'Metric naming scheme for graphite format',
         long: '--scheme SCHEME',
         default: "#{Socket.gethostname}.sensu.aggregates"

  option :measurement,
         description: 'Measurement for influxdb format',
         long: '--measurement MEASUREMENT',
         default: 'sensu.aggregates'

  option :debug,
         long: '--debug',
         description: 'Verbose output'

  def api_request(resource)
    uri = URI.parse(config[:api])
    http = Net::HTTP.new(uri.host, uri.port)
    if uri.scheme == 'https'
      http.use_ssl = true
    end
    req = Net::HTTP::Get.new(resource)
    r = http.request(req)
    ::JSON.parse(r.body)
  rescue Errno::ECONNREFUSED
    warning 'Connection refused'
  rescue Timeout::Error
    warning 'Connection timed out'
  rescue ::JSON::ParserError
    warning 'Sensu API returned invalid JSON'
  end

  def acquire_checks
    uri = '/aggregates'
    checks = api_request(uri)
    puts "Checks: #{checks.inspect}" if config[:debug]
    checks
  end

  def get_aggregate(check)
    uri = "/aggregates/#{check}"
    issued = api_request(uri + "?max_age=#{config[:age]}")
    if issued.empty?
      warning "No aggregates for #{check}"
    else
      issued
    end
  end

  def run
    timestamp = Time.now.to_i
    acquire_checks.each do |check|
      aggregate = get_aggregate(check['name'])
      puts "#{check['name']} aggregates: #{aggregate}" if config[:debug]
      aggregate.each_value do |count|
        count.each do |x, y|
          output metric_name: x,
                 value: y,
                 graphite_metric_path: "#{config[:scheme]}.#{check['name']}.#{x}",
                 statsd_metric_name: "#{config[:scheme]}.#{check['name']}.#{x}",
                 influxdb_measurement: config[:measurement],
                 tags: {
                   check: check['name'],
                   host: Socket.gethostname
                 },
                 timestamp: timestamp
        end
      end
    end
    ok
  end
end
