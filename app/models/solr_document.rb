require 'json'
require 'logging'
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
    @files = [{"geoserver_id" => 'file1.geojson',"file_name" => 'test1'},{"geoserver_id" => 'file2.geojson',"file_name" => 'test2'},{"geoserver_id" => 'file3.geojson',"file_name" => 'test3'}]
    @files2 = ["file1.geojson","file2.geojson","file3.geojson"]
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
    has_bbox? or has_line? or has_point? or has_polygon?
  end

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
    logger = Logging.logger(STDERR)
    logger.level = :warn
    array_boxes = []
    boxes = fetch(Settings.FIELDS.BBOXES, [])
    for box in boxes do
        bbox_map = Hash.new
        answer_bb = []
        answer_bb_str = String.new
        box_json = JSON.parse(box)
        west = String.new(box_json.fetch("west", "181"))
        east = String.new(box_json.fetch("east", "181"))
        north = String.new(box_json.fetch("north", "181"))
        south = String.new(box_json.fetch("south", "181"))
        error_message = "Somehow got an invalid bounding box to GBL: W " + west + " E " + east + " N " + north + " S " + south
        begin
            west_f = west.to_f.round(6)
            if west_f > 180 || west_f < -180
                logger.error error_message
                next
            end
            east_f = east.to_f.round(6)
            if east_f > 180 || east_f < -180
                logger.error error_message
                next
            end
            north_f = north.to_f.round(6)
            if north_f > 90 || north_f < -90
                logger.error error_message
                next
            end
            south_f = south.to_f.round(6)
            if south_f > 90 || south_f < -90
                logger.error error_message
                next
            end
        rescue
            error_message = "Somehow got an invalid entry in one of box coordinates: W " + west + " E " + east + " N " + north + " S " + south
            logger.error error_message
            next
        end

        point_nw = []
        point_se = []
        point_nw = [north_f.to_s,west_f.to_s]
        point_se = [south_f.to_s,east_f.to_s]
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
            answer_bb_str = (([other, city, province, country] - ["", nil]).join("; "))
        end
        bbox_map["data"] = answer_bb
        bbox_map["checkboxes"] = answer_bb_str
        array_boxes.push(bbox_map)
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
    logger = Logging.logger(STDERR)
    logger.level = :warn
    array_polygons = []
    polygons = fetch(Settings.FIELDS.POLYGONS, [])
    for polygon in polygons do
        answer_pgs = []
        answer_pg_str = []
        polygon_json = JSON.parse(polygon)
        first = String.new
        last = String.new
        bad =  false
        for point in polygon_json do
            single_point = []
            point_str = "(" + point["lat"].to_s + ", " + point["long"].to_s + ")"
            lat = point.fetch("lat",181).to_f.round(6)
            lon = point.fetch("long",181).to_f.round(6)
            if lat > 90 || lat< -90 || lon > 180 || lon < -180
                bad = true
                error_message = "ERROR: Somehow got an invalid point in a polygon to GBL: Lat " + lat + " Long " + lon
                logger.error error_message
                break
            end
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
        if bad
            next
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
    logger = Logging.logger(STDERR)
    logger.level = :warn
    array_points = []
    points = fetch(Settings.FIELDS.POINTS, [])
    for point in points do
        point_json = JSON.parse(point)
        points_map = Hash.new
        lat = point_json.fetch("lat",181).to_f.round(6)
        lon = point_json.fetch("long",181).to_f.round(6)
        if lat > 90 || lat < -90 || lon >180 || lon < -180
            error_message = "Somehow got an invalid point to GBL: lat " + lat + " long " + long
            logger.error error_message
            next
        end
        point_string = lat.to_s + ", " + lon.to_s
        points_map["data"] = "[" + point_string + "]"
        points_map["checkboxes"] = "(" + point_string + ")"
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
  # Check if there are geospatial files to preview
  def has_files?
    @files.length>0
    #once we are putting in real values from the GBL JSON use the below rather than the above
    #return has_previews?
  end

  # Return an array of key-value pair with geospatial file names and geoserver ids for geospatial files to preview
  def files(none)
    answer = []
    b = [none, ""]
    answer.push(b)
    #geo_files = @files
    #once we are putting in real values from the GBL JSON use the below rather than the above
    geo_files = get_previews
    geo_files.each do |file|
        label = file["file_name"]
        val = file["geoserver_id"]
        group = [label, val]
        answer.push(group)
    end
    return answer
  end

  def has_previews?
    fetch(Settings.FIELDS.GEO_PREVIEWS,[]).length>0
  end

  # Parse the incoming previewable file info and return an array of Hashes to the files method
  def get_previews
    logger = Logging.logger(STDERR)
    logger.level = :warn
    logger.error Settings.FIELDS.GEO_PREVIEWS
    prevs = fetch(Settings.FIELDS.POINTS,[])
    array = []
    logger.error prevs.length()
    prevs.each do |prev|
        group = Hash.new
        prev_json = JSON.parse(prev)
        label = prev_json.fetch("file_name",String.new)
        val = prev_json.fetch("geoserver_id",String.new)
        error_message = "file_name: " + label + " geoserver_id: " + val
        logger.error error_message
        if label == "" || file_name == ""
            next
        end
        group["file_name"] = label
        group["geoserver_id"] = val
        array.push(group)
    end
    sanity = {}
    sanity["file_name"] = "test"
    sanity["geoserver_id"] = "test_geoserver"
    array.push(sanity)
    return array
  end
end


