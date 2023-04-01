require 'rspec_api_documentation'

RspecApiDocumentation.configure do |config|
  config.request_body_formatter = :json
  config.api_name = "山竹记账 API 文档"
  config.api_explanation = <<EOF
  <style>
    strong {color: #f60;}
    code {font-family: Consolas, monospace;}
  </style>
  <h2>注意事项</h2>
  <ol>
    <li>
      happen_at 全都应该重命名为 happen<strong>ed</strong>_at （目前会同时输出这两个字段）
    </li>
    <li>
      happen_after 参数全都应该重命名为 happen<strong>ed</strong>_after（happen_before 同理）
    </li>
    <li>
      表单错误时，后端会返回
        <pre><code>{
  "errors": {
    "field": ["中文报错"]
  }
}</code></pre>
      前端可以把这个错误信息直接展示给用户
    </li>
  </ol>

EOF
end
RSpec.configure do |config|
  config.before(:each) do |spec|
    if spec.metadata[:type].equal? :acceptance
      header 'Accept', 'application/json'
      header 'Content-Type', 'application/json'
    end
  end
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
  config.shared_context_metadata_behavior = :apply_to_host_groups
end
