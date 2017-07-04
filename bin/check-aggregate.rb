#!/usr/bin/env ruby
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

  option :summarize,
         short: '-s',
         long: '--summarize',
         boolean: true,
         description: 'Summarize check result output',
         default: false

  option :collect_output,
         short: '-o',
         long: '--output',
         boolean: true,
         description: 'Collects all non-ok outputs',
         default: false

  option :warning,
         short: '-W PERCENT',
         long: '--warning PERCENT',
         description: 'PERCENT non-ok before warning',
         proc: proc(&:to_i)

  option :warning_count,
         long: '--warning_count INTEGER',
         description: 'number of nodes in warning before warning',
         proc: proc(&:to_i)

  option :critical,
         short: '-C PERCENT',
         long: '--critical PERCENT',
         description: 'PERCENT non-ok before critical',
         proc: proc(&:to_i)

  option :critical_count,
         long: '--critical_count INTEGER',
         description: 'number of node in critical before critical',
         proc: proc(&:to_i)

  option :pattern,
         short: '-P PATTERN',
         long: '--pattern PATTERN',
         description: 'A PATTERN to detect outliers'

  option :honor_stash,
         short: '-i',
         long: '--honor-stash',
         description: 'Checks that are stashed will be ignored from the aggregate',
         boolean: true,
         default: false

  option :message,
         short: '-M MESSAGE',
         long: '--message MESSAGE',
         description: 'A custom error MESSAGE'

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

  def honor_stash(aggregate)
    # FIXME: it's broken with named aggregates
    aggregate[:results].delete_if do |entry|
      begin
        api_request("/stashes/silence/#{entry[:client]}/#{config[:check]}")
        if entry[:status] == 0
          aggregate[:ok] = aggregate[:ok] - 1
        elsif entry[:status] == 1
          aggregate[:warning] = aggregate[:warning] - 1
        elsif entry[:status] == 2
          aggregate[:critical] = aggregate[:critical] - 1
        else
          aggregate[:unknown] = aggregate[:unknown] - 1
        end
        aggregate[:total] = aggregate[:total] - 1
        true
      rescue RestClient::ResourceNotFound
        false
      end
    end
    aggregate
  end

  def use_named_aggregates?
    api_request('/info')[:sensu][:version].split('.')[1] >= '24'
  end

  def collect_output(aggregate)
    # works with named aggregates only
    aggregate[:results] = []
    [:critical, :warning].each do |s|
      aggregate[:results] += api_request("/aggregates/#{config[:check]}/results/#{s}?max_age=#{config[:age]}") unless aggregate[s] == 0
    end
    output = ''
    aggregate[:results].each do |r|
      r[:summary].each do |s|
        output << "#{r[:check]} #{s[:clients]} #{s[:output]}"
      end
    end
    aggregate[:outputs] = output unless output.empty?
    aggregate
  end

  def acquire_aggregate
    if use_named_aggregates?
      named_aggregate_results
    else
      aggregate_results
    end
  end

  def named_aggregate_results
    results = api_request("/aggregates/#{config[:check]}?max_age=#{config[:age]}")[:results]
    warning "No aggregates found in last #{config[:age]} seconds" if %w(ok warning critical unknown).all? { |x| results[x.to_sym] == 0 }
    results
  end

  def aggregate_results
    uri = "/aggregates/#{config[:check]}"
    issued = api_request(uri + "?age=#{config[:age]}" + (config[:limit] ? "&limit=#{config[:limit]}" : ''))
    unless issued.empty?
      issued_sorted = issued.sort
      time = issued_sorted.pop
      unless time.nil?
        uri += "/#{time}?"
        uri += '&summarize=output' if config[:summarize]
        uri += '&results=true' if config[:honor_stash] || config[:collect_output]
        api_request(uri)
      else
        warning "No aggregates older than #{config[:age]} seconds"
      end
    else
      warning "No aggregates for #{config[:check]}"
    end
  end

  def compare_thresholds(aggregate)
    percent_non_zero = (100 - (aggregate[:ok].to_f / aggregate[:total].to_f) * 100).to_i
    message = config[:message] || 'Number of non-zero results exceeds threshold'
    message += " (#{percent_non_zero}% non-zero)"
    message += "\n" + aggregate[:outputs] if aggregate[:outputs]

    if config[:critical] && percent_non_zero >= config[:critical]
      critical message
    elsif config[:warning] && percent_non_zero >= config[:warning]
      warning message
    end
  end

  def compare_pattern(aggregate)
    # FIXME: it's broken with named aggregates
    regex = Regexp.new(config[:pattern])
    mappings = {}
    message = config[:message] || 'One of these is not like the others!'
    aggregate[:outputs].each do |output, _count|
      matched = regex.match(output.to_s)
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
    number_of_nodes_reporting_down = aggregate[:total].to_i - aggregate[:ok].to_i
    message = config[:message] || 'Number of nodes down exceeds threshold'
    message += " (#{number_of_nodes_reporting_down} out of #{aggregate[:total]} nodes reporting not ok)"
    message += "\n" + aggregate[:outputs] if aggregate[:outputs]

    if config[:critical_count] && number_of_nodes_reporting_down >= config[:critical_count]
      critical message
    elsif config[:warning_count] && number_of_nodes_reporting_down >= config[:warning_count]
      warning message
    end
  end

  def run
    threshold = config[:critical] || config[:warning]
    threshold_count = config[:critical_count] || config[:warning_count]
    pattern = config[:summarize] && config[:pattern]
    critical 'Misconfiguration: critical || warning || (summarize && pattern) must be set' unless threshold || pattern || threshold_count

    aggregate = acquire_aggregate
    aggregate = honor_stash(aggregate) if config[:honor_stash]
    puts aggregate
    aggregate = collect_output(aggregate) if config[:collect_output]
    compare_thresholds(aggregate) if threshold
    compare_pattern(aggregate) if pattern
    compare_thresholds_count(aggregate) if threshold_count

    ok 'Aggregate looks GOOD'
  end
end
