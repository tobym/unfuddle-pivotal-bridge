require 'sinatra'
require 'unfuddle_pivotal_bridge'

post '/unfuddle-pivotal-bridge' do
  raw = request.body.string
  bridge = UnfuddlePivotalBridge.new
  bridge.parse_unfuddle_changeset(raw)
  bridge.add_note
  "Success"
end
