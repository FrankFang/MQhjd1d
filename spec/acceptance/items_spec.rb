require "rails_helper"
require "rspec_api_documentation/dsl"

resource "账目" do
  let(:current_user) { create :user }
  let(:auth) { "Bearer #{current_user.generate_jwt}" }
  get "/api/v1/items" do
    authentication :basic, :auth
    parameter :page, "页码"
    parameter :happened_after, "发生时间的起点"
    parameter :happened_before, "发生时间的终点"
    with_options :scope => :resources do
      response_field :id, "ID"
      response_field :amount, "金额（单位：分）"
    end
    let(:happened_after) { DateTime.now - 10.days }
    let(:happened_before) { DateTime.now }
    example "获取账目" do
      tag = create :tag, user: current_user
      create_list :item, Item.default_per_page - 3, tag_ids: [tag.id], user: current_user, happen_at: Time.now - 15.days
      create_list :item, 3, tag_ids: [tag.id], user: current_user, happen_at: Time.now - 5.days
      do_request
      expect(status).to eq 200
      json = JSON.parse response_body
      expect(json["resources"].size).to eq 3
    end
  end

  post "/api/v1/items" do
    authentication :basic, :auth
    parameter :amount, "金额（单位：分）", required: true
    parameter :kind, "类型", required: true, enum: ["expenses", "income"]
    parameter :happen_at, "发生时间", required: true
    parameter :tag_ids, "标签列表（只传ID）", required: true
    with_options :scope => :resource do
      response_field :id
      response_field :amount
      response_field :kind
      response_field :happen_at
      response_field :tag_ids
    end
    let(:amount) { 9900 }
    let(:kind) { "expenses" }
    let(:happen_at) { "2020-10-30T00:00:00+08:00" }
    let(:tags) { (0..1).map { create :tag, user: current_user } }
    let(:tag_ids) { tags.map(&:id) }
    let(:happen_at) { "2020-10-30T00:00:00+08:00" }
    example "创建账目" do
      do_request
      expect(status).to eq 200
      json = JSON.parse response_body
      expect(json["resource"]["amount"]).to eq amount
    end
  end

  delete "/api/v1/items/:id" do
    authentication :basic, :auth

    let (:item) { create :item, user: current_user }
    let (:id) { item.id }

    example "删除账目" do
      do_request
      expect(status).to eq 200
    end
  end

  get "/api/v1/items/summary" do
    authentication :basic, :auth
    parameter :happened_after, "时间起点", required: true
    parameter :happened_before, "时间终点", required: true
    parameter :kind, "账目类型", enum: ["expenses", "income"], required: true
    parameter :group_by, "分组依据", enum: ["happen_at", "tag_id"], required: true
    response_field :groups, "分组信息"
    response_field :total, "总金额（单位：分）"
    let(:happened_after) { "2018-01-01" }
    let(:happened_before) { "2019-01-01" }
    let(:kind) { "expenses" }
    example "统计信息（按happened_at分组）" do
      user = current_user
      tag = create :tag, user: user
      create :item, amount: 100, kind: "expenses", tag_ids: [tag.id], happened_at: "2018-06-18T00:00:00+08:00", user: user
      create :item, amount: 200, kind: "expenses", tag_ids: [tag.id], happened_at: "2018-06-18T00:00:00+08:00", user: user
      create :item, amount: 100, kind: "expenses", tag_ids: [tag.id], happened_at: "2018-06-20T00:00:00+08:00", user: user
      create :item, amount: 200, kind: "expenses", tag_ids: [tag.id], happened_at: "2018-06-20T00:00:00+08:00", user: user
      create :item, amount: 100, kind: "expenses", tag_ids: [tag.id], happened_at: "2018-06-19T00:00:00+08:00", user: user
      create :item, amount: 200, kind: "expenses", tag_ids: [tag.id], happened_at: "2018-06-19T00:00:00+08:00", user: user
      do_request group_by: "happened_at"
      expect(status).to eq 200
      json = JSON.parse response_body
      expect(json["groups"].size).to eq 3
      expect(json["groups"][0]["happened_at"]).to eq "2018-06-18"
      expect(json["groups"][0]["amount"]).to eq 300
      expect(json["groups"][1]["happened_at"]).to eq "2018-06-19"
      expect(json["groups"][1]["amount"]).to eq 300
      expect(json["groups"][2]["happened_at"]).to eq "2018-06-20"
      expect(json["groups"][2]["amount"]).to eq 300
      expect(json["total"]).to eq 900
    end
    example "统计信息（按happen_at分组）" do
      user = current_user
      tag = create :tag, user: user
      create :item, amount: 100, kind: "expenses", tag_ids: [tag.id], happened_at: "2018-06-18T00:00:00+08:00", user: user
      create :item, amount: 200, kind: "expenses", tag_ids: [tag.id], happened_at: "2018-06-18T00:00:00+08:00", user: user
      create :item, amount: 100, kind: "expenses", tag_ids: [tag.id], happened_at: "2018-06-20T00:00:00+08:00", user: user
      create :item, amount: 200, kind: "expenses", tag_ids: [tag.id], happened_at: "2018-06-20T00:00:00+08:00", user: user
      create :item, amount: 100, kind: "expenses", tag_ids: [tag.id], happened_at: "2018-06-19T00:00:00+08:00", user: user
      create :item, amount: 200, kind: "expenses", tag_ids: [tag.id], happened_at: "2018-06-19T00:00:00+08:00", user: user
      do_request group_by: "happen_at"
      expect(status).to eq 200
      json = JSON.parse response_body
      expect(json["groups"].size).to eq 3
      expect(json["groups"][0]["happen_at"]).to eq "2018-06-20"
      expect(json["groups"][0]["amount"]).to eq 300
      expect(json["groups"][1]["happen_at"]).to eq "2018-06-19"
      expect(json["groups"][1]["amount"]).to eq 300
      expect(json["groups"][2]["happen_at"]).to eq "2018-06-18"
      expect(json["groups"][2]["amount"]).to eq 300
      expect(json["total"]).to eq 900
    end

    example "统计信息（按tag_id分组）" do
      user = current_user
      tag1 = create :tag, user: user
      tag2 = create :tag, user: user
      tag3 = create :tag, user: user
      create :item, amount: 100, kind: "expenses", tag_ids: [tag1.id, tag2.id], happen_at: "2018-06-18T00:00:00+08:00", user: user
      create :item, amount: 200, kind: "expenses", tag_ids: [tag2.id, tag3.id], happen_at: "2018-06-18T00:00:00+08:00", user: user
      create :item, amount: 300, kind: "expenses", tag_ids: [tag3.id, tag1.id], happen_at: "2018-06-18T00:00:00+08:00", user: user
      do_request group_by: "tag_id"
      expect(status).to eq 200
      json = JSON.parse response_body
      expect(json["groups"].size).to eq 3
      expect(json["groups"][0]["tag_id"]).to eq tag3.id
      expect(json["groups"][0]["amount"]).to eq 500
      expect(json["groups"][1]["tag_id"]).to eq tag1.id
      expect(json["groups"][1]["amount"]).to eq 400
      expect(json["groups"][2]["tag_id"]).to eq tag2.id
      expect(json["groups"][2]["amount"]).to eq 300
      expect(json["total"]).to eq 600
    end
  end

  get "/api/v1/items/balance" do
    authentication :basic, :auth
    parameter :happened_after, "时间起点", required: true
    parameter :happened_before, "时间终点", required: true
    response_field :balance, "净收入（单位：分）"
    response_field :expenses, "支出（单位：分）"
    response_field :income, "收入（单位：分）"
    let(:happened_after) { "2018-01-01" }
    let(:happened_before) { "2019-01-01" }
    example "获取收支信息" do
      user = current_user
      tag = create :tag, user: user
      create :item, amount: 100, kind: "expenses", tag_ids: [tag.id], happen_at: "2017-06-18T00:00:00+08:00", user: user

      create :item, amount: 100, kind: "expenses", tag_ids: [tag.id], happen_at: "2018-06-18T00:00:00+08:00", user: user
      create :item, amount: 100, kind: "expenses", tag_ids: [tag.id], happen_at: "2018-06-18T00:00:00+08:00", user: user
      create :item, amount: 100, kind: "expenses", tag_ids: [tag.id], happen_at: "2018-06-18T00:00:00+08:00", user: user
      create :item, amount: 100, kind: "expenses", tag_ids: [tag.id], happen_at: "2018-06-18T00:00:00+08:00", user: user
      create :item, amount: 200, kind: "income", tag_ids: [tag.id], happen_at: "2018-06-18T00:00:00+08:00", user: user
      create :item, amount: 200, kind: "income", tag_ids: [tag.id], happen_at: "2018-06-18T00:00:00+08:00", user: user
      do_request
      expect(status).to eq 200
      json = JSON.parse response_body
      expect(json["balance"]).to eq 0
      expect(json["expenses"]).to eq 400
      expect(json["income"]).to eq 400
    end
  end
end
