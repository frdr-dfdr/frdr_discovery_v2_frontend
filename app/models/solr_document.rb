require 'json'
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

  def bboxes
    @bboxes
  end

  def has_line?
    @lines.length() > 0
  end

  def lines
    @lines
  end

  def has_point?
    @points.length() > 0
  end

  def points
    @points
  end

  def has_polygon?
    @polygons.length() > 0
  end

  def polygons
    @polygons
  end
  def get_bboxes
         bs = fetch(Settings.FIELDS.BBOXES, '')
         array = []
         for b in bs do
             bjson = JSON.parse(b)

             if bjson["bbox_type"] == "bounding box"
                  #other = bjson.key?("other") ? bjson["other"] : ""
                  #country = bjson.key?("country") ? bjson["country"] : ""
                  #province = bjson.key?("province") ? bjson["province"] : ""
                  #city = bjson.key?("city") ? bjson["city"] : ""
                  other = bjson.fetch(:other, "")
                  country = bjson.fetch(:country, "")
                  province = bjson.fetch(:province, "")
                  city = bjson.fetch(:city,"")
                  if other == "" && country == "" && province == "" && city == ""
                    array.push(bjson.fetch(:north, "a") + ", " + bjson.fetch(:west, "b") + ", " + bjson.fetch(:south, "c") + ', ' + bjson.fetch(:east, "d"))
                  else
                    answer = ""
                    if other != ""
                        answer = other
                    end
                    if city!= ""
                        if answer = other
                            answer += "; " + city
                        else
                            answer = city
                        end
                    end
                    if province != ""
                        if answer != ""
                            answer += "; " + province
                        else
                            answer = province
                        end
                    end
                    if country != ""
                        if answer != ""
                            answer += "; " + country
                        else
                            answer = country
                        end
                    end
                    array.push(answer)
                  end
             end
         end
         return array
  end

end


