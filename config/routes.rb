Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  post '/users', to: 'users#create'
  get '/users/:id', to: 'users#show'
end
