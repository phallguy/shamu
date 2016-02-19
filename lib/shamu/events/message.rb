module Shamu
  module Events

    # The event {Message} consists of a set of well-defined attributes
    # describing a single discrete event in the system and associated meta-data
    # needed by subscribers to process the message.
    #
    # Messages should attempt to forward the state available at the time the
    # event was published so that subscribers can process the message without
    # contacting additional services.
    #
    # Event messages are  serialized for network or IPC transimission and must
    # limit attributes to primitive types (Strings, Numbers, Arrays and Hashes)
    # so they can be round tripped with `Message.new( message.to_attributes )`.
    class Message
      include Shamu::Attributes
      include Shamu::Attributes::Equality

      # ============================================================================
      # @!group Attributes
      #

      # @!attribute
      # @return [String] the ID for the message. Automatically generated UUID
        attribute :id

      #
      # @!endgroup Attributes


      def initialize( * )
        super

        @id ||= SecureRandom.uuid
      end
    end
  end
end