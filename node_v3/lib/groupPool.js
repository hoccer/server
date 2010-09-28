var sys = require("sys");

module.exports = function() {
  var Group = require("./group");

  var users = {};
  var fakeGlobalGroup = Group();

  return {
    addUser: function(user_id) {
      users[user_id] = "ok";
      fakeGlobalGroup.addUser(user_id);
    },
    
    updateUser: function(user_id, env) {
      if (!users[user_id]) {
        this.addUser(user_id);
      }
      
      users[user_id] = env;
    },
        
    groupForUser: function(user) {
      return fakeGlobalGroup;
    },
    
    clear: function() {
      fakeGlobalGroup = Group();
    }
  }
};