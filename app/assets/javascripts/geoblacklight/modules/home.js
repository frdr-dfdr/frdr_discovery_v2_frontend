Blacklight.onLoad(function() {
  $('[data-map="home"]').each(function(i, element) {

    var geoblacklight = new GeoBlacklight.Viewer.Map(this);
    var data = $(this).data();
      
    geoblacklight.map.setZoom(2);
    geoblacklight.map.addControl(L.control.geosearch({
      baseUrl: data.catalogPath,
      dynamic: false,
      zoom: 2,
      center: [55.885798, -35.478689],
      searcher: function() {
        window.location.href = this.getSearchUrl();
      },
      staticButton: '<a class="search_here btn btn-primary"></a>'
    }));
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
});
