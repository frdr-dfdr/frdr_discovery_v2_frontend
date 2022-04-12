# frozen_string_literal: true
module Geodisy
  class ShowPresenter < Blacklight::ShowPresenter

    # Shows the current locale's title, fallback to a non locale title and then the other locale
    # @return [String]
    def html_title
      f = get_locale_title()
      field_value(f)
    end

    # Shows the current locale's title, fallback to a non locale title and then the other locale
    def heading
      f = get_locale_title()
      field_value(f, except_operations: [Blacklight::Rendering::HelperMethod])
   end

    def get_locale_title
      if I18n.locale == :fr then
        # Try to use fr, then generic title, then en then id
        fields = [:dc_title_fr_s, "dc_title_s", "dc_title_en_s", configuration.document_model.unique_key]
      else
        # Try to use en, then generic title, then fr then id
        fields = [:dc_title_en_s, "dc_title_s", "dc_title_fr_s", configuration.document_model.unique_key]
      end
      f = fields.lazy.map { |field| field_config(field) }.detect { |field_config| field_presenter(field_config).any? }
      return f
    end


  end
end
