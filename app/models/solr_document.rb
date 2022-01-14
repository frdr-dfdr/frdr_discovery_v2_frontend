# frozen_string_literal: true
class SolrDocument
  include Blacklight::Solr::Document
  include Geoblacklight::SolrDocument

  def initialize(source_doc = {}, response = nil)
    super(source_doc, response)
    @bboxes = ['Stanley Park; Vancouver; British Columbia; Canada', '123.72, 49.195, -123.020, 49.315']
    @lines = ['123,45, 49.195, -123.45, 49.195', '123.72, 49.195, -123.020, 49.315']
    @points = ['123.72,49.50']
    @polygons = ['123,45, 49.195, 92.321, 35.323, 87.232, 23.231, -123.45, 49.195', '123.72, 49.195, -123.020, 49.315, 122.12, 87.321']
  end

  # self.unique_key = 'id'
  self.unique_key = 'layer_slug_s'

  # Email uses the semantic field mappings below to generate the body of an email.
  SolrDocument.use_extension(Blacklight::Document::Email)

  # SMS uses the semantic field mappings below to generate the body of an SMS email.
  SolrDocument.use_extension(Blacklight::Document::Sms)

  # DublinCore uses the semantic field mappings below to assemble an OAI-compliant Dublin Core document
  # Semantic mappings of solr stored fields. Fields may be multi or
  # single valued. See Blacklight::Document::SemanticFields#field_semantics
  # and Blacklight::Document::SemanticFields#to_semantic_values
  # Recommendation: Use field names from Dublin Core
  use_extension(Blacklight::Document::DublinCore)

  def has_bbox?
    @bboxes.length() > 0
  end

  def bbox_all_id
    'bbox-all'
  end

  def bbox_prefix
    'bbox-'
  end

  def bboxes
    @bboxes
  end

  def has_line?
    @lines.length() > 0
  end

  def line_all_id
    'line-all'
  end

  def line_prefix
    'line-'
  end

  def lines
    @lines
  end

  def has_point?
    @points.length() > 0
  end

  def point_all_id
    'point-all'
  end

  def point_prefix
    'point-'
  end

  def points
    @points
  end

  def has_polygon?
    @polygons.length() > 0
  end

  def polygon_all_id
    'polygon-all'
  end

  def polygon_prefix
    'polygon-'
  end

  def polygons
    @polygons
  end

end
