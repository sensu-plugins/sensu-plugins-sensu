#!/usr/bin/env ruby
# frozen_string_literal: false

#
# Event Metrics
#
# Use the /events API to collect events and their severity.
#
# sensu.events.total 156 1518300288
# sensu.events.warning 6 1518300288
# sensu.events.critical 64 1518300288
# sensu.events.status.3 79 1518300288
# sensu.events.status.127 7 1518300288
#
# ===
#
# Authors
# ===
# Bertrand Roussel, @CoRfr
#
# Copyright 2016 Sierra Wireless, Inc.
#
# Released under the same terms as Sensu (the MIT license); see
# LICENSE for details.

require 'sensu-plugin/metric/cli'
require 'rest-client'
require 'json'

class EventMetrics < Sensu::Plugin::Metric::CLI::Generic
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

  option :scheme,
         description: 'Metric naming scheme',
         long: '--scheme SCHEME',
         default: "#{Socket.gethostname}.sensu.events"

  option :measurement,
         description: 'Measurement for influxdb format',
         long: '--measurement MEASUREMENT',
         default: 'sensu.events'

  option :debug,
         long: '--debug',
         description: 'Verbose output'

  def api_request(resource)
    request = RestClient::Resource.new(config[:api] + resource, timeout: config[:timeout],
                                                                user: config[:user],
                                                                password: config[:password])
    ::JSON.parse(request.get, symbolize_names: true)
  rescue RestClient::ResourceNotFound
    warning "Resource not found: #{resource}"
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

  def acquire_events
    uri = '/events'
    checks = api_request(uri)
    puts "Events: #{checks.inspect}" if config[:debug]
    checks
  end

  def run
    timestamp = Time.now.to_i

    status_count = {}
    status_count[1] = 0
    status_count[2] = 0

    status_names = {}
    status_names[1] = 'warning'
    status_names[2] = 'critical'

    total_count = 0
    acquire_events.each do |event|
      total_count += 1
      status_count[event[:check][:status]] ||= 0
      status_count[event[:check][:status]] += 1
    end

    output metric_name: 'total_events_count',
           value: total_count,
           graphite_metric_path: "#{config[:scheme]}.total",
           statsd_metric_name: "#{config[:scheme]}.total",
           influxdb_measurement: config[:measurement],
           tags: {
             host: Socket.gethostname
           },
           timestamp: timestamp

    status_count.each do |status, count|
      name = status_names[status] || "status.#{status}"
      output metric_name: 'event_count',
             value: count,
             graphite_metric_path: "#{config[:scheme]}.#{name}",
             statsd_metric_name: "#{config[:scheme]}.#{name}",
             influxdb_measurement: config[:measurement],
             tags: {
               host: Socket.gethostname,
               event_status: name
             },
             timestamp: timestamp
    end

    ok
  end
end
