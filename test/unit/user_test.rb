require File.dirname(__FILE__) + '/../test_helper'

class UserTest < ActiveSupport::TestCase

  def test_should_create_user
    assert_difference 'User.count' do
      user = create_user
      assert !user.new_record?, "#{user.errors.full_messages.to_sentence}"
    end
  end

  def test_should_require_password
    assert_no_difference 'User.count' do
      u = create_user(:password => nil)
      assert u.errors[:password].size > 0
    end
  end

  def test_should_require_password_confirmation
    assert_no_difference 'User.count' do
      u = create_user(:password_confirmation => nil)
      assert u.errors[:password_confirmation].size > 0
    end
  end

  def test_should_require_email
    assert_no_difference 'User.count' do
      u = create_user(:email => nil)
      assert u.errors[:email].size > 0
    end
  end

  def test_should_reset_password
    users(:ianpurton).update_attributes(:password => 'new password', :password_confirmation => 'new password')
    assert_equal users(:ianpurton), User.authenticate('ianpurton', 'new password')
  end

  def test_should_not_rehash_password
    users(:ianpurton).update_attributes(:login => 'ianpurton2')
    assert_equal users(:ianpurton), User.authenticate('ianpurton2', 'vja481x')
  end

  def test_should_authenticate_user
    assert_equal users(:ianpurton), User.authenticate('ianpurton', 'vja481x')
  end

  def test_should_set_remember_token
    users(:ianpurton).remember_me
    assert_not_nil users(:ianpurton).remember_token
    assert_not_nil users(:ianpurton).remember_token_expires_at
  end

  def test_should_unset_remember_token
    users(:ianpurton).remember_me
    assert_not_nil users(:ianpurton).remember_token
    users(:ianpurton).forget_me
    assert_nil users(:ianpurton).remember_token
  end

  def test_should_remember_me_for_one_week
    before = 1.week.from_now.utc
    users(:ianpurton).remember_me_for 1.week
    after = 1.week.from_now.utc
    assert_not_nil users(:ianpurton).remember_token
    assert_not_nil users(:ianpurton).remember_token_expires_at
    assert users(:ianpurton).remember_token_expires_at.between?(before, after)
  end

  def test_should_remember_me_until_one_week
    time = 1.week.from_now.utc
    users(:ianpurton).remember_me_until time
    assert_not_nil users(:ianpurton).remember_token
    assert_not_nil users(:ianpurton).remember_token_expires_at
    assert_equal users(:ianpurton).remember_token_expires_at, time
  end

  def test_should_remember_me_default_two_weeks
    before = 2.weeks.from_now.utc
    users(:ianpurton).remember_me
    after = 2.weeks.from_now.utc
    assert_not_nil users(:ianpurton).remember_token
    assert_not_nil users(:ianpurton).remember_token_expires_at
    assert users(:ianpurton).remember_token_expires_at.between?(before, after)
  end

protected
  def create_user(options = {})
    record = User.new({ :first_name => 'Ian', :last_name => 'Purton', :login => 'quire', 
      :mobile_number => '',
      :email => 'quire@example.com', :password => 'quire69', 
      :password_confirmation => 'quire69' }.merge(options))
    record.save
    record
  end
end
