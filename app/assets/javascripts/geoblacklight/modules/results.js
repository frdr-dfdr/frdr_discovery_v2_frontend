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

            // Send Oboe to admin/api for non-web-ui attributes like centroid
            // Not usingURL() to maintain legacy IE support
            url = document.createElement('a');
            url.href = window.location.href;
            url.pathname = '/admin/api.json'
            // Oboe - Re-query Solr for JSON results
            oboe(url.toString() + '&format=json&per_page=100&rows=100')
              .node('data.*', function( doc ){
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
});


