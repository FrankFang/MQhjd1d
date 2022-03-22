class HomeController < ApplicationController
  def index
    render json: {
      message: "Welcome!"
    }
  end
end
