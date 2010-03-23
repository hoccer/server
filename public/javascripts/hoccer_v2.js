$(document).ready(function(){
  hoccer_client.initialize();
  maps.initialize();
});


var hoccer_client = {
  
  observer            : null,
  mode                : "",
  interval_id         : null,
  upload_interval_id  : null,
  upload_retry_count  : 0,
  
  initialize : function() {
    hoccer_client.initialize_share_and_receive_buttons();
    hoccer_client.setup_observer_callbacks();
    hoccer_client.initialize_uploadify();
    hoccer_client.switch_to_share_mode();
  },
  
  is_sharing : function() {
    return (hoccer_client.mode === "share");
  },
  
  is_receiving : function() {
    return (hoccer_client.mode === "receive");
  },
  
  setup_observer_callbacks : function() {
      
    $(hoccer_client.observer).bind("share", function(){
      for (callback_function in hoccer_client.share_callbacks) {
        hoccer_client.share_callbacks[callback_function]();
      }
    });
    
    $(hoccer_client.observer).bind("receive", function() {
      for (callback_function in hoccer_client.receive_callbacks) {
        hoccer_client.receive_callbacks[callback_function]();
      }
    });
  },
  
  initialize_share_and_receive_buttons : function() {
    $("#hoccer_receive").bind("click", function(){
      hoccer_client.switch_to_receive_mode();
    });
    
    $("#hoccer_share").bind("click", function(){
      hoccer_client.switch_to_share_mode();
    });
  },
  
  switch_to_receive_mode : function() {
    if (hoccer_client.mode != "receive") {
      hoccer_client.mode = "receive";
      $(hoccer_client.observer).triggerHandler("receive");
    }
  },
  
  switch_to_share_mode : function() {
    if (hoccer_client.mode != "share") {
      hoccer_client.mode = "share";
      $(hoccer_client.observer).triggerHandler("share");
    }
  },
  
  initialize_uploadify : function() {
    $('#upload_foo').uploadify({
      'uploader'    : 'uploadify.swf',
      'queueID'     : 'uploadify_queue',
      'cancelImg'   : 'images/cancel.png',
      'fileDataName': 'upload[attachment]',
      'scriptData'  : {'_method' : 'put'}, 
      'script'      : "/uploads/",
      'onSelect'    : function(){},
      'onComplete'  : function() {$("#messages").text("Upload successful");},
      'width'       : 72,
      'height'      : 28,
      'buttonImg'   : 'images/btn_browse.png',
      'wmode'       : 'transparent'
    });
  },
  
  share_callbacks : {
    bring_share_interface_to_front : function() {
      $("#hoccer_share").attr("src", "/images/tab_share-active.png");
      $("#hoccer_receive").attr("src", "/images/tab_receive-inactive.png");
      $("#receive_box").hide();
      $("#share_box").show();
    },
    
    enable_share_buttons : function() {
      $("#share_box img.throw").bind("click", function() {
        hoccer_client.post_gesture("distribute");
      });

      $("#share_box img.tap").bind("click", function() {
        hoccer_client.post_gesture("pass");
      });
    },
    
    disable_receive_buttons : function() {
      $("#receive_box img.throw").unbind("click");
      $("#receive_box img.tap").unbind("click");
    }
  },
  
  receive_callbacks : {
    bring_receive_interface_to_front : function() {
      $("#hoccer_receive").attr("src", "/images/tab_receive-active.png");
      $("#hoccer_share").attr("src", "/images/tab_share-inactive.png");
      $("#share_box").hide();
      $("#receive_box").show();
    },
    
    enable_receive_buttons : function() {
      $("#receive_box img.throw").bind("click", function() {
        hoccer_client.post_gesture("distribute");
      });

      $("#receive_box img.tap").bind("click", function() {
        hoccer_client.post_gesture("pass");
      });
    },
    
    disable_share_buttons : function() {
      $("#share_box img.throw").unbind("click");
      $("#share_box img.tap").unbind("click");
    }
    
  },
  
  share_validations : {
    validate_that_no_query_is_running : function() {
      if (hoccer_client.interval_id === null) {
        return true;
      } else {
        return false;
      }
    },
    
    validate_queue_is_not_empty : function() {
      if (!hoccer_client.files_in_queue()) {
        alert("Please select a file first. Then try again!");
        return false;
      } else {
        return true;
      }
    }
  },
  
  receive_validations : {
    validate_that_no_query_is_running : function() {
      if (hoccer_client.interval_id === null) {
        return true;
      } else {
        return false;
      }
    }
  },
  
  files_in_queue : function() {
    return (0 < $("#uploadify_queue").children().length);
  },
  
  generate_request_body : function(gesture) {
    lat = maps.getLatitude();
    lng = maps.getLongitude();
        
    var post_body = "peer[gesture]=" + gesture +
                    "&peer[latitude]=" + lat +
                    "&peer[longitude]=" + lng +
                    "&peer[accuracy]=" + 80.0;
    
    if (hoccer_client.mode == "share") { 
      post_body = post_body + "&peer[seeder]=1";
    }
    
    return post_body;
  },
  
  gesture_is_valid : function() {
    if (hoccer_client.is_sharing()) {            
      for (validation in hoccer_client.share_validations) {
        if (!hoccer_client.share_validations[validation]()) {
          return false;
        }
      }      
    } else if (hoccer_client.is_receiving()) {
      for (validation in hoccer_client.receive_validations) {
        if (!hoccer_client.receive_validations[validation]()) {
          return false;
        }
      }
    }
    return true;
  },
  
  post_gesture : function(gesture) {
    if (hoccer_client.gesture_is_valid()) {
      $.ajax({
        type:     "POST",
        url:      "/peers",
        data:     this.generate_request_body(gesture),
        dataType: "json",
        success:  this.posting_gesture_was_successful,
        error :   function() {
          alert("Something went wrong while submitting the gesture");
        }
      });
    }
  },
  
  posting_gesture_was_successful : function(msg) {
    if (hoccer_client.is_sharing() && msg.upload_uri) {
      upload_path = msg.upload_uri.match(/(\/uploads\/.+)/)[1];
      $("#upload_foo").uploadifySettings('script', upload_path);
      $("#upload_foo").uploadifyUpload();
    }
    else if (hoccer_client.is_receiving() && msg.peer_uri) {
      hoccer_client.initialize_peer_query(msg.peer_uri);
    }
  },
  
  initialize_peer_query : function(url) {
    var query_method = function() {hoccer_client.peer_query(url);};
    hoccer_client.interval_id = setInterval(query_method, 1000);
  },
  
  clear_peer_query : function() {
    window.clearInterval(hoccer_client.interval_id);
    hoccer_client.interval_id = null;
  },
  
  peer_query : function(url) {
    $.ajax({
      type: "GET",
      url: url,
      dataType: "json",
      success : function(msg) {
        if (0 < msg.resources.length) {
          hoccer_client.initialize_upload_query(msg.resources[0]);
        }
      },
      complete : function(event, xhr, settings) {
        
        if (event.status == 200) {
          $("#messages").text("Success");
        }
        if (event.status == 202 && (0 == $("#status img").length)) {
          $("#messages").html("Looking for peers …");
        }
        if (event.status != 202) {
          hoccer_client.clear_peer_query();
          $("#messages").text(JSON.parse(event.responseText).message);
        }
      },
      error : function() {
      }
    });
  },
  
  initialize_upload_query : function(url) {
    var query_method = function() {hoccer_client.fetch_upload(url);};
    hoccer_client.upload_interval_id = setInterval(query_method, 1000);
  },
  
  clear_upload_query : function() {
    window.clearInterval(hoccer_client.upload_interval_id);
    hoccer_client.upload_interval_id = null;
    hoccer_client.upload_retry_count = 0;
  },
  
  fetch_upload : function(upload_url) {
    if (9 < hoccer_client.upload_retry_count) { 
      hoccer_client.clear_upload_query();
    }
    
    $.ajax({
      type: "GET",
      url: upload_url,
      
      complete : function(xhr, status_text) {
        if (xhr.status == 200) {
          var content_regexp = /Content-Type\:\s([a-z\/-]+)/;
          content_type = content_regexp.exec(xhr.getAllResponseHeaders())[1];
          
          popup.handle_received_content({
            "content_type" : content_type,
            "data"         : xhr.responseText,
            "upload_url"   : upload_url
          });
          hoccer_client.clear_upload_query();
        }
      }
    });
    
    ++hoccer_client.upload_retry_count;
  }
};

var popup = {
  handle_received_content : function(options) {
    if (options.content_type.match(/^image/)) {
      Shadowbox.open({
        content:    options.upload_url,
        player:     "img"
      });
    } 
    else if (options.content_type.match(/text\/x-vcard/)) {
      name = options.data.match(/FN\:(.+)/)[1];

      Shadowbox.open({
        content:    "<table><tr><td id='vc_image'><a href='"+ options.upload_url + "'>" + 
                    "<img src='/images/vcard-icon.png' /></a></td>" + 
                    "<td id='vc_text'>"+ name + "</td></tr></table>",
        title:      "Contact",
        player:     "html"
      });
    }
    else if (options.content_type.match(/^text/)) {
      if (text.match(/^https?:\/\//)) {
        Shadowbox.open({
          content:    text,
          title:      text,
          player:     "iframe"
        });
      } else {
        //alert("replace me with something good");
      }
    }
  }
};