# frozen_string_literal: true
module Blacklight::GlobusSearch
  class Repository < Blacklight::AbstractRepository
    ##
    # Find a single solr document result (by id) using the document configuration
    # @param [String] id document's unique key value
    # @param [Hash] params additional solr query parameters
    def find id, params = {}
      #doc_params = params.reverse_merge(blacklight_config.default_document_solr_params)
      #                   .reverse_merge(qt: blacklight_config.document_solr_request_handler)
      #                   .merge(blacklight_config.document_unique_id_param => id)

      #solr_response = send_and_receive blacklight_config.document_solr_path || blacklight_config.solr_path, doc_params
      #raise Blacklight::Exceptions::RecordNotFound if solr_response.documents.empty?

      #solr_response
      nil
    end

    ##
    # Execute a search query against solr
    # @param [Hash] params solr query parameters
    def search params = {}
      # send_and_receive blacklight_config.solr_path, params.reverse_merge(qt: blacklight_config.qt)
      nil
    end

    # @param [Hash] request_params
    # @return [Blacklight::Suggest::Response]
    def suggestions(request_params)
      #suggest_results = connection.send_and_receive(suggest_handler_path, params: request_params)
      #Blacklight::Suggest::Response.new suggest_results, request_params, suggest_handler_path, suggester_name
      nil
    end

    ##
    # Gets a list of available fields
    # @return [Hash]
    def reflect_fields
      # send_and_receive('admin/luke', params: { fl: '*', 'json.nl' => 'map' })['fields']
      nil
    end

    ##
    # @return [boolean] true if the repository is reachable
    def ping
      #response = connection.send_and_receive 'admin/ping', {}
      #Blacklight.logger&.info("Ping [#{connection.uri}] returned: '#{response['status']}'")
      #response['status'] == "OK"
    end

    ##
    # Execute a solr query
    # TODO: Make this private after we have a way to abstract admin/luke and ping
    # @see [RSolr::Client#send_and_receive]
    # @overload find(solr_path, params)
    #   Execute a solr query at the given path with the parameters
    #   @param [String] solr path (defaults to blacklight_config.solr_path)
    #   @param [Hash] parameters for RSolr::Client#send_and_receive
    # @overload find(params)
    #   @param [Hash] parameters for RSolr::Client#send_and_receive
    # @return [Blacklight::Solr::Response] the solr response object
    def send_and_receive(path, solr_params = {})
      #benchmark("Solr fetch", level: :debug) do
      #  res = connection.send_and_receive(path, build_solr_request(solr_params))
      #  solr_response = blacklight_config.response_model.new(res, solr_params, document_model: blacklight_config.document_model, blacklight_config: blacklight_config)

      #  Blacklight.logger&.debug("Solr query: #{blacklight_config.http_method} #{path} #{solr_params.to_hash.inspect}")
      #  Blacklight.logger&.debug("Solr response: #{solr_response.inspect}") if defined?(::BLACKLIGHT_VERBOSE_LOGGING) && ::BLACKLIGHT_VERBOSE_LOGGING
      #  solr_response
      #end
      #rescue *defined_rsolr_timeout_exceptions => e
      #  raise Blacklight::Exceptions::RepositoryTimeout, "Timeout connecting to Solr instance using #{connection.inspect}: #{e.inspect}"
      #rescue Errno::ECONNREFUSED => e
      #  # intended for and likely to be a RSolr::Error:ConnectionRefused, specifically.
      #  raise Blacklight::Exceptions::ECONNREFUSED, "Unable to connect to Solr instance using #{connection.inspect}: #{e.inspect}"
      #rescue RSolr::Error::Http => e
      #  raise Blacklight::Exceptions::InvalidRequest, e.message
      nil
    end

    # @return [Hash]
    # @!visibility private
    def build_solr_request(solr_params)
      #if solr_params[:json].present?
      #  {
      #    data: { params: solr_params.to_hash.except(:json) }.merge(solr_params[:json]).to_json,
      #    method: :post,
      #    headers: { 'Content-Type' => 'application/json' }
      #  }
      #else
      #  key = blacklight_config.http_method == :post ? :data : :params
      #  {
      #    key => solr_params.to_hash,
      #    method: blacklight_config.http_method
      #  }
      #end
      nil
    end

    private

    ##
    # @return [String]
    def suggest_handler_path
      blacklight_config.autocomplete_path
    end

    def suggester_name
      blacklight_config.autocomplete_suggester
    end

    def build_connection
      # RSolr.connect(connection_config.merge(adapter: connection_config[:http_adapter]))
      nil
    end

    # RSolr 2.4.0+ has a RSolr::Error::Timeout that we'd like to treat specially
    # instead of lumping into RSolr::Error::Http. Before that we can not rescue
    # specially, so return an empty array.
    #
    # @return [Array<Exception>] that can be used, with a splat, as argument
    #   to a ruby rescue
    def defined_rsolr_timeout_exceptions
      #if defined?(RSolr::Error::Timeout)
      #  [RSolr::Error::Timeout]
      #else
      #  []
      #end
    end
  end
end
