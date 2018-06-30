#!/usr/bin/env ruby
# frozen_string_literal: false

require 'rubygems'
require 'sensu-handler'

class Deregister < Sensu::Handler
  option :invalidate,
         description: 'Invalidate Client',
         short: '-i',
         long: '--invalidate',
         default: false

  option :invalidate_expire,
         description: 'Invalidate Duration (seconds)',
         short: '-d duration',
         long: '--duration duration',
         required: false

  def handle
    delete_sensu_client!
  end

  def delete_sensu_client!
    response = if config[:invalidate] && config[:invalidate_expire]
                 api_request(:DELETE, '/clients/' + @event['client']['name'] + "?invalidate=#{config[:invalidate]}&#{config[:invalidate_expire]}").code
               elsif config[:invalidate]
                 api_request(:DELETE, '/clients/' + @event['client']['name'] + "?invalidate=#{config[:invalidate]}").code
               else
                 api_request(:DELETE, '/clients/' + @event['client']['name']).code
               end
    deletion_status(response)
  end

  def deletion_status(code)
    case code
    when '202'
      puts "202: Successfully deleted Sensu client: #{@event['client']['name']}"
    when '404'
      puts "404: Unable to delete #{@event['client']['name']}, doesn't exist!"
    when '500'
      puts "500: Miscellaneous error when deleting #{@event['client']['name']}"
    else
      puts "Completely unsure of what happened, status code: #{code}"
    end
  end

  def filter
    # override filter method to disable filtering of deregistration events
  end
end
