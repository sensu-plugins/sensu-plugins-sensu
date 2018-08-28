#!/usr/bin/env ruby
# frozen_string_literal: false

#
# handler-purge-stale-results.rb
#
# Author: Matteo Cerutti <matteo.cerutti@hotmail.co.uk>
#

require 'sensu-handler'
require 'time'
require 'net/smtp'
require 'socket'
require 'chronic_duration'

class HandlerPurgeStaleResults < Sensu::Handler
  option :stale,
         description: 'Elapsed time after which a stale check result will be deleted (default: 7d)',
         short: '-s <TIME>',
         long: '--stale <TIME>',
         proc: proc { |s| ChronicDuration.parse(s) },
         default: ChronicDuration.parse('7d')

  option :mail_server,
         description: 'Mail server (default: localhost)',
         long: '--mail-server <HOST>',
         default: 'localhost'

  option :mail_sender,
         description: 'Mail sender (default: sensu@localhost)',
         long: '--mail-sender <ADDRESS>',
         default: 'sensu@localhost'

  option :mail_recipient,
         description: 'Mail recipient',
         long: '--mail-recipient <ADDRESS>',
         required: true

  def results
    res = paginated_get('/results')
    res
  end

  def handle
    deleted = []
    failed = []

    results.each do |result|
      diff = Time.now.to_i - result['check']['issued']
      if diff > config[:stale]
        begin
          req = api_request(:DELETE, "/results/#{result['client']}/#{result['check']['name']}")
          if req.code != '204'
            failed << "#{result['client']} - #{result['check']['name']} (Code: #{req.code}, Message: #{req.body})"
          else
            deleted << "#{result['client']} - #{result['check']['name']}"
          end
        rescue StandardError
          failed << "#{result['client']} - #{result['check']['name']} (Caught exception: #{$ERROR_INFO})"
        end
      end
    end

    if !deleted.empty? || !failed.empty?
      msg = <<~MESSAGE
        From: Sensu <#{config[:mail_sender]}>
        To: <#{config[:mail_recipient]}>
        Subject: Purge stale check results

        This is a notification concerning the #{self.class.name} sensu handler running at #{Socket.gethostname}

        * Summary

            Deleted: #{deleted.size}
            Failed to delete: #{failed.size}

        * Failed to delete check results:

        #{failed.map { |m| "    #{m}" }.join("\n")}

        * Deleted check results:

        #{deleted.map { |m| "    #{m}" }.join("\n")}
      MESSAGE

      Net::SMTP.start(config[:mail_server]) do |smtp|
        smtp.send_message(msg, config[:mail_sender], config[:mail_recipient])
      end
    end
  end
end
