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

    def get_url url
      h = HTTParty.get url, headers: { 'Accept' => 'application/json' }
      puts "Content-Length is #{h.headers['Content-Length']}"
    end

    def tell_the_time
      puts Time.new.strftime "%H:%M on %A %B %-d, %Y"
    end
  end
end
