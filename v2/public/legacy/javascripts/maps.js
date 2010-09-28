var maps = {

  initialize : function() {
    if (GBrowserIsCompatible()) {
      mapContainer = document.getElementById("map_canvas");
      map = new GMap2(mapContainer);

      map.setCenter(new GLatLng(52.501077, 13.345116), 17);
      map.enableScrollWheelZoom();

      if (navigator.geolocation){
        navigator.geolocation.getCurrentPosition(function(position){
          map.setCenter(new GLatLng(position.coords.latitude, position.coords.longitude), 17);
        });
      }
    }

    maps.setup_screen();
  },

  setup_screen : function() {
    maps.setup_overlay();

    GEvent.addListener(map, 'click', function(overlay, point) {

      if (point) {
        map.panTo(point);
      }
    });

    GEvent.addListener(map, "zoomend", function() {
      setup_overlay();
    });


    // Recenter Map and add Coords by clicking the map
    GEvent.addListener(map, 'click', function(overlay, point) {
                document.getElementById("latbox").value=point.y;
                document.getElementById("lonbox").value=point.x;
    });

    GEvent.addListener(map, 'dragend', function(){
      document.getElementById("latbox").value=map.getCenter().lat();
      document.getElementById("lonbox").value=map.getCenter().lng();
    });

    var mapControl = new GMapTypeControl();
    map.addControl(mapControl);
    map.addControl(new GLargeMapControl());
  },

  setup_overlay : function() {
    map.clearOverlays();

    var zoom_level      = map.getZoom();
    var max_zoom_level  = 17;
    var zoom_diff       = max_zoom_level - zoom_level;
    var scale_factor    = zoom_diff * 2;

    if (scale_factor == 0) {
      scale_factor = 1;
    }

    var radius_xy       = 300;

    var zoomed_radius_xy  = (radius_xy / scale_factor);
    var overlay_x         = (340-zoomed_radius_xy)/2;
    var overlay_y         = (340-zoomed_radius_xy)/2;

    logo = new GScreenOverlay('images/radius.png',
            new GScreenPoint(overlay_x, overlay_y, 'pixels', 'pixels'),  // screenXY
            new GScreenPoint(0, 0),  // overlayXY
            new GScreenSize(zoomed_radius_xy, zoomed_radius_xy)  // size on screen
          );
    map.addOverlay(logo);

  },

  getLongitude : function() {
    return map.getCenter().lng();
  },

  getLatitude : function() {
    return map.getCenter().lat();
  }



}

// Create new geocoding object
var geocoder = new GClientGeocoder();

function showAddress(address) {
		if (geocoder) {
        geocoder.getLatLng(
          address,
          function(point) {
            if (!point) {
              alert("location '" + address + "' not found");
            } else {
              map.panTo(point);
            }
          }
        );
  }
}

function showAddress(address) {
		if (geocoder) {
        geocoder.getLatLng(
          address,
          function(point) {
            if (!point) {
              alert("location '" + address + "' not found");
            } else {
              map.panTo(point);
            }
          }
        );
  }
}
