require "faker"

FactoryBot.define do
  factory :item do
    user
    amount { Faker::Number.number(digits: 4) }
    tag_ids { [(create(:tag, user: user)).id] }
    happen_at { Faker::Date.between(from: 2.days.ago, to: Date.today) }
    kind { "expenses" }
  end
end
