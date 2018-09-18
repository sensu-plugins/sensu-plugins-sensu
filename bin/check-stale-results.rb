#!/usr/bin/env ruby
# frozen_string_literal: false

#
# check-stale-results.rb
#
# Author: Matteo Cerutti <matteo.cerutti@hotmail.co.uk>
#

require 'net/http'
require 'uri'
require 'sensu-plugin/utils'
require 'sensu-plugin/check/cli'
require 'json'
require 'chronic_duration'

class CheckStaleResults < Sensu::Plugin::Check::CLI
  include Sensu::Plugin::Utils

  option :stale,
         description: 'Elapsed time to consider a check result result (default: 1d)',
         short: '-s <TIME>',
         long: '--stale <TIME>',
         proc: proc { |s| ChronicDuration.parse(s) },
         default: ChronicDuration.parse('1d')

  option :verbose,
         description: 'Be verbose',
         short: '-v',
         long: '--verbose',
         boolean: true,
         default: false

  option :warn,
         description: 'Warn if number of stale check results exceeds COUNT (default: 1)',
         short: '-w <COUNT>',
         long: '--warn <COUNT>',
         proc: proc(&:to_i),
         default: 1

  option :crit,
         description: 'Critical if number of stale check results exceeds COUNT',
         short: '-c <COUNT>',
         long: '--crit <COUNT>',
         proc: proc(&:to_i),
         default: nil

  option :timeout,
         description: 'read timeout for http request',
         short: '-t <TIME>',
         long: '--timeout <TIME>',
         proc: proc(&:to_i),
         default: 60

  def initialize
    super

    raise 'Critical threshold must be higher than the warning threshold' if config[:crit] && config[:warn] >= config[:crit]

    # get list of sensu results
    @results = results
  end

  def humanize(secs)
    [[60, :seconds], [60, :minutes], [24, :hours], [1000, :days]].map do |count, name|
      if secs.positive?
        secs, n = secs.divmod(count)
        "#{n.to_i} #{name}"
      end
    end.compact.reverse.join(' ')
  end

  def get_uri(path)
    protocol = (settings['api']['host'] =~ /^https:\/\// ? 'https' : 'http')
    host = (protocol == 'https' ? settings['api']['host'][8..-1] : settings['api']['host'])
    URI("#{protocol}://#{host}:#{settings['api']['port']}#{path}")
  end

  def api_request(method, path)
    unless settings.key?('api')
      unknown <<~HEREDOC
        sensu does not have an api config stanza set, please configure it in
        either /etc/sensu/config.json or in any config that is loaded by sensu
        such as /etc/sensu/conf.d/api.json
      HEREDOC
    end
    uri = get_uri(path)
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https', read_timeout: config[:timeout]) do |http|
      request = net_http_req_class(method).new(path)
      if settings['api']['user'] && settings['api']['password']
        request.basic_auth(settings['api']['user'], settings['api']['password'])
      end
      yield(request) if block_given?
      http.request request # Net::HTTPResponse object
    end
  end

  def results
    res = paginated_get('/results')
    res
  end

  def run
    stale = 0
    footer = "\n\n"
    @results.each do |result|
      diff = Time.now.to_i - result['check']['issued']
      if diff > config[:stale]
        stale += 1
        footer += "  - check result #{result['client']}/#{result['check']['name']} is stale (#{humanize(diff)})\n"
      end
    end
    footer += "\n"

    if config[:crit] && stale >= config[:crit]
      msg = "Found #{stale} stale check results (>= #{config[:crit]})"
      msg += footer if config[:verbose]
      critical(msg)
    end

    if stale >= config[:warn]
      msg = "Found #{stale} stale check results (>= #{config[:warn]})"
      msg += footer if config[:verbose]
      warning(msg)
    end

    ok "No stale check results found (>= #{config[:warn]})"
  end
end
