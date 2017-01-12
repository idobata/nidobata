require 'nidobata/version'

require 'json'
require 'net/https'
require 'netrc'
require 'thor'
require 'uri'

module Nidobata
  class CLI < Thor
    IDOBATA_URL = URI.parse('https://idobata.io')

    desc 'init', 'Init nidobata'
    def init
      email = ask('Email:')
      password = ask('Password:', echo: false)
      data = {grant_type: 'password', username: email, password: password}

      token = JSON.parse(http.post('/oauth/token', data.to_json, {'Content-Type' => 'application/json'}).tap(&:value).body)['access_token']
      netrc = Netrc.read
      netrc[IDOBATA_URL.host] = email, token
      netrc.save
    end

    desc 'post ORG_SLUG ROOM_NAME [MESSAGE] [--pre]', 'Post a message from stdin or 2nd argument.'
    option :pre, type: :boolean
    def post(slug, room_name, message = $stdin.read)
      abort 'Message is required.' unless message
      ensure_api_token

      rooms = JSON.parse(http.get("/api/rooms?organization_slug=#{slug}&room_name=#{room_name}", default_headers).tap(&:value).body)
      room_id = rooms['rooms'][0]['id']

      payload =
        if options[:pre]
          {room_id: room_id, source: "<pre>\n#{message}</pre>", format: 'html'}
        else
          {room_id: room_id, source: message}
        end

      http.post('/api/messages', payload.to_json, default_headers).value
    end

    desc 'rooms [ORG_SLUG]', 'list rooms'
    def rooms(slug = nil)
      ensure_api_token

      if slug
        rooms_url = "/api/rooms?organization_slug=#{slug}"
        org_slug = -> _ { slug }
      else
        rooms_url = "/api/rooms"
        orgs = JSON.parse(http.get("/api/organizations", default_headers).tap(&:value).body)
        org_slug = -> id do
          org = orgs["organizations"].detect {|org| org["id"] == id }
          org["slug"]
        end
      end

      rooms = JSON.parse(http.get(rooms_url, default_headers).tap(&:value).body)

      rooms["rooms"].each do |room|
        puts "#{org_slug[room["organization_id"]]}/#{room["name"]}"
      end
    end

    no_commands do
      private

      def ensure_api_token
        abort 'Run nidobata init for setup.' unless api_token
      end

      def api_token
        Netrc.read[IDOBATA_URL.host]&.password
      end

      def default_headers
        {'Content-Type' => 'application/json', 'Authorization' => "Bearer #{api_token}"}
      end

      def http
        Net::HTTP.new(IDOBATA_URL.host, IDOBATA_URL.port).tap {|http|
          http.use_ssl = IDOBATA_URL.scheme == 'https'
        }
      end
    end
  end
end
