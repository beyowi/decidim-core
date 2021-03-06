# frozen_string_literal: true

module Decidim
  class StaticMapController < Decidim::ApplicationController
    skip_before_action :store_current_location

    def show
      send_data StaticMapGenerator.new(resource).data, type: "image/jpeg", disposition: "inline"
    end

    private

    def resource
      @resource ||= GlobalID::Locator.locate_signed params[:sgid]
    end
  end
end
