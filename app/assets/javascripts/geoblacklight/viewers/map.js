//= require geoblacklight/viewers/viewer


GeoBlacklight.Viewer.Map = GeoBlacklight.Viewer.extend({

  options: {
    /**
    * Initial bounds of map
    * @type {L.LatLngBounds}
    */
    bbox: [{lat:11.0,lng:-144.0},{lat:68.0,lng:-55.0}], 
    opacity: 0.75
  },

  overlay: L.layerGroup(),

  load: function() {
    if (this.data.mapBbox) {
      this.options.bbox = L.bboxToBounds(this.data.mapBbox);
    }
    this.map = L.map(this.element).fitBounds(this.options.bbox); 

    // Add initial bbox to map element for easier testing
    if (this.map.getBounds().isValid()) {
      this.element.setAttribute('data-js-map-render-bbox', this.map.getBounds().toBBoxString());
    }

    this.map.addLayer(this.selectBasemap());
    this.map.addLayer(this.overlay);
    if (this.data.map !== 'index') {
      this.addBoundsOverlay(this.options.bbox);
    }
  },

  /**
   * Add a bounding box overlay to map.
   * @param {L.LatLngBounds} bounds Leaflet LatLngBounds
   */
  addBoundsOverlay: function(bounds) {
    if (bounds instanceof L.LatLngBounds) {
      this.overlay.addLayer(L.polygon([
        bounds.getSouthWest(),
        bounds.getSouthEast(),
        bounds.getNorthEast(),
        bounds.getNorthWest()
      ]));
    }
  },

  /**
   * Add a bounding box overlay from checkbox previews to map.
   * @param {L.LatLngBounds} bounds Leaflet LatLngBounds
   * @param {string} name
   */
  addBoundsOverlaySingle: function(bounds, name) {
    if (bounds instanceof L.LatLngBounds) {
      mapOverlay = L.polygon([
                           bounds.getSouthWest(),
                           bounds.getSouthEast(),
                           bounds.getNorthEast(),
                           bounds.getNorthWest()
                         ]);
      mapOverlay.id=name;
      this.overlay.addLayer(mapOverlay);
    }
  },

    /**
     * Add a polyline overlay from checkbox previews to map.
     * @param {L.LatLng[]} points Leaflet LatLng array
     * @param {string} name
     */
  addLineOverlay: function(points, name) {
                    if (points.size>0) {
                      pointArray = [];
                      for (let i = 0; i< points.length; i++){
                      pointArray.push(points[i]);
                      }
                      mapOverlay = L.polyline(pointArray);
                      mapOverlay.id=name;
                      this.overlay.addLayer(mapOverlay);
                    }
  },

    /**
     * Add a point overlay from checkbox previews to map.
     * @param {L.LatLng} point Leaflet LatLng
     * @param {string} name
     */
  addPointOverlay: function(point, name) {
                    if (point instanceof L.LatLng) {
                      mapOverlay = L.circle(point);
                      mapOverlay.id=name;
                      this.overlay.addLayer(mapOverlay);
                    }
  },

  /**
     * Add a polygon overlay from checkbox previews to map.
     * @param {L.LatLngBounds} bounds Leaflet LatLngBounds
     * @param {string} name
     */
  addLineOverlay: function(points, name) {
                    if (points.size>0) {
                      pointArray = [];
                      for (let i = 0; i< points.length; i++){
                      pointArray.push(points[i]);
                      }
                      mapOverlay = L.polygon(pointArray);
                      mapOverlay.id=name;
                      this.overlay.addLayer(mapOverlay);
                    }
  },

  removeSingleBoundsOverlay: function(name) {
    for(var i in this.overlay._layers){
        if (this.overlay._layers[i].id == name){
            this.overlay.removeLayer(i);
        }
    }
  },
  /**
   * Remove bounding box overlay from map.
   */
  removeBoundsOverlay: function() {
    this.overlay.clearLayers();
  },

  /**
  * Selects basemap if specified in data options, if not return positron.
  */
  selectBasemap: function() {
    var _this = this;
    if (_this.data.basemap) {
      return GeoBlacklight.Basemaps[_this.data.basemap];
    } else {
      return GeoBlacklight.Basemaps.positron;
    }
  }
});
