Blacklight.onLoad(function() {
   var historySupported = !!(window.history && window.history.pushState);

   if (historySupported) {
     History.Adapter.bind(window, 'statechange', function() {
       var state = History.getState();
       updatePage(state.url);
     });
   }

   $('[data-map="index"]').each(function() {
     var data = $(this).data(),
     opts = { baseUrl: data.catalogPath },
     world = L.latLngBounds([[-90, -180], [90, 180]]),
     geoblacklight, bbox;

     if (typeof data.mapGeom === 'string') {
       bbox = L.geoJSONToBounds(data.mapGeom);
     } else {
       $('.document [data-geom]').each(function() {
         try {
           var currentBounds = L.geoJSONToBounds($(this).data().geom);
           if (!world.contains(currentBounds)) {
             throw "Invalid bounds";
           }
           if (typeof bbox === 'undefined') {
             bbox = currentBounds;
           } else {
             bbox.extend(currentBounds);
           }
         } catch (e) {
           bbox = L.bboxToBounds("-180 -90 180 90");
         }
       });
     }

     if (!historySupported) {
       $.extend(opts, {
           dynamic: false,
           searcher: function() {
             window.location.href = this.getSearchUrl();
           }
         });
       }

       // instantiate new map
       geoblacklight = new GeoBlacklight.Viewer.Map(this, { bbox: bbox });

       // set hover listeners on map
       $('#content')
         .on('mouseenter', '#documents [data-layer-id]', function() {
           if($(this).data('bbox') !== "") {
           var bounds = L.bboxToBounds($(this).data('bbox'));
           geoblacklight.addBoundsOverlay(bounds);
           }
         })
         .on('mouseleave', '#documents [data-layer-id]', function() {
           geoblacklight.removeBoundsOverlay();
         });

       // add geosearch control to map
       geoblacklight.map.addControl(L.control.geosearch(opts));
       var pruneCluster = new PruneClusterForLeaflet();
       repos = []
       perms = []
       authors = []
       $("input:hidden[name='f[dct_provenance_s][]']").map(function(x, elm) { return repos.add(elm.value); });
       $("input:hidden[name='f[dc_rights_s][]']").map(function(x, elm) { return perms.add(elm.value); });
       $("input:hidden[name='f[dc_creator_sm][]']").map(function(x, elm) { return authors.add(elm.value); });
       year_begin = $("input:hidden[name='range[gbl_indexYear_im][begin]'").value;
       if(year_begin==null){
            year_begin = "*";
       }
       year_end = $("input:hidden[name='range[gbl_indexYear_im][end]'").value;
       if(year_end == null){
            year_end == "*";
       }
       bbox = $("input:hidden[name='bbox']")[0].value.split(' ');
       if(bbox == null)
            bbox == [];
       var q = $("#q[name='q']")[0].value
       results = getGlobusRecords(q,repos,perms,authors,year_begin,year_end, bbox);
       


            // Send Oboe to admin/api for non-web-ui attributes like centroid
            // Not usingURL() to maintain legacy IE support
            url = document.createElement('a');
            loc = window.location.href;
            loc = loc.replace('https','http');
            loc = loc.replace('/en',':8983/solr/geoblacklight/select')
            loc = loc.replace('/fr',':8983/solr/geoblacklight/select')
            // Oboe - Re-query Solr for JSON results
            oboe(loc + '&format=json&per_page=1000&rows=1000')
              .node('response.*', function( doc ){
                  if(typeof doc['solr_geom'] != 'undefined'){
                      geom = doc['solr_geom']
                      geom = geom[geom.index('(')+1..geom.index(')')-1]
                      w,e,n,s    = geom.split(",")
                      lat = ((n.to_f+s.to_f)/2).round(4) // Truncate long values
                      lng = ((w.to_f+e.to_f)/2).round(4) // Truncate long values
                      var marker = new PruneCluster.Marker(lat,lng, {popup: "<a href='/catalog/" + doc['layer_slug_s'] + "'>" +doc['dc_title_s'].truncate(50) + "</a>"});
                      pruneCluster.RegisterMarker(marker);
              }
            }
          )
          .done(function(){
            geoblacklight.map.addLayer(pruneCluster)
        })

            // set hover listeners on map
            $('#content')
              .on('mouseenter', '#documents [data-layer-id]', function() {
                if($(this).data('bbox') !== "") {
                  var geom = $(this).data('geom')
                  geoblacklight.addGeoJsonOverlay(geom)
                }
              })
              .on('mouseleave', '#documents [data-layer-id]', function() {
                geoblacklight.removeBoundsOverlay();
              });
  });

  function updatePage(url) {
    $.get(url).done(function(data) {
      var resp = $.parseHTML(data);
      $doc = $(resp);
      $('#documents').replaceWith($doc.find('#documents'));
      $('#sidebar').replaceWith($doc.find('#sidebar'));
      $('#sortAndPerPage').replaceWith($doc.find('#sortAndPerPage'));
      $('#appliedParams').replaceWith($doc.find('#appliedParams'));
      $('#pagination').replaceWith($doc.find('#pagination'));
      if ($('#map').next().length) {
        $('#map').next().replaceWith($doc.find('#map').next());
      } else {
        $('#map').after($doc.find('#map').next());
      }
    });
  }

  function getGlobusRecords(q,repos,perms,authors,year_begin,year_end, bbox){
    var base = {};
    base["@datatpe"] = "GSearchRequest";
    base["@version"] = "2017-09-01";
    base["advanced"] = true;
    base["limit"] = 20;
    base["offset"] = 0;
    if(q != null)
        base["q"] = q;
    base["result_format_version"] = "2017-09-01";
    var filters = [];
    var filter = {}
    filter["@datatype"] = "GFilter";
    filter["@version"] = "2017-09-01";

    //repos facet
    if(repos != []){
        filter["field_name"] = "dct_provenance_s";
        filter["type"] = "match_any";
        filter["values"] = repos;
        var repoFilter = filter;
        filters.add(repoFilter);
    }
    //author facet
    if(authors != []){
        filter["field_name"] = "dc_creator_sm";
        filter["values"] = authors;
        filter["type"] = "match_any";
        var authorFilter = filter;
        filters.add(authorFilter);
    }
    //permissions facet
    if(perms != []){
        filter["field_name"] = "dc_rights_s";
            filter["type"] = "match_any";
            filter["values"] = perms;
            var permsFilter = filter;
            filters.add(premsFilter);
    }

    //date range facet
    filter["type"] = "range";
    filter["field_name"] = "dct_issued_s";
    var vals = {}
    vals["from"] = year_begin;
    vals["to"] = year_end;
    filter["values"] = vals;
    var dates = filter;
    filters.add(dates);

    //bounding box facet
    filter["type"] = "geo_bounding_box";
    if(bbox != []){
        filter["field_name"] = "geoLocationPolygons";
        filter["type"] = "geo_bounding_box";
        var bottomRight = {};
        bottomRight["lat"] = bbox[3];
        bottomRight["lon"] = bbox[1];
        filter["bottom_right"] = bottomRight;
        var topLeft = {};
        topLeft["lat"] = bbox[2];
        topLeft["lon"] = bbox[0];
        filter["top_left"] = topLeft;
        var geoFacet = filter;
        filters.add(geoFacet);
    }
    base["filters"] = filters;
    var xhr = new XMLHttpRequest();
    var url = "https://search.api.globus.org/v1/index/29abfeb0-bd17-4e6b-b058-85ea7a975e0f/search";
    xhr.open("POST", url, true);
    xhr.setRequestHeader("Content-Type", "application/json");
    xhr.onreadystatechange = function () {
        if (xhr.readyState === 4 && xhr.status === 200) {
            var json = JSON.parse(xhr.responseText);
            console.log(json.email + ", " + json.password);
        }
    };
    var response = xhr.send(base);
    var text =  response.string();
  }
});


