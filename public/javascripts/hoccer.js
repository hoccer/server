$(document).ready(function(){
  initialize();
  
  /* Ajaxify the submit form */
  $("#submit").click(function(){      
    lat = $("#latbox").attr("value");
    lng = $("#lonbox").attr("value");
    
    lat = lat.toString().replace(/\./, ",");
    lng = lng.toString().replace(/\./, ",");
          
    if ($("input[value=upload]").attr("checked")) {
      
      $("body").append("<div id='upload_foo'></div>");
      
      $.ajax({
        type: "POST",
        url: "/locations/"+lat+";"+lng+";100,0/gestures",
        data: "gesture[name]=" + $('input[name=gesture_name]:checked').val(),
        success: function(msg){
          $("#upload_response").html(msg);
          path = msg.split("/")[4].replace(/\"\}/, "");
        
          $('#upload_foo').uploadify({
            'uploader':  '/uploadify.swf',
            'cancelImg': '/images/cancel.png',
            'fileDataName': 'upload[attachment]',
            'auto':      'true',
            'scriptData': {'_method' : 'put'}, 
            'script':    "/uploads/" + path,
            onAllComplete : function() {
              $("#upload_foo").remove();
            }
          });
        }
      });
    }
    else {
      $.ajax({
        type: "GET",
        dataType: "json",
        url: "/locations/"+lat+";"+lng+";100,0/search?gesture="+$('input[name=gesture_name]:checked').val(),
        success: function(msg) {
          $("#downloads").append("<a href='"+msg.uploads[0]+"'>"+ msg.uploads[0]+"</a>");
        }
      });      
    }
    
    return false;
    
  });
})

setup_overlay = function() {
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
  var overlay_x         = (600-zoomed_radius_xy)/2;
  var overlay_y         = (450-zoomed_radius_xy)/2;
  
  logo = new GScreenOverlay('/images/radius.png',
          new GScreenPoint(overlay_x, overlay_y, 'pixels', 'pixels'),  // screenXY
          new GScreenPoint(0, 0),  // overlayXY
          new GScreenSize(zoomed_radius_xy, zoomed_radius_xy)  // size on screen
        );
  map.addOverlay(logo);
  
}