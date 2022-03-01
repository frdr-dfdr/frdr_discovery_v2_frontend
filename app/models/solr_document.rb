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

  def has_something?
    (geo_objects["bboxes"].length()+geo_objects["lines"].length()+geo_objects["points"].length()+geo_objects["polygons"].length())>0

  def has_bbox?
     geo_objects["bboxes"].length() > 0
  end

  def bboxes
    geo_objects["bboxes"]
  end

  def has_line?
    geo_objects["lines"].length() > 0
  end

  def lines
    geo_objects["lines"]
  end

  def has_point?
    geo_objects["points"].length() > 0
  end

  def points
    geo_objects["points"]
  end

  def has_polygon?
    geo_objects["polygons"].length() > 0
  end

  def polygons
    geo_objects["polygons"]
  end
  def get_bboxes
    array_boxes = []
    boxes = fetch(Settings.FIELDS.BBOXES, [])
    counter = 1
    for box in boxes do
        bbox_map = Hash.new
        answer_bb = []
        answer_bb_str = String.new
        box_json = JSON.parse(box)
        west = String.new(box_json.fetch("west", String.new))
        east = String.new(box_json.fetch("east", String.new))
        north = String.new(box_json.fetch("north", String.new))
        south = String.new(box_json.fetch("south", String.new))
        point_nw = []
        point_se = []
        point_nw = [north,west]
        point_se = [south,east]
        answer_bb.push(point_nw)
        answer_bb.push(point_se)

        other = String.new(box_json.fetch("other", String.new))
        country = String.new(box_json.fetch("country", String.new))
        province = String.new(box_json.fetch("province", String.new))
        city = String.new(box_json.fetch("city",String.new))
        file_name = String.new(box_json.fetch("file_name", String.new))
        if !file_name.empty?
            answer_bb_str = file_name
        elsif other.empty? && country.empty? && province.empty? && city.empty?
            answer_bb_str = "North: " + north.to_s + ", West: " + west.to_s + ", South: " + south.to_s + ', East: ' + east.to_s
        else
            answer_bb_str = (([other, city, province, country] - ["", nil]).join(";"))
        end
        bbox_map["data"] = answer_bb
        bbox_map["checkboxes"] = answer_bb_str
        array_boxes.push(bbox_map)
        counter = counter + 1
    end
    return array_boxes
  end
    #TODO update to deal with polylines
  def get_lines
    array_lines = []
    lines = fetch(Settings.FIELDS.LINES, [])
    for line in lines do
        answer_str = String.new
        line_json = JSON.parse(line)
        answer_str = "(" + line_json["lat1"].to_s + ", " + line_json["long1"].to_s + ") - (" + line_json["lat2"].to_s + ", " + line_json["long2"].to_s + ")"
        answer_ls = []
        line_pt_1 = []
        line_pt_2 = []
        line_pt_1.push(line_json["lat1"])
        line_pt_1.push(line_json["long1"])
        answer_ls.push(line_pt_1)
        line_pt_2.push(line_json["lat2"])
        line_pt_2.push(line_json["long2"])
        answer_ls.push(line_pt_2)
        line_map = Hash.new
        line_map["data"] = answer_ls
        line_map["checkboxes"] = answer_str
        array_lines.push(line_map)
    end
    return array_lines
  end

  def get_polygons
    array_polygons = []
    polygons = fetch(Settings.FIELDS.POLYGONS, [])
    for polygon in polygons do
        answer_pgs = []
        answer_pg_str = []
        polygon_json = JSON.parse(polygon)
        first = String.new
        last = String.new
        for point in polygon_json do
            single_point = []
            point_str = "(" + point["lat"].to_s + ", " + point["long"].to_s + ")"
            single_point.push(point["lat"])
            single_point.push(point["long"])
            if first.empty?
                first = single_point
                first_str = point_str
            end
            answer_pgs.push(single_point)
            last = single_point
            answer_pg_str.push(point_str)
            last_str = point_str
        end
        if last == first
            answer_pgs.pop()
            answer_pg_str.pop()
        end
        label = String.new
        counter = 0
        for a in answer_pg_str do
            if counter != 0
                label = label + ", "
            end
            counter = 1
            label = label + a
        end
        poly_map = Hash.new
        poly_map["data"] = answer_pgs
        poly_map["checkboxes"] = label
        array_polygons.push(poly_map)
    end
    return array_polygons
  end

  def get_points
    array_points = []
    points = fetch(Settings.FIELDS.POINTS, [])
    for point in points do
        points_map = Hash.new
        points_map["data"] = "[" + point.to_s + "]"
        points_map["checkboxes"] = "(" + point.to_s + ")"
        array_points.push(points_map)
    end
    return array_points
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


