class Tag < ApplicationRecord
  validates :name, presence: true
  validates :sign, presence: true
  belongs_to :user
end
