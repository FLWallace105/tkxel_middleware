class ApplicationMailer < ActionMailer::Base
  default from: ENV['email_username']
  include ApplicationHelper
  layout 'mailer'
  add_template_helper(ApplicationHelper)
end
