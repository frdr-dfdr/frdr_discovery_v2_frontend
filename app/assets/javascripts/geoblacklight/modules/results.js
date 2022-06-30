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
        $("input:hidden[name='f[dct_provenance_s][]']").map(function(x, elm) { return repos.push(elm.value); });
        $("input:hidden[name='f[dc_rights_s][]']").map(function(x, elm) { return perms.push(elm.value); });
        $("input:hidden[name='f[dc_creator_sm][]']").map(function(x, elm) { return authors.push(elm.value); });
        var year_begin = $("input:hidden[name='from']");
        year_begin = year_begin.length>0? year_begin[0].value : "*";

        var year_end = $("input:hidden[name='to']");
        year_end = year_end.length>0? year_end[0].value : "*";

        var bbox = $("input:hidden[name='bbox']");
        bbox = bbox.length > 0? bbox[0].value.split(' '): [];
        var q = $("#q[name='q']");
        q = q.length>0? q[0].value:"";

        updateClusters(q,repos,perms,authors,year_begin,year_end, bbox, pruneCluster, geoblacklight);

        // set hover listeners on map
        $('#content')
          .on('mouseenter', '#documents [data-layer-id]', function() {
            if($(this).data('bbox') !== "") {
              let bbox = $(this).data('bbox')
              geoblacklight.addBoundsOverlay(bbox)
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

  async function updateClusters(q,repos,perms,authors,year_begin,year_end, bbox, pruneCluster, geoblacklight){
    var base = {};
    base["@datatype"] = "GSearchRequest";
    base["@version"] = "2017-09-01";
    base["advanced"] = true;
    base["limit"] = 1000;
    base["offset"] = 0;
    if(q != "")
        base["q"] = q;
    base["result_format_version"] = "2017-09-01";
    var filters = [];
    var filter = {}
    filter["@datatype"] = "GFilter";
    filter["@version"] = "2017-09-01";

    //bounding box facet
        if(bbox.length > 0){
            geoFacet = JSON.parse(JSON.stringify(filter));
            geoFacet["field_name"] = "geoLocationPolygon";
            geoFacet["type"] = "geo_bounding_box";
            var bottomRight = {};
            bottomRight["lat"] = bbox[1];
            bottomRight["lon"] = bbox[2];
            geoFacet["bottom_right"] = bottomRight;
            var topLeft = {};
            topLeft["lat"] = bbox[3];
            topLeft["lon"] = bbox[0];
            geoFacet["top_left"] = topLeft;
            filters.push(geoFacet);
        }

    //repos facet
    if(repos.length > 0){
        filter["field_name"] = "dct_provenance_s";
        filter["type"] = "match_any";
        filter["values"] = repos;

        filters.push(filter);
    }
    //author facet
    if(authors.length > 0){
        var authFilter = JSON.parse(JSON.stringify(filter));
        authFilter["field_name"] = "dc_creator_sm";
        authFilter["values"] = authors;
        authFilter["type"] = "match_any";
        filters.push(authFilter);
    }
    //permissions facet
    if(perms.length > 0){
        var permsFilter = JSON.parse(JSON.stringify(filter));
        permsFilter["field_name"] = "dc_rights_s";
        permsFilter["type"] = "match_any";
        permsFilter["values"] = perms;
        filters.push(permsFilter);
    }

    //date range facet
    var dates = JSON.parse(JSON.stringify(filter));
    dates["type"] = "range";
    dates["field_name"] = "dct_issued_s";
    var vals = {}
    vals["from"] = year_begin;
    vals["to"] = year_end;
    var values = [];
    values.push(vals);
    dates["values"] = values;
    filters.push(dates);

    base["filters"] = filters;


    const url = "https://search.api.globus.org/v1/index/29abfeb0-bd17-4e6b-b058-85ea7a975e0f/search";
    updatePrune(url,base,pruneCluster).then((data,geoblacklight) =>{
        geoblacklight.map.addLayer(data);
    });
  }

  function addRecordsToClusters(json, pruneCluster){
    let meta = json['gmeta']
    meta.forEach(function(record){
        let slug = record["subject"];
        let content = record["content"][0];
        let title = content["dc_title_s"].slice(0,46) + "...";
        let polygon = content["geoLocationPolygon"]
        let lat = (polygon["coordinates"][0][0][1] + polygon["coordinates"][0][1][1])/2;
        let lng = (polygon["coordinates"][0][0][0] + polygon["coordinates"][0][1][0])/2;
        marker = new PruneCluster.Marker(lat,lng, {popup: "<a href='/catalog/" + slug + "'>" +title + "</a>"});
        pruneCluster.RegisterMarker(marker);
    });
    return pruneCluster;
  }

  async function updatePrune(url, base, pruneCluster){
        $.ajax(url, {
              data: JSON.stringify(base),
              contentType: 'application/json',
              type: 'POST',
              success: async function(data, status, jQxhr){
                  pruneCluster = await addRecordsToClusters(data, pruneCluster);
              },
              error: function( jqXhr, textStatus, errorThrown ){
                      console.log( errorThrown );
                  }
          });
          return pruneCluster;
        }
});


