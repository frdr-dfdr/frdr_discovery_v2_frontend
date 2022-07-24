module GeodisyHelper
  include Blacklight::UrlHelperBehavior

  ##
  # Selects the basemap used for map displays
  # @return [String]
  def geoblacklight_basemap
    if I18n.locale == :fr then
      return "OpenStreetMap_France"
    else
      return "Esri_WorldTopoMap"
    end
  end

  def render_references_url_with_icon(args)
    if args[:document]&.references&.url
      link_to (fa_icon "external-link", text: args[:document].references.url.endpoint, right: true), args[:document].references.url.endpoint
    end
  end

  def date_matches?( str, format="%Y-%m-%d" )
    Date.strptime(str,format) rescue false
  end

  # Makes sure the issued date has Y-M-D as ruby
  # fails to parse if it is missing the month or day
  def get_full_issued_date(input_date)
    # We are missing the day in the date
    if date_matches? input_date, "%Y-%m"
      return input_date + "-01"
    # We are missing the day and month in the date
    elsif date_matches? input_date, "%Y"
      return input_date + "-01-01"
    else
      return input_date
    end
  end

  def get_document_bibtex(document, full_date=false)
    currentDoc = BibTeX::Entry.new({
      :bibtex_type => :misc,
      :bibtex_key => :currentDoc})
    currentDoc.author = document.fetch(:dc_creator_sm, []).join(' and ')
    currentDoc.title = document.fetch(:dc_title_s, '')
    if full_date
      currentDoc.issued = get_full_issued_date(document.fetch(:dct_issued_s, '')) if document.has?(:dct_issued_s)
    else
      currentDoc.issued = document.fetch(:dct_issued_s, '') if document.has?(:dct_issued_s)
    end
    currentDoc.howpublished ='{\\url{' + document.fetch(:dc_identifier_s) + '}}' if document.has?(:dc_identifier_s)

    bib = BibTeX::Bibliography.new
    bib << currentDoc
    return bib
  end

  def get_apa_citation(document)
    # Pass full date as true as CiteProc needs Y-M-D or gives an error parsing
    bib = get_document_bibtex(document, true)
    cp = CiteProc::Processor.new style: 'apa', format: 'html'
    item = CiteProc::Item.new(bib[:currentDoc].to_citeproc)
    cp << item
    return cp.render :bibliography, id: :currentDoc
  end

  # Add fields you want to show up as additional metadata to the following list
  @@additional_metadata = [Settings.FIELDS.AFFILIATION, Settings.FIELDS.CONTRIBUTOR, Settings.FIELDS.PUBLISHER, Settings.FIELDS.SERIES]
  def is_additional_metadata? field_name
    @@additional_metadata.include? field_name
  end

  # Determines user locale and if a field is an english or french and does/n't match
  def is_locale_for_metadata? field_name
    if I18n.locale == :en
      !field_name.include? "_fr_"
    else
      !field_name.include? "_en_"
    end
  end

  # Helper for add show fields to render each value as its own separate div
  def render_value_as_divs(args)
    content_tag :div do
      args[:value].collect { |value| concat content_tag(:div, value) }
    end
  end

  # Try to get the correct title for the current locale, fallback to others
  def get_locale_title(blacklight_config, document)
    if I18n.locale == :fr then
      # Try to use fr, then generic title, then en then id
      fields = [:dc_title_fr_s, "dc_title_s", "dc_title_en_s", blacklight_config.document_model.unique_key]
    else
      # Try to use en, then generic title, then fr then id
      fields = [:dc_title_en_s, "dc_title_s", "dc_title_fr_s", blacklight_config.document_model.unique_key]
    end
    f = fields.find { |field| document.key?(field) }
    return document[f]
  end

  def get_title_url(document)
    return url_for_document(document)
  end

  def get_title_opts(doc, counter)
    opts = { counter: counter }
    return document_link_params(doc, opts)
  end

  # Change repository name to match icon files stored as assets
  def get_safe_repo_name(name)
    safe = name.downcase
    safe = safe.delete('()')
    safe = safe.gsub(' ', '+')
    return safe
  end

  def main_content_classes
    'index-main col-xl-9'
  end

  def sidebar_classes
    'page-sidebar col-xl-3'
  end

  def has_active_facet? fields, response
      facets_from_request(fields, response).any? { |display_facet| facet_field_in_params?(display_facet.name) }
  end

  def get_search_details(controller)
    search = controller.view_context.search_state.query_param()
    filters = controller.view_context.search_state.filter_params()
    details = []

    details.append(search.to_s.strip) unless search.to_s.strip.empty?

    filters.each do | key, values |
      filter = "("
      filter += I18n.t("blacklight.search.facets.details." + key) + ": "
      filter += values.join(", ") if values.is_a?(Array)
      filter += values if values.is_a?(String)
      filter += ")"
      details.append(filter)
    end

    details.join(" AND ")
  end

  # A helper function for clear all button that removes all of the filters
  # and filter search terms in URL format preserving the search state otherwise.
  def url_no_facets(view_context, field_names)
    # Remove the filters
    no_filters = view_context.search_state.params.except(:f)
    # Remove search terms for filters
    query = no_filters[:q]
    field_names.each { | field_name |
      query = remove_search_filter(query, field_name)
    }
    no_filters[:q] = query
    view_context.search_action_path(view_context.search_state.reset(no_filters))
  end

  # Remove a search to limit results based on a filter
  def remove_search_filter(q, field_name)
    if q.nil? || q.empty?
      q
    end
    # Handle the case where there is an AND in front of the search filter.
    # We want to remove the AND with white space around it as well as the search filter
    additional_search_regex = Regexp.new('[\s]+[Aa][Nn][Dd][\s]+' + get_search_filter_regex(field_name))

    # Handle the case where the search filter is first or the only part of the query and doesn't start with an AND.
    front_or_single_regex = Regexp.new(get_search_filter_regex(field_name))

    if (q.match(additional_search_regex))
      q = q.sub(additional_search_regex, "")
    elsif (q.match(front_or_single_regex))
      q = q.sub(front_or_single_regex, "")
    end

    # Remove any left over white space
    q = q.strip

    # Remove a possible leading AND now that we have removed the search filter
    if (q.match(/\A[Aa][Nn][Dd][\s]+/))
      q = q.sub(/\A[Aa][Nn][Dd][\s]+/, "")
    end

    return q
  end

  def date_published_parse(params)
    full = params.dig(:f, Settings.FIELDS.DATE_PUBLISHED)
    if full.nil? || full.empty?
      return ["", ""]
    end
    full = full[0] if full.is_a?(Array)
    full = full.split("to")
    full
  end

  def add_empty_date_published_filter(params)
    if params.nil?
      return {}
    end
    with_date = params.clone
    if with_date[:f].nil?
      with_date[:f] = {}
    end
    if with_date[:f]["#{Settings.FIELDS.DATE_PUBLISHED}"].nil?
      with_date[:f]["#{Settings.FIELDS.DATE_PUBLISHED}"] = ''
    end
    with_date
  end

  def has_any_search_filter?(q, field_names)
    if q.nil? || q.empty?
      return false;
    end

    unless field_names.is_a?(Array)
      return false;
    else
      field_names.each { | field_name |
        if (has_search_filter?(q, field_name))
          return true;
        end
      }
      return false;
    end
  end

  def has_search_filter?(q, field_name)
    if q.nil? || q.empty?
      return false;
    end
    return q.match(get_search_filter_regex(field_name)) ? true : false
  end

  def get_search_filter(q, field_name)
    match_field = get_search_filter_regex(field_name)
    if q.nil? || q.empty? || !q.match?(match_field)
      return ""
    end

    return q.match(match_field)[1] || ""
  end

  def get_search_filter_regex(field_name)
    # This tries to match something like:
    # Arctic dct_provenance_s: (Polar*) AND dc_creator_sm: (David*)
    # So that we could remove the dct_provenance_s or dc_creator_sm value in the query
    # without losing the rest. I've tried to support every possible character available
    # within the parentheses including things like white spaces (\s) regular characters
    # (\w) or available special characters.
    return field_name + ':\\s*\\(([\\w\\s~`@#$%^&*-=+|\\[\\]{};\':",.<>\\/?]+)\\*\\)'
  end

end
