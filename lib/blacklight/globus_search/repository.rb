# frozen_string_literal: true

require "http"

module Blacklight::GlobusSearch
  class Repository < Blacklight::AbstractRepository

    ##
    # Find a single solr document result (by id) using the document configuration
    # @param [String] id document's unique key value
    # @param [Hash] params additional solr query parameters
    def find id, params = {}
      request = Request.new(connection_config[:url] + "/subject?subject=" + id)
      response = request.get()
      raise Blacklight::Exceptions::RecordNotFound if response.documents.empty?
      response
    end

    ##
    # Execute a search query against solr
    # @param [Hash] params solr query parameters
    def search params = {}
      request = Request.new(connection_config[:url] + "/search", params.reverse_merge(qt: blacklight_config.qt))
      response = request.post(params)
      response
    end

    # @param [Hash] request_params
    # @return [Blacklight::Suggest::Response]
    def suggestions(request_params)
      search_results = search(request_params)
      Suggest.new(search_results, request_params)
    end

    ##
    # Gets a list of available fields
    # @return [Hash]
    def reflect_fields
      puts "reflect_fields called"
      # send_and_receive('admin/luke', params: { fl: '*', 'json.nl' => 'map' })['fields']
      nil
    end

    ##
    # @return [boolean] true if the repository is reachable
    def ping
      response = search({q: "*"})
      response['status'].empty?
    end

  end
end
