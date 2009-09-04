$(document).ready(function(){
  maps.initialize();
  hoccer.initialize();
  uploader.initialize();
});


var hoccer = {
  
  interval_id : 0,
  
  initialize : function() {
    $("#throw").click(function() {
      hoccer.post_gesture("distribute");
      
      return false;
    });
    
    $("#tap").click(function() {
      hoccer.post_gesture("pass");
      
      return false;
    });
    
  },
  
  post_gesture : function(gesture) {
    lat = maps.getLatitude();
    lng = maps.getLongitude();
        
    var post_body = "peer[gesture]=" + gesture +
                    "&peer[latitude]=" + lat +
                    "&peer[longitude]=" + lng +
                    "&peer[accuracy]=" + 80.0

    //alert(post_body);

                      
    if (0 < $("#upload_fooQueue").children().length) {
      post_body = post_body + "&peer[seeder]=1"
    } else {
    	return;
    }
    
      
    $.ajax({
      type: "POST",
      url: "/peers",
      data: post_body,
      dataType: "json",
      success: function(msg){
        if (msg.upload_uri) {
          upload_path = msg.upload_uri.match(/(\/uploads\/.+)/)[1];
          $("#upload_foo").uploadifySettings('script', upload_path);
          $("#upload_foo").uploadifyUpload();
        }
        else {
            hoccer.initialize_peer_query(msg.peer_uri);
        }
      }
    });
  },
  
  
  initialize_peer_query : function(url) {
    var query_method = function() {hoccer.peer_query(url)}
    hoccer.interval_id = setInterval(query_method, 1000);
  },
  
  peer_query : function(url) {
    $.ajax({
      type: "GET",
      url: url,
      dataType: "json",
      success : function(msg) {
        if (0 < msg.resources.length) {
          hoccer.fetch_upload(msg.resources[0]);
        }
      },
      complete : function(event, xhr, settings) {
        if (event.status == 200) {
          window.clearInterval(hoccer.interval_id);
          $("#status").empty();
        }
        if (event.status == 202 && (0 == $("#status img").length)) {
          $("#status").append("<img src='/images/ajax-loader.gif' />" );
        }
      },
      error : function() {
        //alert("error");
        window.clearInterval(hoccer.interval_id);
      }
    });
  },
  
  fetch_upload : function(upload_url) {
    $.ajax({
      type: "GET",
      url: upload_url,
      
      complete : function(xhr, status_text) {
        var tmp_regexp = /Content-Type\:\s([a-z\/-]+)/
        content_type = tmp_regexp.exec(xhr.getAllResponseHeaders())[1];
        generic_type = content_type.split("/")[0];
        
        if (content_type.match(/^image/)) {
          popup.handle_image(upload_url);
        } 
        else if (content_type.match(/text\/x-vcard/)) {
          popup.handle_vcard(xhr.responseText, upload_url);
        }
        else if (content_type.match(/^text/)) {
          popup.handle_text(xhr.responseText);
        }
      }
      
    });
  }
}

var popup = {
  
  handle_image : function(image_url) {
    Shadowbox.open({
      content:    image_url,
      player:     "img"
    });
  },
  
  handle_text : function(text) {
    if (text.match(/^https?:\/\//)) {
      Shadowbox.open({
        content:    text,
        title:      text,
        player:     "iframe"
      });
    } else {
      //alert("replace me with something good");
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
      'uploader':  'uploadify.swf',
      'cancelImg': 'images/cancel.png',
      'fileDataName': 'upload[attachment]',
      'scriptData': {'_method' : 'put'}, 
      'script':    "/uploads/",
      'onSelect': function(){},
      'width' : 72,
      'height' : 28,
      'buttonImg': 'images/btn_browse.png',
      'wmode' : 'transparent'
    });
  }
}
