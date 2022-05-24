// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, or any plugin's
// vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery3
//= require rails-ujs
//= require activestorage

//
// Required by Blacklight
//= require popper
// Twitter Typeahead for autocomplete
//= require twitter/typeahead
//= require bootstrap
//= require blacklight/blacklight

//= require_tree .

// FRDR Discovery
//= require handlebars.runtime
//= require geoblacklight/geoblacklight
//= require geoblacklight/basemaps
//= require geoblacklight/controls
//= require geoblacklight/viewers

//The following line will tell sprockets to add the modules directory from our app,
// but we need to manually list all the files within modules that we want sprockets
// to look for in the geoblacklight gem asset location.
//= require geoblacklight/modules

// After importing modules from our app, look for these files...If the file
// has been overridden in our app it does not need to be specified here
//= require geoblacklight/modules/download
//= require geoblacklight/modules/help_text
//= require geoblacklight/modules/layer_opacity
//= require geoblacklight/modules/metadata
//= require geoblacklight/modules/metadata_download_button
//= require geoblacklight/modules/results
//= require geoblacklight/modules/util

//= require geoblacklight/downloaders
//= require readmore
//= require leaflet
//= require leaflet-iiif
//= require esri-leaflet

// Required for bounding box, line, point, polygon all checkboxes to change
// all of the other individual checkboxes in map controls on show
//= require geoblacklight/modules/items.js
//= require geoblacklight/modules/show_citation_controls.js

// Clustering
//= require Leaflet/leaflet.prunecluster/PruneCluster.js
//= require oboe/oboe-browser.js
