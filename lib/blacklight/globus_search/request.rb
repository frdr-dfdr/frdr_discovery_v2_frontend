# frozen_string_literal: true

module Blacklight::GlobusSearch
  class Request < ActiveSupport::HashWithIndifferentAccess

    @@base = "https://search.api.globus.org/v1/index/ecfd43ee-165f-47be-b82e-2a9e496f0264"

    def initialize(path, constructor = {})
      @path = path
      if constructor.is_a?(Hash)
        super()
        update(constructor)
      else
        super(constructor)
      end
    end

    def send_and_receive()
        puts "send_and_receive called"
        http_response = HTTP.get(@@base + @path, :params => {:q => "*"})
        puts http_response.parse
        puts http_response.code
        Response.new(http_response.parse, self)
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
