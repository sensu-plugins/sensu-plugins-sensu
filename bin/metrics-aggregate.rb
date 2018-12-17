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
require 'rest-client'
require 'json'

class AggregateMetrics < Sensu::Plugin::Metric::CLI::Generic
  option :api,
         short: '-a URL',
         long: '--api URL',
         description: 'Sensu API URL',
         default: 'http://127.0.0.1:4567'

  option :user,
         short: '-u USER',
         long: '--user USER',
         description: 'Sensu API USER'

  option :password,
         short: '-p PASSOWRD',
         long: '--password PASSWORD',
         description: 'Sensu API PASSWORD'

  option :insecure,
         short: '-k',
         boolean: true,
         description: 'Enabling insecure connections',
         default: false

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
    verify_mode = OpenSSL::SSL::VERIFY_PEER
    verify_mode = OpenSSL::SSL::VERIFY_NONE if config[:insecure]
    request = RestClient::Resource.new(config[:api] + resource, timeout: config[:timeout],
                                                                user: config[:user],
                                                                password: config[:password],
                                                                verify_ssl: verify_mode)
    ::JSON.parse(request.get, symbolize_names: true)
  rescue Errno::ECONNREFUSED
    warning 'Connection refused'
  rescue RestClient::RequestFailed
    warning 'Request failed'
  rescue RestClient::RequestTimeout
    warning 'Connection timed out'
  rescue RestClient::Unauthorized
    warning 'Missing or incorrect Sensu API credentials'
  rescue ::JSON::ParserError
    warning 'Sensu API returned invalid JSON'
  end

  def get_aggregates
    aggregates = api_request('/aggregates')
    puts "Aggregates: #{aggregates.inspect}" if config[:debug]
    aggregates
  end

  def get_aggregate(name)
    aggregate = api_request("/aggregates/#{name}?max_age=#{config[:age]}")
    puts "Aggregate: #{aggregate.inspect}" if config[:debug]
    aggregate
  end

  def counter(aggregate_name, metric_name, metric_value, timestamp)
    output metric_name: metric_name,
           value: metric_value,
           graphite_metric_path: "#{config[:scheme]}.#{aggregate_name}.#{metric_name}",
           statsd_metric_name: "#{config[:scheme]}.#{aggregate_name}.#{metric_name}",
           influxdb_measurement: config[:measurement],
           tags: {
             aggregate: aggregate_name,
             host: Socket.gethostname
           },
           timestamp: timestamp
  end

  def run
    timestamp = Time.now.to_i
    get_aggregates.each do |info|
      aggregate_name = info[:name]
      aggregate = get_aggregate(aggregate_name)
      counter(aggregate_name, 'clients', aggregate[:clients], timestamp)
      counter(aggregate_name, 'checks', aggregate[:checks], timestamp)
      aggregate[:results].each do |metric_name, metric_value|
        counter(aggregate_name, metric_name, metric_value, timestamp)
      end
    end
    ok
  end
end
