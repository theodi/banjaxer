require 'thor'
require 'httparty'
require 'banjaxer/version'

module Banjaxer
  class CLI < Thor
    desc 'version', 'Print banjaxer version'
    def version
      puts "banjaxer version #{VERSION}"
    end
    map %w(-v --version) => :version

    desc 'get_url', 'GET a url and tell us the Content-Length'
    def get_url url
      h = HTTParty.get url, headers: { 'Accept' => 'application/json' }
      puts "Content-Length is #{h.headers['Content-Length']}"
    end

    desc 'tell_the_time', 'Tell us the current time and date'
    def tell_the_time
      puts Time.new.strftime "%H:%M on %A %B %-d, %Y"
    end
  end
end
