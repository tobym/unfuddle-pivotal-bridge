require 'sinatra/base'
require 'unfuddle_pivotal_bridge'

class UnfuddlePostcommitEndpoint < Sinatra::Base
  post '/unfuddle-pivotal-bridge' do
    raw = request.body.read
    bridge = UnfuddlePivotalBridge.new
    bridge.parse_unfuddle_changeset(raw)
    bridge.add_note
    "Success"
  end
end
