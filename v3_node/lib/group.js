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
    var actions = (sender[mode] || []).concat(receiver[mode] || []);
    for (var key in actions) {
      actions[key].success();
    }
  }
  
  var verify = function(mode, group) {
    if (users.length <= 1) {
      error(mode);
      return;
    }
    
    sys.puts("sender:" + sys.inspect(sender));
    sys.puts("receiver:" + sys.inspect(receiver));
    
    if ((sender[mode] || []).length == 1 && (receiver[mode] || []).length > 0) {
      sys.puts("success");
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
      sys.puts("send");
      var senderForMode = sender[action.mode] || [];
      senderForMode.push(action);
      sender[action.mode] = senderForMode;

      verify(action.mode, this);
    },
    
    receive: function(action) {
      sys.puts("receive");
      var receiverForMode = receiver[action.mode] || [];
      receiverForMode.push(action);
      receiver[action.mode] = receiverForMode;
      
      verify(action.mode, this);
    }    
  }              
};