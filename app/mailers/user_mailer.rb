class UserMailer < ApplicationMailer
  def welcome_email(code)
    @code = code
    mail(to: "fangyinghang@foxmail.com", subject: 'hi')
  end
end
