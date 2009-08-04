function initialize() {
  if (GBrowserIsCompatible()) {
    mapContainer = document.getElementById("map_canvas");
    map = new GMap2(mapContainer);
    map.setCenter(new GLatLng(52.501077, 13.345116), 17);
    map.enableScrollWheelZoom();
  }
  
  setupScreen();
};

function setupScreen() {
  
  document.getElementById("latbox").value=map.getCenter().lat();
  document.getElementById("lonbox").value=map.getCenter().lng();

  setup_overlay();
  
  
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
}