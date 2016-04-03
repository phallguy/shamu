require "rack"

module Shamu
  module JsonApi

    # Build an error response object.
    class ErrorBuilder

      def initialize
        @output = { id: SecureRandom.uuid }
      end

      # @param [String] id unique id for this occurrence of the error.
      def id( id )
        output[:id] = id
      end

      # Summary of the error.
      # @param [Integer] http_status code.
      # @param [String,Symbol] code application specific code for the error.
      # @param [String] human friendly title for the error.
      def summary( http_status, code = nil, title = nil )
        code ||= ::Rack::Util::HTTP_STATUS_CODES[ code ].to_s.underscore

        output[:status] = http_status.to_s
        output[:code]   = code.to_s
        output[:title]  = title || code.to_s.titleize
      end

      # Summarize an exception as an error.
      # @param [Exception] exception
      # @param [Integer] http_status code. Default 400.
      def exception( exception, http_status = nil )
        http_status ||= 500

        name = exception.class.name.demodulize.gsub( /Error$/, "" )
        summary http_status, name.underscore, name.titleize
        detail exception.message
      end

      # @return [String] message details about the error.
      def detail( message )
        output[:detail] = message
      end

      # Write a link to error information.
      #
      # @param [String,Symbol] name of the link.
      # @param [String] url
      # @param [Hash] meta optional additional meta information.
      # @return [void]
      def link( name, url, meta: nil )
        links = ( output[:links] ||= {} )

        if meta # rubocop:disable Style/ConditionalAssignment
          links[ name.to_sym ] = { href: url, meta: meta }
        else
          links[ name.to_sym ] = url
        end
      end

      # Add a meta field.
      # @param [String,Symbol] name of the meta field.
      # @param [Object] value that can be converted to a JSON primitive type.
      # @return [void]
      def meta( name, value )
        meta = ( output[:meta] ||= {} )
        meta[ name.to_sym ] = value
      end

      # @return [Hash] the results output as JSON safe hash.
      def compile
        output
      end

      private

        attr_reader :output

    end
  end
end