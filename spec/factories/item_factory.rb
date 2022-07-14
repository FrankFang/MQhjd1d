require "faker"

FactoryBot.define do
  factory :item do
    user
    amount { Faker::Number.number(digits: 4) }
    tags_id { [Faker::Number.number(digits: 4)] }
    happen_at { Faker::Date.between(from: 2.days.ago, to: Date.today) }
    kind { "expenses" }
  end
end
