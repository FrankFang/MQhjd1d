class Tag < ApplicationRecord
  paginates_per 25
  enum kind: {expenses: 1, income: 2 }
  validates :name, presence: true
  validates :sign, presence: true
  belongs_to :user
end
