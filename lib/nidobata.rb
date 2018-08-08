require 'nidobata/version'

require 'json'
require 'net/https'
require 'netrc'
require 'thor'
require 'uri'

require 'graphql/client'
require 'graphql/client/http'

module Nidobata
  class CLI < Thor
    IDOBATA_URL = URI.parse('https://idobata.io')

    HTTP = GraphQL::Client::HTTP.new('https://api.idobata.io/graphql') {
      def headers(context)
        {'Authorization' => "Bearer #{context[:api_token]}"}
      end
    }

    Schema = GraphQL::Client.load_schema(File.expand_path("#{__dir__}/../schema.json"))
    Client = GraphQL::Client.new(schema: Schema, execute: HTTP)

    RoomListQuery = Client.parse(<<~QUERY)
      query {
        viewer {
          rooms {
            edges { node { id name organization { slug }
          } } } } }
    QUERY

    CreateMessageMutation = Client.parse(<<~MUTATION)
      mutation ($input: CreateMessageInput!) {
        createMessage(input: $input)
      }
    MUTATION

    desc 'init', 'Init nidobata'
    def init
      email    = ask('Email:')
      password = ask('Password:', echo: false)
      puts

      http = Net::HTTP.new(IDOBATA_URL.host, IDOBATA_URL.port).tap {|h|
        h.use_ssl = IDOBATA_URL.scheme == 'https'
      }

      data = {grant_type: 'password', username: email, password: password}
      res  = http.post('/oauth/token', data.to_json, {'Content-Type' => 'application/json'})

      case res
      when Net::HTTPSuccess
        token = JSON.parse(res.body)['access_token']
        netrc = Netrc.read
        netrc[IDOBATA_URL.host] = email, token
        netrc.save
      when Net::HTTPUnauthorized
        abort 'Authentication failed. You may have entered wrong Email or Password.'
      else
        abort <<~EOS
          Failed to initialize.
          Status: #{res.code}
          Body:
          #{res.body}
        EOS
      end
    end

    desc 'post ORG_SLUG ROOM_NAME [MESSAGE] [--pre] [--title]', 'Post a message from stdin or 2nd argument.'
    option :pre,   type: :string, lazy_default: '', desc: 'can be used syntax highlight if argument exists'
    option :title, type: :string, default: nil
    def post(slug, room_name, message = $stdin.read)
      abort 'Message is required.' unless message
      ensure_api_token

      room_id = query(RoomListQuery).data.viewer.rooms.edges.map(&:node).find {|room|
        room.organization.slug == slug && room.name == room_name
      }.id

      payload = {
        roomId: room_id,
        source: build_message(message, options),
        format: options[:pre] ? 'MARKDOWN' : 'PLAIN'
      }

      query CreateMessageMutation, variables: {input: payload}
    end

    desc 'rooms [ORG_SLUG]', 'list rooms'
    def rooms(slug = nil)
      ensure_api_token

      rooms = query(RoomListQuery).data.viewer.rooms.edges.map(&:node)
      rooms.select! {|room| room.organization.slug == slug } if slug

      rooms.map {|room|
        "#{room.organization.slug}/#{room.name}"
      }.sort.each do |name|
        puts name
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

      def query(q, variables: {}, context: {})
        Client.query(q, variables: variables, context: {api_token: api_token}.merge(context))
      end

      def build_message(original_message, options)
        return original_message if options.empty?

        title, pre = options.values_at(:title, :pre)

        message = pre ? "~~~#{pre}\n#{original_message}\n~~~" : original_message
        title ? "#{title}\n\n#{message}" : message
      end
    end
  end
end
