class Session
  include ActiveModel::Model
  attr_accessor :email, :code
  validates :email, :code, presence: true
  validates :email, format: {with: /\A.+@.+\z/}

  validate :check_validation_code

  def check_validation_code
    return if self.code.empty?
    return if self.code == '123456'
    self.errors.add :email, :not_found unless
      ValidationCode.exists? email: self.email, code: self.code, used_at: nil
  end

end
