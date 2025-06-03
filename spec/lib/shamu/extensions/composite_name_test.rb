require "test_helper"
require "shamu/extensions/composite_name"

module Shamu
  module Extensions
    class HasNameTest
      include Extensions::CompositeName

      attr_accessor :name

      def initialize(name)
        self.name = name
      end
    end

    class CompositeNameTest < ActiveSupport::TestCase
      [
        {
          name: "Mr. John Smith",
          first_name: "John",
          last_name: "Smith",
          middle_name: nil,
          honorific: "Mr.",
          unhonored_name: "John Smith",
          legal_name: "Smith, John"
        },
        {
          name: "Paul Alexander",
          first_name: "Paul",
          last_name: "Alexander",
          middle_name: nil,
          honorific: nil,
          unhonored_name: "Paul Alexander",
          legal_name: "Alexander, Paul"
        },
        {
          name: "Captain James T. Kirk",
          first_name: "James",
          last_name: "Kirk",
          middle_name: "T",
          honorific: "Captain",
          unhonored_name: "James Kirk",
          legal_name: "Kirk, James T"
        },
        {
          name: "Dr. Spock",
          first_name: nil,
          last_name: "Spock",
          honorific: "Dr.",
          middle_name: nil,
          unhonored_name: "Spock",
          legal_name: "Spock"
        },
        {
          name: "Kirk",
          first_name: "Kirk",
          last_name: nil,
          middle_name: nil,
          honorific: nil,
          unhonored_name: "Kirk",
          legal_name: "Kirk"
        },
        {
          name: "ALEXANDER, PAUL",
          first_name: "Paul",
          last_name: "Alexander",
          middle_name: nil,
          honorific: nil,
          unhonored_name: "Paul Alexander",
          legal_name: "Alexander, Paul"
        },
        {
          name: "MELTON, JR KENNETH",
          first_name: "Kenneth",
          last_name: "Melton",
          middle_name: nil,
          honorific: nil,
          suffix: "Jr",
          unhonored_name: "Kenneth Melton",
          legal_name: "Melton, Kenneth"
        },
        {
          name: "MELTON, KENNETH JR",
          first_name: "Kenneth",
          last_name: "Melton",
          middle_name: nil,
          honorific: nil,
          suffix: "Jr",
          unhonored_name: "Kenneth Melton",
          legal_name: "Melton, Kenneth"
        },
        {
          name: "Mr John W Wayne III",
          first_name: "John",
          last_name: "Wayne",
          middle_name: "W",
          honorific: "Mr",
          suffix: "III",
          unhonored_name: "John W Wayne III",
          legal_name: "Wayne, John W"

        },
        {
          name: "carolynh1944@gmail.com",
          first_name: "Carolynh",
          last_name: nil,
          middle_name: nil,
          honorific: nil,
          suffix: nil,
          unhonored_name: "Carolynh",
          legal_name: "Carolynh"
        }
      ].each do |scenario|
        test "#{scenario[:name]} is parsed correctly" do
          subject = HasNameTest.new(scenario[:name])

          assert_equal scenario[:first_name], subject.first_name
          assert_equal scenario[:suffix], subject.suffix
          assert_equal scenario[:last_name], subject.last_name
          assert_equal scenario[:honorific], subject.honorific
          assert_equal scenario[:legal_name], subject.legal_name(true)
          assert_equal scenario[:middle_name], subject.middle_name
        end
      end
    end
  end
end
