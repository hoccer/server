$(document).ready(function(){
  hoccer_client.initialize();
  maps.initialize();
});


var hoccer_client = {
  
  observer    : null,
  mode        : "",
  interval_id : null,
  
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
    else if (hoccer_client.is_receiving()) {
      alert("i'm a receiver if i try");
    }
  }
};