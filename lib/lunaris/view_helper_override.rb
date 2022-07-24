module Lunaris
  module ViewHelperOverride
    include CatalogHelperOverride

    def date_parameters?
      params[:to] || params[:from]
    end

    def spatial_parameters?
      params[:bbox]
    end

    # Overrides BL method to enable results for spatial only params
    def has_search_parameters?
      puts "Lunaris has_search_parameters"
      date_parameters? || spatial_parameters? || super
    end

    def query_has_constraints?(localized_params = params)
      puts "Lunaris query_has_constraints"
      has_search_parameters? || super(localized_params)
    end

    def render_search_to_s(params)
      puts "Lunaris render_search_to_s"
      super + render_search_to_s_param(params, 'bbox', 'geoblacklight.bbox_label') + render_search_to_s_param(params, 'to', 'geoblacklight.to_label') + render_search_to_s_param(params, 'from', 'geoblacklight.from_label')
    end

    def render_search_to_s_param(params, name, label)
      puts "Lunaris render_search_to_s_param"
      return ''.html_safe if params[name].blank?
      render_search_to_s_element(t(label), render_filter_value(params[name]))
    end

    def render_constraints_filters(localized_params = params)
      puts "Lunaris render_constraints_filters"
      content = super(localized_params)
      localized_params = localized_params.to_unsafe_h if localized_params.respond_to?(:to_unsafe_h)

      if localized_params[:bbox]
        path = search_action_path(remove_spatial_filter_group(:bbox, localized_params))
        content << render_constraint_element(t('geoblacklight.bbox_label'),
                                             localized_params[:bbox], remove: path)
      end

      if localized_params[:to]
        path = search_action_path(remove_spatial_filter_group(:to, localized_params))
        content << render_constraint_element(t('geoblacklight.to_label'),
                                             localized_params[:to], remove: path)
      end

      if localized_params[:from]
        path = search_action_path(remove_spatial_filter_group(:from, localized_params))
        content << render_constraint_element(t('geoblacklight.from_label'),
                                             localized_params[:from], remove: path)
      end

      content
    end
  end
end
