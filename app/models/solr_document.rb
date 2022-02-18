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
    geo_objects.get("bboxes").get("checkboxes").length() > 0
  end

  def bboxes
    geo_objects.get("bboxes").get("data")
  end

  def has_line?
    geo_objects.get("lines").get("checkboxes").length() > 0
  end

  def lines
    geo_objects.get("lines").get("data")
  end

  def has_point?
    geo_objects.get("points").get("checkboxes").length() > 0
  end

  def points
    geo_objects.get("points").get("data")
  end

  def has_polygon?
    geo_objects.get("polygons").get("checkboxes").length() > 0
  end

  def polygons
    geo_objects.get("polygons").get("data")
  end
  def get_bboxes
    arrays_bs = []
    bs = fetch(Settings.FIELDS.BBOXES, '')
    bbox_map = Hash.new
    for b in bs do
        answer_bb = []
        answer_bb_str = ""
        bjson = JSON.parse(b)
        west = bjson.fetch("west", "")
        east = bjson.fetch("east", "")
        north = bjson.fetch("north", "")
        south = bjson.fetch("south", "")
        point_nw = [north,west]
        point_se = [south,east]
        answer_bb.push(point_nw)
        answer_bb.push(point_se)

        other = bjson.fetch("other", "")
        country = bjson.fetch("country", "")
        province = bjson.fetch("province", "")
        city = bjson.fetch("city","")
        file_name = bjson.fetch("file_name", "")
        if !file_name.empty?
            answer_bb_str = file_name
        elsif other.empty? && country.empty? && province.empty? && city.empty?
            answer_bb_str = north.to_s + ", " + west.to_s + ", " + south.to_s + ', ' + east.to_s
        else
            if !other.empty?
                answer_bb_str = other
            end
            if !city.empty?
                if !answer_bb_str.empty?
                    answer_bb_str += "; " + city
                else
                    answer_bb_str = city
                end
            end
            if !province.empty?
                if !answer_bb_str.empty?
                    answer_bb_str += "; " + province
                else
                    answer_bb_str = province
                end
            end
            if !country.empty?
                if !answer_bb_str.empty?
                    answer_bb_str += "; " + country
                else
                    answer_bb_str = country
                end
            end
        end
        bbox_map["data"] = answer_bb
        bbox_map["checkboxes"] = answer_bb_str
        arrays_bs.push(bbox_map)
    end
    return arrays_bs
  end

  def get_lines
    array_ls = []
    ls = fetch(Settings.FIELDS.LINES, '')
    for l in ls do
        ljson = JSON.parse(l)
        answer_str = "(" + ljson["lat1"].to_s + ", " + ljson["long1"].to_s + ") - (" + ljson["lat2"].to_s + ", " + ljson["long2"].to_s + ")"
        answer_ls = []
        line_pt_1 = []
        line_pt_2 = []
        line_pt_1.push(ljson["lat1"])
        line_pt_1.push(ljson["long1"])
        answer_ls.push(line_pt_1)
        line_pt_2.push(ljson["lat2"])
        line_pt_2.push(ljson["long2"])
        answer_ls.push(line_pt_2)
        line_map = Hash.new
        line_map["data"] = answer_ls
        line_map["checkboxes"] = answer_str
        array_ls.push(line_map)
        array_ls.push(answer)
    end
    return arrays_ls
  end

  def get_polygons
    arrays_pgs = []
    pgs = fetch(Settings.FIELDS.POLYGONS, '')
    for p in pgs do
        answer_pgs = []
        answer_pg_str = []
        point = []
        point_str = ""
        pjson = JSON.parse(p)
        first = ""
        last = ""
        for pt in pjson
            point_str = "(" + pt["lat"].to_s + ", " + pt["long"].to_s + ")"
            point.push(pt["lat"])
            point.push(pt["long"])
            if first.empty?
                first = point
                first_str = point_str
            end
            answer_pgs.push(point)
            last = point
            answer_pg_str.push(point)
            last_str = point_str
        end
        if last != first
            answer_pgs.push(first)
            answer_pg_str.push(first_str)
        end
        poly_map = Hash.new
        poly_map["data"] = answer_pgs
        poly_map["checkboxes"] = answer_pg_str
        arrays_pgs.push(poly_map)
    end
    return arrays_pgs
  end

  def get_points
    arrays_pts = []
    pts = fetch(Settings.FIELDS.POINTS, '')
    for p in pts
        points_map = Hash.new
        points_map["data"] = p
        points_map["checkboxes"] = p
        arrays_pts.push(points_map)
    end
    return arrays_pts
  end

  # Creates a Map of arrays of arrays of geo objects (bboxes, lines, points, and polygons) for the record map to be able to draw
  def geo_objects
    map_object_types = Hash.new

    # Get polygons
    map_object_types["polygons"] = get_polygons

    # Get lines (probably need to fix this as lines don't need to be straight lines so may need more than 2 points to define)
    map_object_types["lines"] = get_lines

    # Get bounding boxes
    map_object_types["bboxes"] = get_bboxes

    # Get points
    map_object_types["points"] = get_points

    return map_object_types
  end
end


