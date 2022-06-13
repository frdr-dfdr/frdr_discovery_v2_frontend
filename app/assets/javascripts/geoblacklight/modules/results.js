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

           // Oboe - SAX steam JSON results from Solr /export
           // oboe('http://localhost:8983/solr/geoportal/export?fl=uuid_sdv,dc_title_sdv,centroid_sdv&indent=on&q=*:*&wt=json&sort=dc_title_sdv%20asc&rows=10000')

           oboe('/centroids.json')
             .node('*', function( doc ){
                 if(typeof doc.c != 'undefined'){
                   var latlng = doc.c.split(",")

                   var marker = new PruneCluster.Marker(latlng[0],latlng[1], {popup: "<a href='/catalog/" + doc.l + "'>" + doc.t + "</a>"});
                   pruneCluster.RegisterMarker(marker);
              }
            }
          )
          .done(function(){
            geoblacklight.map.addLayer(pruneCluster)
        })
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


