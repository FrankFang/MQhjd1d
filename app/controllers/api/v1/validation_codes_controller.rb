class Api::V1::ValidationCodesController < ApplicationController
  def create
    if ValidationCode.exists?(email: params[:email], kind:'sign_in',created_at: 3.seconds.ago..Time.now)
      render status: :too_many_requests
      return
    end
    validation_code = ValidationCode.new email: params[:email], kind: 'sign_in'
    if validation_code.save
      render status: 200
    else
      render json: {errors: validation_code.errors}, status: 422
    end
  end
end
