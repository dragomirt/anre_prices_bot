# This file is autogenerated. Do not edit it by hand. Regenerate it with:
#   srb rbi gems

# typed: strict
#
# If you would like to make changes to this file, great! Please create the gem's shim here:
#
#   https://github.com/sorbet/sorbet-typed/new/master?filename=lib/faraday-rack/all/faraday-rack.rbi
#
# faraday-rack-1.0.0

module Faraday
end
class Faraday::Adapter
end
class Faraday::Adapter::Rack < Faraday::Adapter
  def build_rack_env(env); end
  def call(env); end
  def execute_request(env, rack_env); end
  def initialize(faraday_app, rack_app); end
end
module Faraday::Rack
end
