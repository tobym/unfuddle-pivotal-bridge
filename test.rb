require 'test/unit'
require 'unfuddle_pivotal_bridge'

class UnfuddlePivotalBridgeTest < Test::Unit::TestCase
  PID = 1234
  TOKEN = "asdf234sdf234"

  def setup
    @bridge = UnfuddlePivotalBridge.new(PID, TOKEN)
    @bridge.parse_unfuddle_changeset(changeset)
  end

  def setup_for_failures
    @bridge = UnfuddlePivotalBridge.new(PID, TOKEN)
    @bridge.parse_unfuddle_changeset(bad_changeset)
  end

  def test_extract_message
    assert_equal "Story:434927 Implement awesome feature", @bridge.message, "Commit message was not extracted correctly"
  end

  def test_extract_revision
    assert_equal "4f657b17281aaae24284bfd15e47f9c279049f9b", @bridge.revision, "Commit revision was not extracted correctly"
  end

  def test_extract_story_id
    assert_equal 434927, @bridge.story_id, "Pivotal Story ID was not extracted correctly"
  end

  def test_valid
    assert @bridge.valid?, "Bridge should be valid. Errors: #{@bridge.errors.to_s}"
  end

  def test_invalid
    setup_for_failures

    assert !@bridge.valid?
    assert @bridge.errors.include? "Story ID is missing"
  end

  def test_fail_add_note
    setup_for_failures

    begin
      @bridge.add_note
    rescue UnfuddlePivotalBridgeError::Invalid => e
      @error = e
    end

    assert @error.message =~ /is missing/i
  end


  private
  # This is the data that Unfuddle POSTs to the repository callback URL
  def changeset
    xml =<<EOF
<?xml version="1.0" encoding="UTF-8"?>
<changeset>
  <author-date type="datetime">2010-05-26T17:22:11Z</author-date>
  <author-email>toby.matejovsky@gmail.com</author-email>
  <author-id type="integer">1</author-id>
  <author-name>Toby Matejovsky</author-name>
  <committer-date type="datetime">2010-05-26T17:22:11Z</committer-date>
  <committer-email>toby.matejovsky@gmail.com</committer-email>
  <committer-id type="integer">1</committer-id>
  <committer-name>Toby Matejovsky</committer-name>
  <created-at type="datetime">2010-05-26T17:22:11Z</created-at>
  <id type="integer">3564</id>
  <message>Story:434927 Implement awesome feature</message>
  <repository-id type="integer">6</repository-id>
  <revision>4f657b17281aaae24284bfd15e47f9c279049f9b</revision>
</changeset>
EOF

  xml
  end

  # This is the data that Unfuddle POSTs to the repository callback URL, but contains no Story ID in the commit message
  def bad_changeset
    xml =<<EOF
<?xml version="1.0" encoding="UTF-8"?>
<changeset>
  <author-date type="datetime">2010-05-26T17:22:11Z</author-date>
  <author-email>toby.matejovsky@gmail.com</author-email>
  <author-id type="integer">1</author-id>
  <author-name>Toby Matejovsky</author-name>
  <committer-date type="datetime">2010-05-26T17:22:11Z</committer-date>
  <committer-email>toby.matejovsky@gmail.com</committer-email>
  <committer-id type="integer">1</committer-id>
  <committer-name>Toby Matejovsky</committer-name>
  <created-at type="datetime">2010-05-26T17:22:11Z</created-at>
  <id type="integer">3564</id>
  <message>Implement awesome feature but forgot to mention Story ID</message>
  <repository-id type="integer">6</repository-id>
  <revision>4f657b17281aaae24284bfd15e47f9c279049f9b</revision>
</changeset>
EOF

  xml
  end
end
