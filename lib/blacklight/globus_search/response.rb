# frozen_string_literal: true
class Blacklight::GlobusSearch::Response < ActiveSupport::HashWithIndifferentAccess
  extend ActiveSupport::Autoload
  eager_autoload do
    autoload :PaginationMethods
    autoload :Response
    autoload :Spelling
    autoload :Facets
    autoload :MoreLikeThis
    autoload :GroupResponse
    autoload :Group
    autoload :Params
  end

  include PaginationMethods
  include Spelling
  include Facets
  include Response
  include MoreLikeThis
  include Params

  attr_reader :request_params
  attr_accessor :blacklight_config, :options

  def initialize(data, request_params, options = {})
    @request_params = ActiveSupport::HashWithIndifferentAccess.new(request_params)
    Blacklight.logger&.debug "Response init with #{data.to_json}"
    if data["@datatype"] == "GSearchResult"
      parsed_data = parse_search_result(data)
    elsif data["@datatype"] == "GMetaResult"
      parsed_data = parse_meta_result(data)
    else
      Blacklight.logger&.error "Unable to parse Globus Search result because its type #{data["@datatype"]} is not recognized. Full response was: #{data}"
      parsed_data = data
    end

    super(force_to_utf8(ActiveSupport::HashWithIndifferentAccess.new(parsed_data)))
    self.blacklight_config = options[:blacklight_config]
    self.options = options
  end

  def polygon_to_bbox(metadata)

    if metadata.nil? || metadata["geoLocationPolygon"].nil?
      return []
    end

    polygon = metadata["geoLocationPolygon"]
    coordinates = polygon["coordinates"]

    if coordinates.nil?
      return []
    end

    coordinates = coordinates[0] unless coordinates.length() < 1

    if coordinates.length() != 5
      return []
    end

    west = coordinates[0]
    east = coordinates[1]
    north = coordinates[2]
    south = coordinates[3]

    bbox = "ENVELOPE(#{coordinates[0][0]}, #{coordinates[2][0]}, #{coordinates[0][1]}, #{coordinates[2][1]})"
    bbox
  end

  def parse_meta_result(data)
    # Structure is:
    # entries => [] => content => metadata field key => value
    docs = []
    subject = data["subject"]
    data["entries"].each { |entry|
      content = entry["content"]
      # Replace the internal id with the subject from the Globus Search index
      content["layer_slug_s"] = subject
      # Replace globus search polygon coordinates with solr geom
      content["solr_geom"] = polygon_to_bbox(content)
      docs << content
    }
    parsed_data = {
      :response => {
        :docs => docs,
        :start => 0,
        :numFound => 1
      }
    }
    parsed_data
  end

  def get_facet_counts(data)
    facet_counts = {}
    data["facet_results"].each { | facet_result |
      counts = []
      facet_result["buckets"].each { | bucket |
        counts << bucket["value"]
        counts << bucket["count"]
      }
      facet_counts[facet_result["name"]] = counts
    } unless data["facet_results"].nil?

    request_params["parsed_filters"].each { | filter_key, filter_value |
      # If there is no count array create it.
      if !facet_counts.has_key?(filter_key)
        counts = []
      else
        counts = facet_counts[filter_key]
      end

      # For each of the selected filters if they are not present in the counts,
      # then add it with a zero count so that it shows up in the UI.
      filter_value.each { | value |
        if filter_value.is_a?(Array) && !counts.include?(value)
            counts << value
            counts << 0
        end
      }
      facet_counts[filter_key] = counts
    } if request_params.has_key?("parsed_filters")

    # Make sure every facet has at least one blank entry so it displays
    facet_counts.each { | filter_key, filter_values |
      if filter_values.nil?
        filter_values = []
      end
      if filter_values.length == 0
        # We found an empty facet so add an empty value
        filter_values << "none"
        filter_values << 0
      end
    }
    facet_counts
  end

  def parse_search_result(data)
    # Need to replace globus search coordinates with envelope
    docs = []
    # Structure is:
    # gmeta => [] => content => metadata field key => value
    data["gmeta"].each { |gmetaresult|
      subject = gmetaresult["subject"]
      gmetaresult["content"].each { |entry|
        # Replace the internal id with the subject from the Globus Search index
        entry["layer_slug_s"] = subject
        entry["solr_geom"] = polygon_to_bbox(entry)
        docs << entry
      }
    }
    parsed_data = {
        :response => {
          :docs => docs,
          :start => data["offset"],
          :numFound => data["total"]
        },

        :facet_counts => {
          :facet_fields => get_facet_counts(data)
        }
      }
    Blacklight.logger&.debug "Globus Search result parsed to Solr style response: #{parsed_data.to_json.to_s}"
    parsed_data
  end

  def header
    self['responseHeader'] || {}
  end

  def document_factory
    Blacklight::DocumentFactory
  end

  def documents
    @documents ||= (response['docs'] || []).collect { |doc| document_factory.build(doc, self, options) }
  end
  alias_method :docs, :documents

  def grouped
    @groups ||= self["grouped"].map do |field, group|
      # grouped responses can either be grouped by:
      #   - field, where this key is the field name, and there will be a list
      #        of documents grouped by field value, or:
      #   - function, where the key is the function, and the documents will be
      #        further grouped by function value, or:
      #   - query, where the key is the query, and the matching documents will be
      #        in the doclist on THIS object
      if group["groups"] # field or function
        GroupResponse.new field, group, self
      else # query
        Group.new field, group, self
      end
    end
  end

  def group key
    grouped.find { |x| x.key == key }
  end

  def grouped?
    key? "grouped"
  end

  def export_formats
    documents.map { |x| x.export_formats.keys }.flatten.uniq
  end

  private

  def force_to_utf8(value)
    case value
    when Hash
      value.each { |k, v| value[k] = force_to_utf8(v) }
    when Array
      value.each { |v| force_to_utf8(v) }
    when String
      if value.encoding != Encoding::UTF_8
        Blacklight.logger&.warn "Found a non utf-8 value in Blacklight::Solr::Response. \"#{value}\" Encoding is #{value.encoding}"
        value.dup.force_encoding('UTF-8')
      else
        value
      end
    end
    value
  end
end
