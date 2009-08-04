$(document).ready(function(){
  maps.initialize();
  uploader.initialize();
  
  /* Ajaxify the submit form */
  $("#submit").click(function(){      
    lat = $("#latbox").attr("value");
    lng = $("#lonbox").attr("value");
    
    lat = lat.toString().replace(/\./, ",");
    lng = lng.toString().replace(/\./, ",");
          
    if (0 < $("#upload_fooQueue").children().length) {
      
      var gesture_path = "/locations/"+lat+";"+lng+";100,0/gestures";
      
      $.ajax({
        type: "POST",
        url: gesture_path,
        data: "gesture[name]=" + $('input[name=gesture_name]:checked').val(),
        success: function(msg){
          var upload_path = "/uploads/" + msg.split("/")[4].replace(/\"\}/, "");
          $("#upload_foo").uploadifySettings('script', upload_path);
          $("#upload_foo").uploadifyUpload(); 
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
});

var uploader = {
  initialize : function() {
    $('#upload_foo').uploadify({
      'uploader':  '/uploadify.swf',
      'cancelImg': '/images/cancel.png',
      'fileDataName': 'upload[attachment]',
      'scriptData': {'_method' : 'put'}, 
      'script':    "/uploads/"
    });
  }
}