# frozen_string_literal: true

module Blacklight
  module GlobusSearch
    class Suggest
        attr_reader :response, :request_params, :suggest_path, :suggester_name

        ##
        # Creates a suggest response
        # @param [RSolr::HashWithResponse] response
        # @param [Hash] request_params
        # @param [String] suggest_path
        # @param [String] suggester_name
        def initialize(response, request_params)
          @response = response
          @request_params = request_params
        end

        ##
        # Trys the suggester response to return suggestions if they are
        # present
        # @return [Array]
        def suggestions
          suggestions = []
          titles = []
          repositories = []
          creators = []
          response.dig(:response, :docs).each { | doc |
            titles << doc.dig(Settings.FIELDS.TITLE)

            repositories << doc.dig(Settings.FIELDS.PROVENANCE)

            creators << doc.dig(Settings.FIELDS.CREATOR)
          }
          titles.uniq!
          titles.each { | title |
            suggestions << { term: title, weight: 8, payload: "" } unless title.empty?
          }

          repositories.uniq!
          repositories.each { | provenance |
            suggestions << { term: provenance, weight: 6, payload: "" } unless provenance.empty?
          }

          creators.uniq!
          creators.each { | creator |
            suggestions << { term: creator, weight: 6, payload: "" } unless creator.empty?
          }
          suggestions
          # (response.dig(suggest_path, suggester_name, request_params[:q], 'suggestions') || []).uniq
        end
    end
  end
end
