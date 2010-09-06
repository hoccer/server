var sys = require("sys"); 
var Group = require("../lib/group.js");

module.exports = {
 //  'test #add user to group': function(assert) {
 //    var group = Group();
 //    group.addUser('123');
 //    assert.equal(1, group.users.length);
 //  },
 //  
 //  'test #perform send action to group': function(assert) {
 //    var group = Group();
 //    group.addUser('123');
 //    group.send({
 //      "mode": "distribute",
 //      success: function() {},
 //      error: function() {}
 //    });
 //    
 //    assert.equal(1, group.sender["distribute"].length);
 //  },
 //  
 //  '#test #perform receive gesture on group': function(assert) {
 //    var group = Group();
 //    group.addUser('123');
 //    group.receive({      
 //      "mode": "distribute",
 //      success: function() {},
 //      error: function() {}
 //    });
 //    
 //    assert.equal(1, group.receiver['distribute'].length);
 //  },
 // 
 // 'test #return error immediately after error': function(assert) {
 //    var group = Group(), 
 //     hasError = false;
 //   
 //    group.addUser('123');
 //    group.send({
 //      "mode": "distribute",
 //      success: function() {},
 //      error: function() {
 //        hasError = true;
 //      }
 //    })
 //    
 //    setTimeout(function() { assert.ok(hasError); }, 10);     
 //  },
  
  'test #successful exchanged': function(assert) {
    var group               = Group(),
      successfulSend        = false,
      successfulReceived    = false;
      
    group.addUser('123456');
    group.addUser('567899');
    
    group.send({
      "mode": "distribute",
      success: function() {
        successfulSend = true;
      },
      error: function() {}
    });

    assert.ok(!successfulSend);
    assert.ok(!successfulReceived); 
    
    group.receive({
      "mode": "distribute",
      success: function() {
        successfulReceived = true;
      },
      error: function() {}
    });
    
    assert.ok(successfulSend);
    assert.ok(successfulReceived); 
  } 
}