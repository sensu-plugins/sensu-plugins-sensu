#!/usr/bin/env ruby
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

  def initialize
    super

    raise 'Critical threshold must be higher than the warning threshold' if config[:crit] && config[:warn] >= config[:crit]

    # get list of sensu results
    @results = results
  end

  def humanize(secs)
    [[60, :seconds], [60, :minutes], [24, :hours], [1000, :days]].map do |count, name|
      if secs > 0
        secs, n = secs.divmod(count)
        "#{n.to_i} #{name}"
      end
    end.compact.reverse.join(' ')
  end

  def get_uri(path)
    protocol = (settings['api'].key?('protocol') ? settings['api']['protocol'] : 'http')
    uri = URI(protocol + '://' + settings['api']['host'] + ':' + settings['api']['port'].to_s + path)
  end

  def api_request(path)
    unless settings.key?('api')
      raise 'api.json settings not found.'
    end
    uri = get_uri(path)
    response = nil
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
      request = Net::HTTP::Get.new uri
      if settings['api']['user'] && settings['api']['password']
        request.basic_auth(settings['api']['user'], settings['api']['password'])
      end
      yield(request) if block_given?
      response = http.request request # Net::HTTPResponse object
    end
    response
  end

  def results
    res = []
    req = api_request('/results')
    res = JSON.parse(req.body) if req && req.code == '200'
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
