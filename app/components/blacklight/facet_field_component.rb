# frozen_string_literal: true
require "geodisy_helper"

module Blacklight
  class FacetFieldComponent < ::ViewComponent::Base
    include Blacklight::ContentAreasShim
    include GeodisyHelper

    renders_one :label
    renders_one :body

    def initialize(facet_field:)
      @facet_field = facet_field
    end

    def url_clear_facet(all_params, field_key)
      other_params = all_params.except(:f)
      other_params = other_params.merge(:f => all_params[:f].except(field_key)) unless all_params[:f].nil?
      other_params[:q] = remove_search_filter(other_params[:q], field_key)
      other_params
    end
  end
end
