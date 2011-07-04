require 'test_helper'

class NotificationMailerTest < ActionMailer::TestCase
  
  test "reset email" do
    user = users(:aaron)
    email = NotificationMailer.reset_notification(user).deliver
    assert !ActionMailer::Base.deliveries.empty?

    email = ActionMailer::Base.deliveries.last
  end

  test "server down email" do
    NotificationMailer.alert_service_down(monitor_users(:one),
        incidents).deliver
    assert !ActionMailer::Base.deliveries.empty?

    email = ActionMailer::Base.deliveries.last
  end

end
