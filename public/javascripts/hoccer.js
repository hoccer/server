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
        url: "/locations/"+lat+";"+lng+";80,0/search?gesture="+$('input[name=gesture_name]:checked').val(),
        success: function(msg) {
          if (msg.uploads[0]) {
            $.ajax({
              type: "GET",
              url: msg.uploads[0],
              
              complete : function(xhr, status_text) {
                var tmp_regexp = /Content-Type\:\s([a-z\/-]+)/
                content_type = tmp_regexp.exec(xhr.getAllResponseHeaders())[1];
                generic_type = content_type.split("/")[0];
                
                if (content_type.match(/^image/)) {
                  popup.handle_image(msg.uploads[0]);
                } 
                else if (content_type.match(/text\/x-vcard/)) {
                  popup.handle_vcard(xhr.responseText, msg.uploads[0]);
                }
                else if (content_type.match(/^text/)) {
                  popup.handle_text(xhr.responseText);
                }
                
              } 
            });
          }
        }
      });      
    }
    
    return false;
    
  });
});

var popup = {
  
  handle_image : function(image_url) {
    Shadowbox.open({
      content:    image_url,
      player:     "img"
    });
  },
  
  handle_text : function(text) {
    if (text.match(/^http:\/\//)) {
      Shadowbox.open({
        content:    text,
        title:      text,
        player:     "iframe"
      });
    } else {
      popup.handle_text(xhr.responseText);
    }
  },
  
  handle_vcard : function(vcard, url) {
    
    name = vcard.match(/FN\:(.+)/)[1];
    
    Shadowbox.open({
      content:    "<table><tr><td id='vc_image'><a href='"+ url + "'>" + 
                  "<img src='/images/vcard-icon.png' /></a></td>" + 
                  "<td id='vc_text'>"+ name + "</td></tr></table>",
      title:      "Contact",
      player:     "html"
    });
  }
}

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