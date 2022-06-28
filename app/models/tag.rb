class Tag < ApplicationRecord
  enum kind: {expenses: 1, income: 2 }
  validates :name, presence: true
  validates :sign, presence: true
  belongs_to :user
end
