class Tag < ApplicationRecord
  paginates_per 25
  enum kind: {expenses: 1, income: 2 }
  validates :name, presence: true
  validates :name, length: { maximum: 4 }
  validates :sign, presence: true
  validates :kind, presence: true
  belongs_to :user
  def self.default_scope
    where(deleted_at: nil)
  end
end
