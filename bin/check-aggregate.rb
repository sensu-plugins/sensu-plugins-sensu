#!/usr/bin/env ruby
# frozen_string_literal: false

#
# Check Aggregate
# ===
#
# Authors
# ===
# Sean Porter, @portertech
#
# Copyright 2012 Sonian, Inc.
#
# Released under the same terms as Sensu (the MIT license); see
# LICENSE for details.

require 'sensu-plugin/check/cli'
require 'rest-client'
require 'json'

class CheckAggregate < Sensu::Plugin::Check::CLI
  option :api,
         short: '-a URL',
         long: '--api URL',
         description: 'Sensu API URL',
         default: if ENV['SENSU_API']
                    ENV['SENSU_API'] + ':4567'
                  elsif ENV['SENSU_API_URL']
                    ENV['SENSU_API_URL']
                  else
                    'http://localhost:4567'
                  end

  option :insecure,
         short: '-k',
         boolean: true,
         description: 'Enabling insecure connections',
         default: false

  option :user,
         short: '-u USER',
         long: '--user USER',
         description: 'Sensu API USER'

  option :password,
         short: '-p PASSWORD',
         long: '--password PASSWORD',
         description: 'Sensu API PASSWORD'

  option :timeout,
         short: '-t SECONDS',
         long: '--timeout SECONDS',
         description: 'Sensu API connection timeout in SECONDS',
         proc: proc(&:to_i),
         default: 30

  option :check,
         short: '-c CHECK',
         long: '--check CHECK',
         description: 'Aggregate CHECK name',
         required: true

  option :age,
         short: '-A SECONDS',
         long: '--age SECONDS',
         description: 'Minimum aggregate age in SECONDS, time since check request issued',
         default: 30,
         proc: proc(&:to_i)

  option :limit,
         short: '-l LIMIT',
         long: '--limit LIMIT',
         description: 'Limit of aggregates you want the API to return',
         proc: proc(&:to_i)

  option :collect_output,
         short: '-o',
         long: '--output',
         boolean: true,
         description: 'Collects all non-ok outputs',
         default: false

  option :warning,
         short: '-W PERCENT',
         long: '--warning PERCENT',
         description: 'PERCENT warning before warning (can be change with --ignore-severity)',
         proc: proc(&:to_i)

  option :warning_count,
         long: '--warning_count INTEGER',
         description: 'number of nodes in warning before warning (can be change with --ignore-severity)',
         proc: proc(&:to_i)

  option :critical,
         short: '-C PERCENT',
         long: '--critical PERCENT',
         description: 'PERCENT critical before critical (can be change with --ignore-severity)',
         proc: proc(&:to_i)

  option :critical_count,
         long: '--critical_count INTEGER',
         description: 'number of node in critical before critical (can be change with --ignore-severity)',
         proc: proc(&:to_i)

  option :pattern,
         short: '-P PATTERN',
         long: '--pattern PATTERN',
         description: 'A PATTERN to detect outliers'

  option :message,
         short: '-M MESSAGE',
         long: '--message MESSAGE',
         description: 'A custom error MESSAGE'

  option :ignore_severity,
         long: '--ignore-severity',
         description: 'Ignore severities, all non-ok will count for critical, critical_count, warning and warning_count option',
         boolean: true,
         default: false

  option :debug,
         short: '-D',
         long: '--debug',
         description: 'Display results hash at end of output message',
         boolean: true,
         default: false

  option :stale_percentage,
         long: '--stale-percentage PERCENT',
         description: 'PERCENT stale before warning',
         proc: proc(&:to_i)

  option :stale_count,
         long: '--stale-count INTEGER',
         description: 'number of nodes with stale data before warning',
         proc: proc(&:to_i)

  def api_request(resource)
    verify_mode = OpenSSL::SSL::VERIFY_PEER
    verify_mode = OpenSSL::SSL::VERIFY_NONE if config[:insecure]
    request = RestClient::Resource.new(config[:api] + resource, timeout: config[:timeout],
                                                                user: config[:user],
                                                                password: config[:password],
                                                                verify_ssl: verify_mode)
    JSON.parse(request.get, symbolize_names: true)
  rescue Errno::ECONNREFUSED
    warning 'Connection refused'
  rescue RestClient::RequestFailed
    warning 'Request failed'
  rescue RestClient::RequestTimeout
    warning 'Connection timed out'
  rescue RestClient::Unauthorized
    warning 'Missing or incorrect Sensu API credentials'
  rescue JSON::ParserError
    warning 'Sensu API returned invalid JSON'
  end

  def collect_output(aggregate)
    outputs = []
    %w[warning critical unknown].each do |severity|
      results = api_request("/aggregates/#{config[:check]}/results/#{severity}?max_age=#{config[:age]}")
      results.each do |result|
        result[:summary].each do |group|
          outputs << group[:output]
        end
      end
    end
    aggregate[:outputs] = outputs
    aggregate
  end

  def named_aggregate_results
    aggregate = api_request("/aggregates/#{config[:check]}?max_age=#{config[:age]}")
    results = aggregate[:results]
    if %w[ok warning critical unknown].all? { |severity| results[severity.to_sym].zero? }
      warning "No aggregates found in last #{config[:age]} seconds"
    end
    results
  end

  def compare_thresholds(aggregate)
    message = config[:message] || 'Number of non-zero results exceeds threshold'
    message += ' (%d%% %s)'
    message += "\n\sOutputs:\n\s\s" + aggregate[:outputs].join("\n\s\s") if aggregate[:outputs]
    if config[:debug]
      message += "\n" + aggregate.to_s
    end
    if config[:ignore_severity]
      percent_non_zero = (100 - (aggregate[:ok].to_f / aggregate[:total].to_f) * 100).to_i
      if config[:critical] && percent_non_zero >= config[:critical]
        critical format(message, percent_non_zero, 'non-zero')
      elsif config[:warning] && percent_non_zero >= config[:warning]
        warning format(message, percent_non_zero, 'non-zero')
      end
    else
      percent_warning = (aggregate[:warning].to_f / aggregate[:total].to_f * 100).to_i
      percent_critical = (aggregate[:critical].to_f / aggregate[:total].to_f * 100).to_i
      if config[:critical] && percent_critical >= config[:critical]
        critical format(message, percent_critical, 'critical')
      elsif config[:warning] && percent_warning >= config[:warning]
        warning format(message, percent_warning, 'warning')
      end
    end
  end

  def compare_pattern(aggregate)
    regex = Regexp.new(config[:pattern])
    mappings = {}
    message = config[:message] || 'One of these is not like the others!'
    if config[:debug]
      message += "\n" + aggregate.to_s
    end
    aggregate[:outputs].each do |output|
      matched = regex.match(output)
      unless matched.nil?
        key = matched[1]
        value = matched[2..-1]
        if mappings.key?(key)
          unless mappings[key] == value
            critical message + " (#{key})"
          end
        end
        mappings[key] = value
      end
    end
  end

  def compare_thresholds_count(aggregate)
    message = config[:message] || 'Number of nodes down exceeds threshold'
    message += " (%s out of #{aggregate[:total]} nodes reporting %s)"
    message += "\n\sOutputs:\n\s\s" + aggregate[:outputs].join("\n\s\s") if aggregate[:outputs]
    if config[:debug]
      message += "\n" + aggregate.to_s
    end
    if config[:ignore_severity]
      number_of_nodes_reporting_down = aggregate[:total].to_i - aggregate[:ok].to_i
      if config[:critical_count] && number_of_nodes_reporting_down >= config[:critical_count]
        critical format(message, number_of_nodes_reporting_down, 'not ok')
      elsif config[:warning_count] && number_of_nodes_reporting_down >= config[:warning_count]
        warning format(message, number_of_nodes_reporting_down, 'not ok')
      end
    else
      nodes_reporting_warning = aggregate[:warning].to_i
      nodes_reporting_critical = aggregate[:critical].to_i
      if config[:critical_count] && nodes_reporting_critical >= config[:critical_count]
        critical format(message, nodes_reporting_critical, 'critical')
      elsif config[:warning_count] && nodes_reporting_warning >= config[:warning_count]
        warning format(message, nodes_reporting_warning, 'warning')
      end
    end
  end

  def compare_stale(aggregate)
    message = config[:message] || 'Number of stale results exceeds threshold'
    message += " (%s out of #{aggregate[:total]} nodes reporting %s)"
    message += "\n\sOutputs:\n\s\s" + aggregate[:outputs].join("\n\s\s") if aggregate[:outputs]
    if config[:stale_percentage]
      percent_stale = (aggregate[:stale].to_f / aggregate[:total].to_f * 100).to_i
      if percent_stale >= config[:stale_percentage]
        warning format(message, percent_stale.to_s + '%', 'stale')
      end
    elsif config[:stale_count]
      if aggregate[:stale] >= config[:stale_count]
        warning format(message, aggregate[:stale].to_s, 'stale')
      end
    end
  end

  def run
    threshold = config[:critical] || config[:warning]
    threshold_count = config[:critical_count] || config[:warning_count]
    pattern = config[:pattern]
    critical 'Misconfiguration: critical || warning || pattern must be set' unless threshold || pattern || threshold_count

    aggregate = named_aggregate_results
    aggregate = collect_output(aggregate) if config[:collect_output]
    compare_thresholds(aggregate) if threshold
    compare_pattern(aggregate) if pattern
    compare_thresholds_count(aggregate) if threshold_count
    compare_stale(aggregate) if config[:stale_percentage] || config[:stale_count]

    if config[:debug]
      ok "Aggregate looks GOOD\n" + aggregate.to_s
    else
      ok 'Aggregate looks Good'
    end
  end
end
