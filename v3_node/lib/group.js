var sys = require("sys");

module.exports =  function() {
  var sender = {}, receiver = {};
  var users = [];  
     
  var error = function(mode) {
    var actions = (sender[mode] || []).concat(receiver[mode] || []);
    for (var key in actions) {
      actions[key].error();
    }
  }        
  
  var deliverContent = function(mode) {
    var s = sender[mode][0];
    s.success();
    
    for (var key in receiver[mode]) {
      sys.puts(s.payload);
      receiver[mode][key].success(s.payload);
    }
  }
  
  var verify = function(mode, group) {
    if (users.length <= 1) {
      error(mode);
      return;
    }
    
    if ((sender[mode] || []).length == 1 && (receiver[mode] || []).length > 0) {
      deliverContent(mode);
      return;
    }
  }
  
  return {
    users: users,
    sender: sender,
    receiver: receiver,
  
    addUser: function(user) {
      users.push(user);
    },
    
    send: function(action) {
      var senderForMode = sender[action.mode] || [];
      senderForMode.push(action);
      sender[action.mode] = senderForMode;

      verify(action.mode, this);
    },
    
    receive: function(action) {
      var receiverForMode = receiver[action.mode] || [];
      receiverForMode.push(action);
      receiver[action.mode] = receiverForMode;
      
      verify(action.mode, this);
    }    
  }              
};