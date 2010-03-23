$(document).ready(function(){
  maps.initialize();
  hoccer_interface.initialize();
  hoccer.initialize();
  uploader.initialize();
});


hoccer_interface = {
  initialize : function() {
    $("#receive_box").hide();
    
    $("#hoccer_receive").bind("click", function(){
      if (/active/.exec($(this).attr("src"))) {
        $(this).attr("src", "/images/tab_receive-active.png");
        $("#hoccer_share").attr("src", "/images/tab_share-inactive.png");
        $("#share_box").hide();
        $("#receive_box").show();
      }
    });
    
    $("#hoccer_share").bind("click", function(){
      if (/active/.exec($(this).attr("src"))) {
        $(this).attr("src", "/images/tab_share-active.png");
        $("#hoccer_receive").attr("src", "/images/tab_receive-inactive.png");
        $("#receive_box").hide();
        $("#share_box").show();
      }
    });
  }
};

var hoccer = {
  
  interval_id : null,
  
  initialize : function() {
    $("#share_box img.throw").bind("click", function() {
      if (hoccer.interval_id === null) {
        hoccer.post_gesture("distribute");
      }
    });
    
    $("#share_box img.tap").bind("click", function() {
      if (hoccer.interval_id === null) {
        hoccer.post_gesture("pass");
      }
    });
    
    $("#receive_box img.throw").bind("click", function(){
      if (hoccer.interval_id === null) {
        hoccer.post_gesture("distribute");
      }
    });
    
    $("#receive_box img.tap").bind("click", function(){
      if (hoccer.interval_id === null) {
        hoccer.post_gesture("pass");
      }
    });
  },
  
  post_gesture : function(gesture) {
    lat = maps.getLatitude();
    lng = maps.getLongitude();
        
    var post_body = "peer[gesture]=" + gesture +
                    "&peer[latitude]=" + lat +
                    "&peer[longitude]=" + lng +
                    "&peer[accuracy]=" + 80.0;
                      
    var queue_length = $("#upload_fooQueue").children().length;
    var widget_mode = function() {
      if ($("#receive_box").css("display") == "none") {
        return "share";
      } 
      else if ($("#share_box").css("display") == "none") {
        return "receive"
      }
    };
    
    if (0 < queue_length) {
      post_body = post_body + "&peer[seeder]=1";
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
        else if (widget_mode() == "receive") {
          hoccer.initialize_peer_query(msg.peer_uri);
        }
      }
    });
  },
  
  
  initialize_peer_query : function(url) {
    var query_method = function() {hoccer.peer_query(url);};
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
          hoccer.interval_id = null;
          $("#status").empty();
        }
        if (event.status == 202 && (0 == $("#status img").length)) {
          $("#status").append("<img src='/images/ajax-loader.gif' />" );
        }
      },
      error : function() {
        window.clearInterval(hoccer.interval_id);
        hoccer.interval_id = null;
        $("#status").empty();
      }
    });
  },
  
  fetch_upload : function(upload_url) {
    $.ajax({
      type: "GET",
      url: upload_url,
      
      complete : function(xhr, status_text) {
        var tmp_regexp = /Content-Type\:\s([a-z\/-]+)/;
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
};

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
};

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
};