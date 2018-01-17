#!/usr/bin/env ruby
#
# Check Aggregate Output
# ===
# This check is very similar to check-aggregate.rb, it checks the Sensu aggregate
# api and returns Critical / Warning / OK based on how many aggregate results
# match the options you configure.
#
# Authors
# ===
# AJ Bourg, @ajbourg
# Sean Porter, @portertech
#
# Copyright 2017
#
# Released under the same terms as Sensu (the MIT license); see
# LICENSE for details.

require 'sensu-plugin/check/cli'
require 'rest-client'
require 'json'

class CheckAggregateOutput < Sensu::Plugin::Check::CLI
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

  option :message,
         short: '-M MESSAGE',
         long: '--message MESSAGE',
         description: 'A custom error MESSAGE'

  option :collect_output,
         short: '-o',
         long: '--output',
         boolean: true,
         description: 'Collects all non-ok outputs',
         default: true

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

  option :ignore_severity,
         long: '--ignore-severity',
         description: 'Ignore severities, all non-ok will count for critical, critical_count, warning and warning_count option',
         boolean: true,
         default: false

  def api_request(resource)
    verify_mode = OpenSSL::SSL::VERIFY_PEER
    verify_mode = OpenSSL::SSL::VERIFY_NONE if config[:insecure]
    request = RestClient::Resource.new(config[:api] + resource, timeout: config[:timeout],
                                                                user: config[:user],
                                                                password: config[:password],
                                                                verify_ssl: verify_mode)
    JSON.parse(request.get)
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

  def aggregate_results
    results = api_request("/aggregates/#{config[:check]}?max_age=#{config[:age]}")['results']
    warning "No aggregates found in last #{config[:age]} seconds" if %w[ok warning critical unknown].all? { |x| results[x].zero? }
    results
  end

  def output_results
    severities = %w[critical warning unknown]

    outputs = {}

    severities.each do |severity|
      outputs[severity] = api_request("/aggregates/#{config[:check]}/results/#{severity}?max_age=#{config[:age]}")
    end

    outputs
  end

  def message_of_outputs(outputs)
    message = ''
    outputs.each do |severity, o|
      o.each do |output|
        output['summary'].each do |summary|
          message += "#{summary['total']} clients #{severity} #{summary['clients']}: #{summary['output']} \n"
        end
      end
    end

    message
  end

  def count_based?
    config[:critical_count] || config[:warning_count]
  end

  def percent_based?
    config[:critical] || config[:warning]
  end

  def percent(count, total)
    (count.to_f / total.to_f * 100).to_i
  end

  def critical?
    if count_based? && @results['critical'] >= config[:critical_count]
      true
    elsif percent_based? && percent(@results['critical'], @results['total']) >= config[:critical]
      true
    else
      false
    end
  end

  def warning?
    if count_based? && @results['warning'] >= config[:critical_count]
      true
    elsif percent_based? && percent(@results['warning'], @results['total']) >= config[:warning]
      true
    else
      false
    end
  end

  def run
    @results = aggregate_results

    message = config[:message] ? config[:message] : "Results exceed thresholds: #{@results}"
    message += "\n" + message_of_outputs(output_results) if config[:collect_output]

    if critical?
      critical message
    elsif warning?
      warning message
    else
      ok message
    end
  end
end
