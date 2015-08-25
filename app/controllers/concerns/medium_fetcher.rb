##
# Позволяет получать media проект различными методами
#
module MediumFetcher
  attr_reader :medium

  def fetch_non_restricted_medium
    @medium = Medium.find_by(uniqid: params[:medium_id])
    if @medium.blank? || @medium.restricted?
      render(nothing: true, status: 403) and return false
    end
  end

  def fetch_medium
    @medium = Medium.find_by(uniqid: params[:medium_id])
    if @medium.blank?
      render(nothing: true, status: 403) and return false
    end
  end
end
