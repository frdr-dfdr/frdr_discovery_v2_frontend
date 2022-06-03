# frozen_string_literal: true
module Blacklight
  module GlobusSearch
    # autoload :Document, 'blacklight/solr/document'
    autoload :FacetPaginator, 'blacklight/globus_search/facet_paginator'
    autoload :Repository, 'blacklight/globus_search/repository'
    autoload :Request, 'blacklight/globus_search/request'
    autoload :Response, 'blacklight/globus_search/response'
    # autoload :SearchBuilderBehavior, 'blacklight/solr/search_builder_behavior'
  end
end
