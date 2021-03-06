require 'test_helper'

class ProjectTest < ActiveSupport::TestCase

  def setup
    @user = User.new(name: "Test User", email: "test_user@ema.il", password: "123qwehello123harder", password_confirmation: "123qwehello123harder")
    @user.save!
    @project = @user.projects.build(name: "Test project", systems_description: "Lorem ipsum")
  end

  test "should be valid" do
    assert @project.valid?
  end

  test "user id should be present" do
    @project.user_id = nil
    assert_not @project.valid?
  end

  test "extracting subsystems from description" do
    @project.systems_description = """ # Open BSD stuff
OpenBSD
gcc # the default compiler

# I am a comment
#another comment
cyberdiode
 perl module
"""
    assert @project.systems == ["OpenBSD", "gcc", "cyberdiode", "perl module"]
  end

  test "extracting subsystems from description with commas" do
    @project.systems_description = """ # Open BSD stuff
OpenBSD
 gcc # the default compiler

# I am a comment
#another comment
	  cyberdiode
 perl module

Ubuntu  Linux, Wireshark
"""
    assert @project.systems == ["OpenBSD", "gcc", "cyberdiode", "perl module", "Ubuntu Linux", "Wireshark"]
  end

  

end
