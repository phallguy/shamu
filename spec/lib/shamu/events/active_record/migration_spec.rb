require "spec_helper"
require "shamu/active_record"

describe Shamu::Events::ActiveRecord::Migration do

  it "can run" do
    Shamu::Events::ActiveRecord::Migration.new.migrate( :down )
    Shamu::Events::ActiveRecord::Migration.new.migrate( :up )
  end

end