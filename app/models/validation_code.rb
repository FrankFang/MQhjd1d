class ValidationCode < ApplicationRecord
  validates :email, presence: true
end
