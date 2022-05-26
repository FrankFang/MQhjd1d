class ValidationCode < ApplicationRecord
  validates :email, presence: true
  
  before_create :generate_code
  after_create :send_email

  enum kind: { sign_in: 0, reset_password: 1 }

  def generate_code
    self.code = SecureRandom.random_number.to_s[2..7]
  end
  def send_email
    UserMailer.welcome_email(self.email)
  end
end
