require 'rsolr'

namespace :geoportal do
  desc 'Generate homepage centroids for map clustering'
  task generate_centroids_json: :environment do
    # Search request
    response = Blacklight.default_index.connection.get 'select', :params => {:q => "*:*", :rows => '100000'}

    docs = []
    response["response"]["docs"].each_with_index do |doc, index|
      begin
        if doc.key?('solr_geom') && !doc['solr_geom'].empty?
          entry = {}
          entry['l'] = doc['layer_slug_s']
          entry['t'] = doc['dc_title_s'].truncate(50)
          geom = doc['solr_geom']
          geom = geom[geom.index('(')+1..geom.index(')')-1]
          w,e,n,s    = geom.split(",")
          lat = ((n.to_f+s.to_f)/2).round(4) # Truncate long values
          lng = ((w.to_f+e.to_f)/2).round(4) # Truncate long values
          entry['c'] = "#{lat},#{lng}"
          docs << entry
        end
      rescue Exception => e
        puts "Caught #{e}"
        puts "BBox or centroid no good - #{doc['layer_slug_s']}"
      end
    end

    centroids_file = "#{Rails.root}/public/centroids_full.json"
    File.open(centroids_file, "w"){|f| f.write(JSON.generate(docs))}
  end
end
