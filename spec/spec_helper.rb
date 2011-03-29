require 'bundler'

Bundler.setup
Bundler.require
require 'yajl'
require 'goliath/test_helper'

RSpec.configure do |c|
  c.include Goliath::TestHelper
end
