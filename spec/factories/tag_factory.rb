require "faker"

FactoryBot.define do
  factory :tag do
    name { Faker::Lorem.word }
    sign { Faker::Lorem.multibyte }
    kind { "expenses" }
    user
  end
end
