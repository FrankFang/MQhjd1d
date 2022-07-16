require "rails_helper"

RSpec.describe "Items", type: :request do
  describe "获取账目" do
    it "分页，未登录" do
      create_list :item, 11, amount: 100
      create_list :item, 11, amount: 100
      get "/api/v1/items"
      expect(response).to have_http_status 401
    end
    it "分页" do
      user = create :user
      items = create_list :item, Item.default_per_page+1, user: user
      create_list :item, 11

      get "/api/v1/items", headers: items.first.user.generate_auth_header
      expect(response).to have_http_status 200
      json = JSON.parse(response.body)
      expect(json["resources"].size).to eq Item.default_per_page
      expect(json["resources"][0]["tags"].size).to eq 1
      get "/api/v1/items?page=2", headers: items.first.user.generate_auth_header
      expect(response).to have_http_status 200
      json = JSON.parse(response.body)
      expect(json["resources"].size).to eq 1
    end
    it "按时间筛选" do
      user1 = create :user
      item1 = create :item, happen_at: "2018-01-02", user: user1
      item2 = create :item, happen_at: "2018-01-02", user: user1
      item3 = create :item, happen_at: "2019-01-01", user: user1

      get "/api/v1/items?happen_after=2018-01-01&happen_before=2018-01-03",
        headers: user1.generate_auth_header
      expect(response).to have_http_status 200
      json = JSON.parse(response.body)
      expect(json["resources"].size).to eq 2
      expect(json["resources"][0]["id"]).to eq item1.id
      expect(json["resources"][1]["id"]).to eq item2.id
    end
    it "按时间筛选（边界条件）" do
      item1 = create :item, happen_at: "2018-01-01"

      get "/api/v1/items?created_after=2018-01-01&created_before=2018-01-02",
        headers: item1.user.generate_auth_header
      expect(response).to have_http_status 200
      json = JSON.parse(response.body)
      expect(json["resources"].size).to eq 1
      expect(json["resources"][0]["id"]).to eq item1.id
    end
    it "按时间筛选（边界条件2）" do
      item1 = create :item, happen_at: "2018-01-01"
      item2 = create :item, happen_at: "2017-01-01", user: item1.user
      get "/api/v1/items?happen_after=2018-01-01",
        headers: item1.user.generate_auth_header
      expect(response).to have_http_status 200
      json = JSON.parse(response.body)
      expect(json["resources"].size).to eq 1
      expect(json["resources"][0]["id"]).to eq item1.id
    end
    it "按时间筛选（边界条件3）" do
      user1 = create :user
      item1 = create :item, happen_at: "2018-01-01", user: user1
      item2 = create :item, happen_at: "2019-01-01", user: user1

      get "/api/v1/items?happen_before=2018-01-02",
        headers: user1.generate_auth_header
      expect(response).to have_http_status 200
      json = JSON.parse(response.body)
      expect(json["resources"].size).to eq 1
      expect(json["resources"][0]["id"]).to eq item1.id
    end
    it "按 kind 筛选" do
      user = create :user
      create :item, kind: 'income', amount: 200, user: user
      create :item, kind: 'expenses', amount: 100, user: user

      get "/api/v1/items?kind=income", headers: user.generate_auth_header
      expect(response).to have_http_status 200
      json = JSON.parse(response.body)
      expect(json["resources"].size).to eq 1
      expect(json["resources"][0]["amount"]).to eq 200
    end
  end
  describe "创建账目" do
    it "未登录创建" do
      post "/api/v1/items", params: { amount: 100 }
      expect(response).to have_http_status 401
    end
    it "登录后创建" do
      user = create :user
      tag1 = create :tag, user: user
      tag2 = create :tag, user: user
      expect {
        post "/api/v1/items", params: { amount: 99, tag_ids: [tag1.id, tag2.id],
                                        happen_at: "2018-01-01T00:00:00+08:00",
                                        kind: 'income' },
                              headers: user.generate_auth_header
      }.to change { Item.count }.by 1
      expect(response).to have_http_status 200
      json = JSON.parse response.body
      expect(json["resource"]["id"]).to be_an(Numeric)
      expect(json["resource"]["amount"]).to eq 99
      expect(json["resource"]["user_id"]).to eq user.id
      expect(json["resource"]["happen_at"]).to eq "2017-12-31T16:00:00.000Z"
      expect(json["resource"]["kind"]).to eq "income"
    end
    it "创建时 amount、tag_ids、happen_at 必填" do
      user = create :user
      post "/api/v1/items", params: {}, headers: user.generate_auth_header
      expect(response).to have_http_status 422
      json = JSON.parse response.body
      expect(json["errors"]["amount"][0]).to be_a String
      expect(json["errors"]["tag_ids"][0]).to be_a String
      expect(json["errors"]["happen_at"][0]).to be_a String
    end
  end
  describe "获取余额" do
    it "未登录" do
      get "/api/v1/items/balance?happen_after=2018-01-01&happen_before=2019-01-01"
      expect(response).to have_http_status 401
    end
    it "登录" do
      user = create :user
      create :item, user: user, kind: 'expenses', amount: 100, happen_at: '2018-03-02T16:00:00.000Z'
      create :item, user: user, kind: 'expenses', amount: 200, happen_at: '2018-03-02T16:00:00.000Z'
      create :item, user: user, kind: 'income', amount: 100, happen_at: '2018-03-02T16:00:00.000Z'
      create :item, user: user, kind: 'income', amount: 200, happen_at: '2018-03-02T16:00:00.000Z'

      get "/api/v1/items/balance?happen_after=2018-03-02T15:00:00.000Z&happen_before=2018-03-02T17:00:00.000Z", headers: user.generate_auth_header
      expect(response).to have_http_status 200
      json = JSON.parse(response.body)
      expect(json["income"]).to eq 300
      expect(json["expenses"]).to eq 300
      expect(json["balance"]).to eq 0
    end
  end
  describe "统计数据" do
    it "按天分组" do
      user = create :user
      create :item, amount: 100, kind: "expenses", happen_at: "2018-06-18T00:00:00+08:00", user: user
      create :item, amount: 200, kind: "expenses", happen_at: "2018-06-18T00:00:00+08:00", user: user
      create :item, amount: 100, kind: "expenses", happen_at: "2018-06-20T00:00:00+08:00", user: user
      create :item, amount: 200, kind: "expenses", happen_at: "2018-06-20T00:00:00+08:00", user: user
      create :item, amount: 100, kind: "expenses", happen_at: "2018-06-19T00:00:00+08:00", user: user
      create :item, amount: 200, kind: "expenses", happen_at: "2018-06-19T00:00:00+08:00", user: user
      get "/api/v1/items/summary", params: {
                                     happened_after: "2018-01-01",
                                     happened_before: "2019-01-01",
                                     kind: "expenses",
                                     group_by: "happen_at",
                                   }, headers: user.generate_auth_header
      expect(response).to have_http_status 200
      json = JSON.parse response.body
      expect(json["groups"].size).to eq 3
      expect(json["groups"][0]["happen_at"]).to eq "2018-06-18"
      expect(json["groups"][0]["amount"]).to eq 300
      expect(json["groups"][1]["happen_at"]).to eq "2018-06-19"
      expect(json["groups"][1]["amount"]).to eq 300
      expect(json["groups"][2]["happen_at"]).to eq "2018-06-20"
      expect(json["groups"][2]["amount"]).to eq 300
      expect(json["total"]).to eq 900
    end
    it "按标签ID分组" do
      user = create :user
      tag1 = create :tag, user: user
      tag2 = create :tag, user: user
      tag3 = create :tag, user: user
      create :item, amount: 100, kind: "expenses", tag_ids: [tag1.id, tag2.id], happen_at: "2018-06-18T00:00:00+08:00", user: user
      create :item, amount: 200, kind: "expenses", tag_ids: [tag2.id, tag3.id], happen_at: "2018-06-18T00:00:00+08:00", user: user
      create :item, amount: 300, kind: "expenses", tag_ids: [tag3.id, tag1.id], happen_at: "2018-06-18T00:00:00+08:00", user: user
      get "/api/v1/items/summary", params: {
                                     happened_after: "2018-01-01",
                                     happened_before: "2019-01-01",
                                     kind: "expenses",
                                     group_by: "tag_id",
                                   }, headers: user.generate_auth_header
      expect(response).to have_http_status 200
      json = JSON.parse response.body
      expect(json["groups"].size).to eq 3
      expect(json["groups"][0]["tag_id"]).to eq tag3.id
      expect(json["groups"][0]["tag"]["name"]).to eq tag3.name
      expect(json["groups"][0]["amount"]).to eq 500
      expect(json["groups"][1]["tag_id"]).to eq tag1.id
      expect(json["groups"][1]["tag"]["name"]).to eq tag1.name
      expect(json["groups"][1]["amount"]).to eq 400
      expect(json["groups"][2]["tag_id"]).to eq tag2.id
      expect(json["groups"][2]["tag"]["name"]).to eq tag2.name
      expect(json["groups"][2]["amount"]).to eq 300
      expect(json["total"]).to eq 600
    end
  end
end
