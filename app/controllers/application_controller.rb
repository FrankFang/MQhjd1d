class ApplicationController < ActionController::API
  def datetime_with_zone(str)
    return nil if str.nil?
    Time.zone.parse(str)
  end
end
