module Shamu
  module Extensions
    # Add some developer friendly inspection output to classes.
    module Inspectable
      def inspect
        io = StringIO.new
        PP.singleline_pp(self, io)

        io.string
      end

      def pretty_print(pp)
        attributes = inspectable_attributes
        attributes.reject! do |a|
          send(a).nil?
        rescue StandardError
          true
        end

        pp.object_address_group(self) do
          pretty_print_custom(pp)
          pp.seplist(attributes, -> { pp.text(",") }) do |name|
            value = begin
              send(name)
            rescue StandardError
              "???"
            end

            pp.breakable(" ")
            pp.group(1) do
              pp.text(name.to_s)
              pp.text(":")
              pp.breakable(" ")
              pp.pp(value)
            end
          end
        end
      end

      private

        def pretty_print_custom(pp); end

        def inspectable_attributes
          detect_inspectable_attributes
        end

        def detect_inspectable_attributes
          %i[network id name title].select do |eligible|
            respond_to?(eligible)
          end
        end
    end
  end
end
