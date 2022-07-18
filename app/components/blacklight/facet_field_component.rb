# frozen_string_literal: true

module Blacklight
  class FacetFieldComponent < ::ViewComponent::Base
    include Blacklight::ContentAreasShim

    renders_one :label
    renders_one :body

    def initialize(facet_field:)
      @facet_field = facet_field
    end

    def url_clear_facet(all_params, field_field_key)
      other_params = all_params.except(:f)
      other_params.merge(:f => all_params[:f].except(field_field_key))
    end
  end
end
