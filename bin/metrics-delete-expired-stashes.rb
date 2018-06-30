#!/usr/bin/env ruby
# frozen_string_literal: false

#
# Delete stashes when their 'expires' timestamp is exceeded
# ===
#
# Copyright 2013 Needle, Inc (ops@needle.com)
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.

require 'sensu-plugin/metric/cli'
require 'sensu-plugin/utils'
require 'rest-client'
require 'json'
require 'socket'

class CheckSilenced < Sensu::Plugin::Metric::CLI::Generic
  include Sensu::Plugin::Utils
  default_host = begin
                   settings['api']['host']
                 rescue StandardError
                   'localhost'
                 end

  option :host,
         short: '-h HOST',
         long: '--host HOST',
         description: 'Hostname for sensu-api endpoint',
         default: default_host

  option :port,
         short: '-p PORT',
         long: '--port PORT',
         description: 'Port for sensu-api endpoint',
         default: 4567

  option :use_ssl,
         short: '--ssl',
         long: '--use-ssl',
         description: 'Use ssl when connecting to sensu-api endpoint',
         default: false

  option :scheme,
         short: '-s SCHEME',
         long: '--scheme SCHEME',
         description: 'Metric naming scheme, text to prepend to metric',
         default: "#{Socket.gethostname}.sensu.stashes.expired"

  option :filter,
         short: '-f PREFIX',
         long: '--filter PREFIX',
         description: 'Stash prefix filter',
         default: 'silence'

  option :noop,
         short: '-n',
         long: '--noop',
         description: 'Do not delete expired stashes',
         default: false

  option :measurement,
         description: 'Measurement for influxdb format',
         long: '--measurement MEASUREMENT',
         default: 'sensu.stashes'

  def api
    endpoint = URI.parse("http://#{@config[:host]}:#{@config[:port]}")
    endpoint.scheme = if @config[:use_ssl?]
                        'https'
                      else
                        'http'
                      end
    endpoint.scheme = (@config[:use_ssl?] ? 'https' : 'http')
    @api ||= RestClient::Resource.new(endpoint, timeout: 45)
  end

  def acquire_stashes
    all_stashes = ::JSON.parse(api['/stashes'].get)
    filtered_stashes = []
    all_stashes.each do |stash|
      filtered_stashes << stash if stash['path'] =~ /^#{@config[:filter]}\/.*/
    end
    filtered_stashes
  rescue Errno::ECONNREFUSED
    warning 'Connection refused'
  rescue RestClient::RequestTimeout
    warning 'Connection timed out'
  rescue ::JSON::ParserError
    warning 'Sensu API returned invalid JSON'
  end

  def delete_stash(stash)
    api["/stash/#{stash['path']}"].delete
  end

  def run
    @config = config
    stashes = acquire_stashes
    now = Time.now.to_i
    @count = 0
    if stashes.count.positive?
      stashes.each do |stash|
        if stash['content'].key?('expires') && now - stash['content']['expires'] .positive?
          delete_stash(stash) unless config[:noop]
          @count += 1
        end
      end
    end
    ok metric_name: 'expired',
       value: @count,
       graphite_metric_path: "#{config[:scheme]}.sensu.stashes.expired",
       statsd_metric_name: "#{config[:scheme]}.sensu.stashes.expired",
       influxdb_measurement: config[:measurement],
       tags: {
         host: Socket.gethostname
       }
  end
end
