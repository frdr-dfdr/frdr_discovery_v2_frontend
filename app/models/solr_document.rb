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
    fetch(Settings.FIELDS.BBOXES, '').length() > 0
  end

  def bboxes
    get_bboxes
  end

  def has_line?
    fetch(Settings.FIELDS.LINES, '').length() > 0
  end

  def lines
    get_lines
  end

  def has_point?
    fetch(Settings.FIELDS.POINTS, '').length() > 0
  end

  def points
    get_points
  end

  def has_polygon?
    fetch(Settings.FIELDS.POLYGONS, '').length() > 0
  end

  def polygons
    get_polygons
  end
  def get_bboxes
         bs = fetch(Settings.FIELDS.BBOXES, '')
         array = []
         for b in bs do
             bjson = JSON.parse(b)

             if bjson["bbox_type"] == "bounding box" || bjson["bbox_type"] == "file"
                  #other = bjson.key?("other") ? bjson["other"] : ""
                  #country = bjson.key?("country") ? bjson["country"] : ""
                  #province = bjson.key?("province") ? bjson["province"] : ""
                  #city = bjson.key?("city") ? bjson["city"] : ""
                  other = bjson.fetch("other", "")
                  country = bjson.fetch("country", "")
                  province = bjson.fetch("province", "")
                  city = bjson.fetch("city","")
                  file_name = bjson.fetch("file_name", "")
                  if !file_name.empty?
                    array.push(file_name)
                  elsif other.empty? && country.empty? && province.empty? && city.empty?
                    array.push(bjson.fetch("north", "failed to grab north") + ", " + bjson.fetch("west", "failed to grab west") + ", " + bjson.fetch("south", "failed to grab south") + ', ' + bjson.fetch("east", "failed to grab east"))
                  else
                    answer = ""
                    if !other.empty?
                        answer = other
                    end
                    if !city.empty?
                        if !answer.empty?
                            answer += "; " + city
                        else
                            answer = city
                        end
                    end
                    if !province.empty?
                        if !answer.empty?
                            answer += "; " + province
                        else
                            answer = province
                        end
                    end
                    if !country.empty?
                        if !answer.empty?
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

  def get_lines
    ls = fetch(Settings.FIELDS.LINES, '')
         array = []
         for l in ls do
             answer = ""
             ljson = JSON.parse(l)
             for p in ljson
                 if !answer.empty?
                    answer += ", "
                 end
                 answer += p.to_s
             end
             array.push(answer)
         end
    return answer
    #return ljson
  end

  def get_polygons
    ps = fetch(Settings.FIELDS.POLYGONS, '')
        array = []
        for p in ps do
            answer = ""
            pjson = JSON.parse(p)
            first = ""
            last = ""
            for pt in pjson
                if first.to_s.empty?
                    first = pt
                end
                if !answer.empty?
                   answer += ", "
                end
                answer += pt.to_s
                last = pt
            end
            if last != first
                answer += ", " + first.to_s
            end
            array.push(answer)
        end
    return ps
  end

  def get_points
    fetch(Settings.FIELDS.POINTS, '')
  end

end


