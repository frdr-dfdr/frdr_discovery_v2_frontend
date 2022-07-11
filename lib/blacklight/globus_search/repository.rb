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
      # Need to figure out if we need suggestions
      puts "suggestions called"
      #suggest_results = connection.send_and_receive(suggest_handler_path, params: request_params)
      #Blacklight::Suggest::Response.new suggest_results, request_params, suggest_handler_path, suggester_name
      nil
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
      puts "ping called"
      #response = connection.send_and_receive 'admin/ping', {}
      #Blacklight.logger&.info("Ping [#{connection.uri}] returned: '#{response['status']}'")
      #response['status'] == "OK"
    end

    private

    ##
    # @return [String]
    def suggest_handler_path
      puts "suggest_handler_path called"
      blacklight_config.autocomplete_path
    end

    def suggester_name
      puts "suggester_name called"
      blacklight_config.autocomplete_suggester
    end

  end
end
