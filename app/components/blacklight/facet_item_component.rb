# frozen_string_literal: true

module Blacklight
  class FacetItemComponent < ::ViewComponent::Base
    with_collection_parameter :facet_item

    def initialize(facet_item:, wrapping_element: 'li', suppress_link: false)
      @facet_item = facet_item
      @label = facet_item.label
      @hits = facet_item.hits
      @href = facet_item.href
      @selected = facet_item.selected?
      @wrapping_element = wrapping_element
      @suppress_link = suppress_link
    end

    def call
      # if the downstream app has overridden the helper methods we'd usually call,
      # use the helpers to preserve compatibility
      content = if overridden_helper_methods?
                  content_from_legacy_view_helper
                elsif @selected
                  render_selected_facet_value
                else
                  render_facet_value
                end

      return if content.blank?
      return content unless @wrapping_element

      content_tag @wrapping_element, content
    end

    # This is a little shim to let us call the render methods below outside the
    # usual component rendering cycle (for backward compatibility)
    # @private
    # @deprecated
    def with_view_context(view_context)
      @view_context = view_context
      self
    end

    # Check if the downstream application has overridden these methods
    # @deprecated
    # @private
    def overridden_helper_methods?
      return false if explicit_component_configuration?

      @view_context.method(:render_facet_item).owner != Blacklight::FacetsHelperBehavior ||
        @view_context.method(:render_facet_value).owner != Blacklight::FacetsHelperBehavior ||
        @view_context.method(:render_selected_facet_value).owner != Blacklight::FacetsHelperBehavior
    end

    # Call out to the helper method equivalent of this component
    # @deprecated
    # @private
    def content_from_legacy_view_helper
      Deprecation.warn('Calling out to the #render_facet_item helper for backwards compatibility.')
      Deprecation.silence(Blacklight::FacetsHelperBehavior) do
        @view_context.render_facet_item(@facet_item.facet_field, @facet_item.facet_item)
      end
    end

    ##
    # Standard display of a facet value in a list. Used in both _facets sidebar
    # partial and catalog/facet expanded list. Will output facet value name as
    # a link to add that to your restrictions, with count in parens.
    #
    # @param [Blacklight::Solr::Response::Facets::FacetField] facet_field
    # @param [Blacklight::Solr::Response::Facets::FacetItem] item
    # @param [Hash] options
    # @option options [Boolean] :suppress_link display the facet, but don't link to it
    # @return [String]
    # @private
    def render_facet_value
      content_tag(:span) do
        if not @suppress_link
          link_to(@href, class: "facet-select render-facet-value") do
            label_tag(@label, class: "facet-label") do
              concat check_box_tag(@label, @label, false, class: "facet-checkbox", :onclick => 'location.href="' + @href + '"')
              concat @label
            end
          end
        else
          @label
        end
      end + render_facet_count
    end

    ##
    # Standard display of a SELECTED facet value (e.g. without a link and with a remove button)
    # @see #render_facet_value
    # @param [Blacklight::Solr::Response::Facets::FacetField] facet_field
    # @param [String] item
    # @private
    def render_selected_facet_value
      content_tag(:span) do
        link_to(@href) do
          label_tag(@label, class: "facet-label") do
            concat check_box_tag(@label, @label, true, class: "facet-checkbox", :onclick => 'location.href="' + @href + '"')
            concat @label
          end
        end
      end + render_facet_count(classes: [""])
    end

    ##
    # Renders a count value for facet limits. Can be over-ridden locally
    # to change style. And can be called by plugins to get consistent display.
    #
    # @param [Integer] num number of facet results
    # @param [Hash] options
    # @option options [Array<String>]  an array of classes to add to count span.
    # @return [String]
    # @private
    def render_facet_count(options = {})
      return @view_context.render_facet_count(@hits, options) unless @view_context.method(:render_facet_count).owner == Blacklight::FacetsHelperBehavior || explicit_component_configuration?

      classes = (options[:classes] || []) << "facet-count"
      content_tag("span", t('blacklight.search.facets.count', number: number_with_delimiter(@hits)), class: classes)
    end

    private

    def explicit_component_configuration?
      @facet_item.facet_config.item_component.present?
    end
  end
end
