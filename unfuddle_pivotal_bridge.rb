require 'net/http'
require 'yaml'
require 'nokogiri'

module UnfuddlePivotalBridgeError
  class Invalid    < StandardError; end
  class PivotalApi < StandardError; end
end

class UnfuddlePivotalBridge
  attr_accessor :pivotal_project_id, :changeset, :author, :revision, :message, :story_id
  attr_reader :errors

  def initialize(pivotal_project_id = nil, pivotal_token = nil)
    @pivotal_project_id = pivotal_project_id
    @pivotal_token = pivotal_token
    parse_config unless (@pivotal_project_id && @pivotal_token)

    @errors = []
    @pivotal_api_base = "http://www.pivotaltracker.com/services/v3/projects"
  end

  def parse_config
    config = YAML.load(File.read("bridge_config.yml"))
    @pivotal_project_id ||= config["pivotal_project_id"]
    @pivotal_token      ||= config["pivotal_token"]
  end

  def get_token(username, password)
    # Needs SSL
    # manual: curl -u USERNAME:PASSWORD -X GET https://www.pivotaltracker.com/services/v3/tokens/active
  end

  def add_note
    raise UnfuddlePivotalBridgeError::Invalid.new(errors.to_s) unless valid?

    uri = URI.parse("#{@pivotal_api_base}/#{@pivotal_project_id}/stories/#{@story_id}/notes")
    response = Net::HTTP.new(uri.host).start do |http|
      http.post(uri.path, comment_xml, {'X-TrackerToken' => @pivotal_token, 'Content-Type' => 'application/xml'})
    end

    validate_response(response.body)
    doc = Nokogiri::XML(response.body)
    { :id     => doc.xpath('//id').text.to_i,
      :text   => doc.xpath('//text').text,
      :author => doc.xpath('//author').text,
      :date   => doc.xpath('//note_at').text }
  end

  def comment_xml
    text = "Revision #{@revision} committed (#{@message})."
    "<note><text>#{text}</text></note>"
  end

  def parse_unfuddle_changeset(xml)
    @changeset = Nokogiri::XML(xml)
    @revision = @changeset.xpath('//changeset/revision').text
    @message = @changeset.xpath('//changeset/message').text
    @story_id = @message.match(/Story:(\d*)/)[1].to_i rescue nil
  end

  def valid?
    validate
    @errors.empty?
  end

  private
  def validate
    @errors.clear
    @errors << "Story ID is missing"           unless @story_id
    @errors << "Commit message is missing"     unless @message
    @errors << "Commit revision is missing"    unless @revision
    @errors << "Pivotal Project ID is missing" unless @pivotal_project_id
  end

  def validate_response(body)
    response = Nokogiri::XML(body)
    message = response.xpath('//message').text
    errors = response.xpath('//error').map(&:text)

    if message =~ /resource not found/i
      raise UnfuddlePivotalBridgeError::PivotalApi.new(message)
    elsif errors.any?
      raise UnfuddlePivotalBridgeError::PivotalApi.new(errors.to_s)
    end
  end
end
