# -*- encoding : utf-8 -*-
require 'blacklight/catalog'

class CatalogController < ApplicationController

  include Blacklight::Catalog
  include GeodisyHelper

  configure_blacklight do |config|

    # Ensures that JSON representations of Solr Documents can be retrieved using
    # the path /catalog/:id/raw
    # Please see https://github.com/projectblacklight/blacklight/pull/2006/
    config.raw_endpoint.enabled = true

    ## Default parameters to send to solr for all search-like requests. See also SolrHelper#solr_search_params
    ## @see https://lucene.apache.org/solr/guide/6_6/common-query-parameters.html
    ## @see https://lucene.apache.org/solr/guide/6_6/the-dismax-query-parser.html#TheDisMaxQueryParser-Theq.altParameter
    config.default_solr_params = {
      start: 0,
      'q.alt' => '*:*'
    }

    ## Default rows returned from Solr
    ## @see https://lucene.apache.org/solr/guide/6_6/common-query-parameters.html
    config.default_per_page = 20

    ## Default parameters to send on single-document requests to Solr. These settings are the Blackligt defaults (see SolrHelper#solr_doc_params) or
    ## parameters included in the Blacklight-jetty document requestHandler.
    #
    config.default_document_solr_params = {
     :qt => 'document',
     :q => '{!raw f=layer_slug_s v=$id}'
    }


    # solr field configuration for search results/index views
    # config.index.show_link = 'title_display'
    # config.index.record_display_type = 'format'

    config.index.title_field = Settings.FIELDS.TITLE

    # solr field configuration for document/show views

    config.show.display_type_field = 'format'
    config.show.partials << 'show_default_viewer_container'
    config.show.partials << 'show_default_additional_metadata'

    ##
    # Configure the index document presenter.
    config.index.document_presenter_class = Geoblacklight::DocumentPresenter
    config.show.document_presenter_class = Geodisy::ShowPresenter

    # solr fields that will be treated as facets by the blacklight application
    #   The ordering of the field names is the order of the display
    #
    # Setting a limit will trigger Blacklight's 'more' facet values link.
    # * If left unset, then all facet values returned by solr will be displayed.
    # * If set to an integer, then "f.somefield.facet.limit" will be added to
    # solr request, with actual solr request being +1 your configured limit --
    # you configure the number of items you actually want _displayed_ in a page.
    # * If set to 'true', then no additional parameters will be sent to solr,
    # but any 'sniffed' request limit parameters will be used for paging, with
    # paging at requested limit -1. Can sniff from facet.limit or
    # f.specific_field.facet.limit solr request params. This 'true' config
    # can be used if you set limits in :default_solr_params, or as defaults
    # on the solr side in the request handler itself. Request handler defaults
    # sniffing requires solr requests to be made with "echoParams=all", for
    # app code to actually have it echo'd back to see it.
    #
    # :show may be set to false if you don't want the facet to be drawn in the
    # facet bar
    # config.add_facet_field 'format', :label => 'Format'
    # config.add_facet_field 'pub_date', :label => 'Publication Year', :single => true
    # config.add_facet_field 'subject_topic_facet', :label => 'Topic', :limit => 20
    # config.add_facet_field 'language_facet', :label => 'Language', :limit => true
    # config.add_facet_field 'lc_1letter_facet', :label => 'Call Number'
    # config.add_facet_field 'subject_geo_facet', :label => 'Region'
    # config.add_facet_field 'solr_bbox', :fq => "solr_bbox:IsWithin(-88,26,-79,36)", :label => 'Spatial'

    # config.add_facet_field 'example_pivot_field', :label => 'Pivot Field', :pivot => ['format', 'language_facet']

    # config.add_facet_field 'example_query_facet_field', :label => 'Publish Date', :query => {
    #    :years_5 => { :label => 'within 5 Years', :fq => "pub_date:[#{Time.now.year - 5 } TO *]" },
    #    :years_10 => { :label => 'within 10 Years', :fq => "pub_date:[#{Time.now.year - 10 } TO *]" },
    #    :years_25 => { :label => 'within 25 Years', :fq => "pub_date:[#{Time.now.year - 25 } TO *]" }
    # }

    config.add_facet_field Settings.FIELDS.PROVENANCE, label: 'Institution', limit: 8, partial: "lunaris_facet", collapse: false
    config.add_facet_field Settings.FIELDS.DATE_PUBLISHED, :label => 'Publication Date', limit: 10, partial: "lunaris_date_facet"
    config.add_facet_field Settings.FIELDS.CREATOR, :label => 'Author', limit: 8, partial: "lunaris_facet"
    config.add_facet_field Settings.FIELDS.RIGHTS, label: 'Access', limit: 8, partial: "lunaris_facet"

    # config.add_facet_field Settings.FIELDS.SUBJECT, :label => 'Subject', :limit => 8, partial: "lunaris_facet"

    # config.add_facet_field Settings.FIELDS.SPATIAL_COVERAGE, :label => 'Place', :limit => 8, partial: "lunaris_facet"
    # config.add_facet_field Settings.FIELDS.PART_OF, :label => 'Collection', :limit => 8, partial: "lunaris_facet"


    # config.add_facet_field Settings.FIELDS.GEOM_TYPE, label: 'Data type', limit: 8, partial: "lunaris_facet"
    # config.add_facet_field Settings.FIELDS.FILE_FORMAT, :label => 'Format', :limit => 8, partial: "lunaris_facet"

    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.add_facet_fields_to_solr_request!

    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display
    config.add_index_field Settings.FIELDS.PUBLISHER
    config.add_index_field Settings.FIELDS.CREATOR
    config.add_index_field Settings.FIELDS.YEAR



    # solr fields to be displayed in the show (single result) view
    #  The ordering of the field names is the order of the display
    #
    # item_prop: [String] property given to span with Schema.org item property
    # link_to_search: [Boolean] that can be passed to link to a facet search
    # helper_method: [Symbol] method that can be used to render the value

    # Add additional metadata fields first so they show up before the other locale values
    config.add_show_field Settings.FIELDS.AFFILIATION, label: 'Author Affiliation', itemprop: 'affiliation', helper_method: :render_value_as_divs
    config.add_show_field Settings.FIELDS.CONTRIBUTOR, label: 'Contributor(s)', itemprop: 'contributor'
    config.add_show_field Settings.FIELDS.PUBLISHER, label: 'Publisher', itemprop: 'publisher'
    config.add_show_field Settings.FIELDS.SERIES, label: 'Series', itemprop: 'series'

    config.add_show_field Settings.FIELDS.TITLE_EN, label: 'Title (EN)', itemprop: 'title'
    config.add_show_field Settings.FIELDS.TITLE_FR, label: 'Title (FR)', itemprop: 'title'
    config.add_show_field Settings.FIELDS.DATE_PUBLISHED, label: 'Date Published', itemprop: 'temporal'
    config.add_show_field Settings.FIELDS.PROVENANCE, label: 'Held by', link_to_facet: true
    config.add_show_field Settings.FIELDS.CREATOR, label: 'Author', itemprop: 'author', link_to_facet: true
    config.add_show_field Settings.FIELDS.DESCRIPTION, label: 'Description', itemprop: 'description', helper_method: :render_value_as_truncate_abstract
    config.add_show_field Settings.FIELDS.DESCRIPTION_EN, label: 'Description (EN)', itemprop: 'description', helper_method: :render_value_as_truncate_abstract
    config.add_show_field Settings.FIELDS.DESCRIPTION_FR, label: 'Description (FR)', itemprop: 'description', helper_method: :render_value_as_truncate_abstract
    config.add_show_field Settings.FIELDS.PART_OF, label: 'Collection', itemprop: 'isPartOf'
    config.add_show_field Settings.FIELDS.SPATIAL_COVERAGE, label: 'Place(s)', itemprop: 'spatial', link_to_facet: true
    config.add_show_field Settings.FIELDS.SUBJECT, label: 'Keywords', itemprop: 'keywords', link_to_facet: true
    config.add_show_field Settings.FIELDS.SUBJECT_EN, label: 'Keywords (EN)', itemprop: 'keywords', link_to_facet: true
    config.add_show_field Settings.FIELDS.SUBJECT_FR, label: 'Keywords (FR)', itemprop: 'keywords', link_to_facet: true

    config.add_show_field Settings.FIELDS.TEMPORAL, label: 'Year', itemprop: 'temporal'
    config.add_show_field(
      Settings.FIELDS.REFERENCES,
      label: 'URL',
      accessor: [:external_url],
      if: proc { |_, _, doc| doc.external_url },
      helper_method: :render_references_url_with_icon
    )

    config.add_show_field Settings.FIELDS.RIGHTS, label: 'Access', itemprop: 'rights'
    config.add_show_field Settings.FIELDS.RIGHTS_URI, label: 'Rights', itemprop: 'rights-uri'
    config.add_show_field Settings.FIELDS.BBOXES, label: 'Bounding Boxes'


    # "fielded" search configuration. Used by pulldown among other places.
    # For supported keys in hash, see rdoc for Blacklight::SearchFields
    #
    # Search fields will inherit the :qt solr request handler from
    # config[:default_solr_parameters], OR can specify a different one
    # with a :qt key/value. Below examples inherit, except for subject
    # that specifies the same :qt as default for our own internal
    # testing purposes.
    #
    # The :key is what will be used to identify this BL search field internally,
    # as well as in URLs -- so changing it after deployment may break bookmarked
    # urls.  A display label will be automatically calculated from the :key,
    # or can be specified manually to be different.

    # This one uses all the defaults set by the solr request handler. Which
    # solr request handler? The one set in config[:default_solr_parameters][:qt],
    # since we aren't specifying it otherwise.

    config.add_search_field 'all_fields', :label => 'All Fields'
    # config.add_search_field 'dc_title_ti', :label => 'Title'
    # config.add_search_field 'dc_description_ti', :label => 'Description'

    # Now we see how to over-ride Solr request handler defaults, in this
    # case for a BL "search field", which is really a dismax aggregate
    # of Solr search fields.

    # config.add_search_field('title') do |field|
    #   # solr_parameters hash are sent to Solr as ordinary url query params.
    #   field.solr_parameters = { :'spellcheck.dictionary' => 'title' }

    #   # :solr_local_parameters will be sent using Solr LocalParams
    #   # syntax, as eg {! qf=$title_qf }. This is neccesary to use
    #   # Solr parameter de-referencing like $title_qf.
    #   # See: http://wiki.apache.org/solr/LocalParams
    #   field.solr_local_parameters = {
    #     :qf => '$title_qf',
    #     :pf => '$title_pf'
    #   }
    # end

    # config.add_search_field('author') do |field|
    #   field.solr_parameters = { :'spellcheck.dictionary' => 'author' }
    #   field.solr_local_parameters = {
    #     :qf => '$author_qf',
    #     :pf => '$author_pf'
    #   }
    # end

    # # Specifying a :qt only to show it's possible, and so our internal automated
    # # tests can test it. In this case it's the same as
    # # config[:default_solr_parameters][:qt], so isn't actually neccesary.
    # config.add_search_field('subject') do |field|
    #   field.solr_parameters = { :'spellcheck.dictionary' => 'subject' }
    #   field.qt = 'search'
    #   field.solr_local_parameters = {
    #     :qf => '$subject_qf',
    #     :pf => '$subject_pf'
    #   }
    # end

    #  config.add_search_field('Institution') do |field|
    #   field.solr_parameters = { :'spellcheck.dictionary' => 'Institution' }
    #   field.solr_local_parameters = {
    #     :qf => '$Institution_qf',
    #     :pf => '$Institution_pf'
    #   }
    # end

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    config.add_sort_field 'score desc, dc_title_sort asc', :label => 'blacklight.search_fields.sort.relevancy'
    config.add_sort_field "#{Settings.FIELDS.DATE_PUBLISHED} desc, dc_title_sort asc", :label => 'geoblacklight.sort.publication_date_newest'
    config.add_sort_field "#{Settings.FIELDS.DATE_PUBLISHED} asc, dc_title_sort asc", :label => 'geoblacklight.sort.publication_date_oldest'
    config.add_sort_field 'dc_title_sort asc', :label =>  'geoblacklight.sort.title_a_z'
    config.add_sort_field 'dc_title_sort desc', :label => 'geoblacklight.sort.title_z_a'

    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 5

    # Nav actions from Blacklight
    config.add_nav_action(:search_history, partial: 'blacklight/nav/search_history')

    # Tools from Blacklight
    config.add_results_collection_tool(:sort_widget)

    # Custom tools for GeoBlacklight
    config.add_show_tools_partial :metadata, if: proc { |_context, _config, options| options[:document] && (Settings.METADATA_SHOWN & options[:document].references.refs.map(&:type).map(&:to_s)).any? }
    config.add_show_tools_partial :exports, partial: 'exports', if: proc { |_context, _config, options| options[:document] }
    config.add_show_tools_partial :data_dictionary, partial: 'data_dictionary', if: proc { |_context, _config, options| options[:document] }

    # Configure basemap provider for GeoBlacklight maps (uses https only basemap
    # providers with open licenses)
    # Valid basemaps include:
    # 'positron'
    # 'darkMatter'
    # 'positronLite'
    # 'worldAntique'
    # 'worldEco'
    # 'flatBlue'
    # 'midnightCommander'

    config.basemap_provider = 'Esri_WorldTopoMap'


    # Configuration for autocomplete suggestor
    config.autocomplete_enabled = true
    config.autocomplete_path = 'suggest'
  end

  def download_bibtex
    solr_response = search_service.fetch params[:id]
    document = solr_response&.first()&.documents&.first()
    bibtex = get_document_bibtex document
    filename = document.fetch(:dc_title_s, "new_reference")
    filename = filename.parameterize(separator: '_') + ".bib"
    send_data bibtex.to_s, :type => 'text/plain; charset=UTF-8', :filename => filename, :disposition => :attachment
  end

end
