class Item < ApplicationRecord
  enum kind: {expenses: 1, income: 2 }
end
