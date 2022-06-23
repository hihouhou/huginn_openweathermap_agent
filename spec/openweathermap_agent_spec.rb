require 'rails_helper'
require 'huginn_agent/spec_helper'

describe Agents::OpenweathermapAgent do
  before(:each) do
    @valid_options = Agents::OpenweathermapAgent.new.default_options
    @checker = Agents::OpenweathermapAgent.new(:name => "OpenweathermapAgent", :options => @valid_options)
    @checker.user = users(:bob)
    @checker.save!
  end

  pending "add specs here"
end
