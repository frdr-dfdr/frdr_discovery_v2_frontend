module GeodisyHelper
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
      currentDoc.issued = get_full_issued_date(document.fetch(:dct_issued_s, ''))
    else
      currentDoc.issued = document.fetch(:dct_issued_s, '')
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

end
