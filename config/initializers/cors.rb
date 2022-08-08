# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin AJAX requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins {true} # 相当于 '*'，但比 * 更好用，因为这样写返回的是请求的域名，而不是 '*'
    resource '*',
        methods: [:get, :post, :delete, :patch, :options, :head],
        headers: :any,
        expose: ['*', 'Authorization'],
        max_age: 600
  end
end
