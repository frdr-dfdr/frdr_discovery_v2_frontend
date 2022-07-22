# frozen_string_literal: true
require 'json'

module Blacklight::GlobusSearch
  class Request < ActiveSupport::HashWithIndifferentAccess

    # Field name => amount to boost search by for field
    @@boosts = {
      "dc_title_multi" => 8,
      "dc_title_en" => 6,
      "dc_title_fr" => 6,
      "frdr_subject_multi" => 4,
      "frdr_subject_en" => 3,
      "frdr_subject_fr" => 3,
      "dc_description_multi" => 3,
      "dc_description_en" => 2,
      "dc_description_fr" => 2
    }

    @@default_facet_limit = 10

    def initialize(path, constructor = {})
      @path = path
      if constructor.is_a?(Hash)
        super()
        update(constructor)
      else
        super(constructor)
      end
    end

    def get(params = {})
        Blacklight.logger&.debug "Get called to globus search index: #{@path} and params #{params}"
        http_response = HTTP.get(@path, params)
        Response.new(http_response.parse, self)
    end

    def generate_boosts(field_boosts = {})
      boosts = []
      field_boosts.each { | field_name, boost_value |
        boost = {
          "@datatype": "GBoost",
          "@version": "2017-09-01",
          "field_name": field_name,
          "factor": boost_value
        }
        boosts << boost
      } unless field_boosts.nil?
      boosts
    end

    def generate_facets(field_limits = {})
      facets = []
      field_limits.each { | field_name, limit |
        facet = {
          "@datatype": "GFacet",
          "@version": "2017-09-01",
          "type": "terms",
          "field_name": field_name
        }
        if field_name == Settings.FIELDS.DATE_PUBLISHED
          facet["type"] = "date_histogram"
          facet["date_interval"] = "year"
          facet.delete("size")
        else
          facet["size"] = limit
        end
        facets << facet
      } unless field_limits.nil?
      facets
    end

    # Need to add the from and to date filters if set in parameters
    def generate_filters(field_filters = {})
      filters = []
      field_filters.each { | field_name, values |
        if field_name != Settings.FIELDS.DATE_PUBLISHED
          filter = {
            "@datatype": "GFilter",
            "@version": "2017-09-01",
            "type": "match_any",
            "field_name": field_name,
            "values": values
          }
          filters << filter
        end
      } unless filters.nil?
      filters
    end

    def generate_sort(sort_params)
      sorting = []
      sort_params.each { | field, order |
        sort = {
          "@datatype":"GSort",
          "@version":"2017-09-01",
          "order": order,
          "field_name": field
        }
        sorting << sort
      } unless sort_params.nil?
      sorting
    end

    def generate_bbox_filters(search_params = {})
      filters = []
      search_params["fq"].each { | filter_text |
        if filter_text.include? "solr_geom"
          # Remove wrapper ENVELOPE(west, east, north, south)
          coordinates = filter_text.sub("solr_geom:\"Intersects(ENVELOPE(", "").sub("))\"", "")
          # Make individual coordinates
          coordinates = coordinates.split(",")

          west = coordinates[0]
          east = coordinates[1]
          north = coordinates[2]
          south = coordinates[3]

          filter = {
            "type": "geo_bounding_box",
            "field_name": "geoLocationPolygon",
            "top_left": {
              "lat": north.strip,
              "lon": west.strip
            },
            "bottom_right": {
              "lat": south.strip,
              "lon": east.strip
            }
          }
          filters << filter
        end
      } unless search_params["fq"].nil?
      filters
    end

    def generate_date_filters(search_params = {})
      filters = []

      from = "*"
      to = "*"

      fromTo = search_params.dig(Settings.FIELDS.DATE_PUBLISHED)
      fromTo = fromTo[0] if fromTo.is_a?(Array)
      fromTo = fromTo.split("to") unless fromTo.nil?

      from = fromTo[0] unless fromTo.nil? || fromTo[0].nil? || fromTo[0].empty?
      to = fromTo[1] unless fromTo.nil? || fromTo[1].nil? || fromTo[1].empty?

      filter = {
        "@datatype": "GFilter",
        "@version": "2017-09-01",
        "type": "range",
        "field_name": Settings.FIELDS.DATE_PUBLISHED,
        "values": [
          {
            "from": from,
            "to": to
          }
        ]
      }
      filters << filter
      filters
    end

    def parse_filters(search_params = {})
      filters = {}
      search_params["fq"].each { | filter_text |
        if filter_text.include? "{!term f="
          filter_text = filter_text.sub("{!term f=", "")
          split_filter = filter_text.split("}")
          field_name = split_filter[0]
          value = split_filter[1]
          current_values = filters[field_name]
          filters[field_name] = [] if filters[field_name].nil?
          filters[field_name] << value
        end
      } unless search_params["fq"].nil?
      filters
    end

    def parse_facets(search_params = {})
      facets = {}
      search_params["facet.field"].each { | field |
        facets[field] = search_params["f.#{field}.facet.limit"] || @@default_facet_limit
      } unless search_params["facet.field"].nil?
      facets
    end

    def parse_sort(search_params = {})
      sort = {}
      if search_params.nil? || search_params["sort"].nil? || search_params["sort"].include?("score desc")
        return sort
      end
      search_params["sort"].split(",").each { | sort_text |
        parts = sort_text.split(" ")
        field = parts[0]
        order = parts[1]
        sort[field] = order
      }
      sort
    end

    def post(params = {})
      search_params = params.to_hash

      advanced = true
      query = search_params[:q]&.strip || "*"
      offset = search_params["start"] || 0
      limit = search_params["rows"] || 20
      parsed_filters = parse_filters(search_params)
      self["parsed_filters"] = parsed_filters
      filters = generate_filters(parsed_filters)
      filters = filters + generate_bbox_filters(search_params) + generate_date_filters(parsed_filters)

      facets = parse_facets(search_params)
      sort = parse_sort(search_params)

      payload = {
        "@datatype": "GSearchRequest",
        "@version": "2017-09-01",
        "result_format_version": "2017-09-01",
        "advanced": advanced,
        "limit": limit,
        "offset": offset,
        "q": query,
        "filters": filters,
        "facets": generate_facets(facets),
        "boosts": generate_boosts(@@boosts),
        sort: generate_sort(sort)
      }

      Blacklight.logger&.debug "Post called Globus Search index #{@path} and payload #{payload.to_json}"
      http_response = HTTP.headers("Content-Type" => "application/json").post(@path, :body => payload.to_json)
      Response.new(http_response.parse, request_params=self)
    end

    def append_query(query)
      if self['q'] || dig(:json, :query, :bool)
        self[:json] ||= { query: { bool: { must: [] } } }
        self[:json][:query] ||= { bool: { must: [] } }
        self[:json][:query][:bool][:must] << query

        if self['q']
          self[:json][:query][:bool][:must] << self['q']
          delete 'q'
        end
      else
        self['q'] = query
      end
    end

    def append_boolean_query(bool_operator, query)
      return if query.blank?

      self[:json] ||= { query: { bool: { bool_operator => [] } } }
      self[:json][:query] ||= { bool: { bool_operator => [] } }
      self[:json][:query][:bool][bool_operator] ||= []

      if self['q']
        self[:json][:query][:bool][:must] ||= []
        self[:json][:query][:bool][:must] << self['q']
        delete 'q'
      end

      self[:json][:query][:bool][bool_operator] << query
    end

    def append_filter_query(query)
      self['fq'] ||= []
      self['fq'] = Array(self['fq']) if self['fq'].is_a? String

      self['fq'] << query
    end

    def append_facet_fields(values)
      self['facet.field'] ||= []
      self['facet.field'] += Array(values)
    end

    def append_facet_query(values)
      self['facet.query'] ||= []
      self['facet.query'] += Array(values)
    end

    def append_facet_pivot(query)
      self['facet.pivot'] ||= []
      self['facet.pivot'] << query
    end

    def append_highlight_field(query)
      self['hl.fl'] ||= []
      self['hl.fl'] << query
    end
  end
end
