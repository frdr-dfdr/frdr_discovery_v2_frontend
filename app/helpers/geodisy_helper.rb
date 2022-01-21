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

  def get_document_bibtex(document)
    currentDoc = BibTeX::Entry.new({
      :bibtex_type => :misc,
      :bibtex_key => :currentDoc})
    currentDoc.author = document.fetch('dc_creator_sm', nil).join(' and ') if document.has?('dc_creator_sm')
    currentDoc.title = document.fetch('dc_title_s') if document.has?('dc_title_s')
    currentDoc.issued = document.fetch('dct_issued_s') if document.has?('dc_issued_s')
    currentDoc.howpublished ='{\\url{' + document.fetch('dc_identifier_s') + '}}' if document.has?('dc_identifier_s')

    bib = BibTeX::Bibliography.new
    bib << currentDoc
    return bib
  end

  def get_apa_citation(document)
    bib = get_document_bibtex(document)
    cp = CiteProc::Processor.new style: 'apa', format: 'html'
    cp.register bib[:currentDoc].to_citeproc
    return cp.render :bibliography, id: 'currentDoc'
  end
end
