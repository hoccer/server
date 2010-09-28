var sys = require("sys"); 
var Group = require("../lib/group.js");

module.exports = {
  'test #add user to group': function(assert) {
    var group = Group();
    group.addUser('123');
    assert.equal(1, group.users.length);
  },
  
  'test #perform send action to group': function(assert) {
    var group = Group();
    group.addUser('123');
    group.send({
      "mode": "distribute",
      success: function() {},
      error: function() {}
    });
    
    assert.equal(1, group.sender["distribute"].length);
  },
  
  '#test #perform receive gesture on group': function(assert) {
    var group = Group();
    group.addUser('123');
    group.receive({      
      "mode": "distribute",
      success: function() {},
      error: function() {}
    });
    
    assert.equal(1, group.receiver['distribute'].length);
  },
 
 'test #return error immediately after error': function(assert) {
    var group = Group(), 
     hasError = false;
   
    group.addUser('123');
    group.send({
      "mode": "distribute",
      success: function() {},
      error: function() {
        hasError = true;
      }
    })
    
    setTimeout(function() { assert.ok(hasError); }, 10);     
  },
  
  'test two groupes': function(assert) {
    var g1 = Group(), g2 = Group();
    
    g1.addUser('1');
    g2.addUser('2');
    
    assert.equal(1, g1.users.length);
    assert.equal(1, g2.users.length);
  },
  
  'test #successful exchanged': function(assert) {
    var group               = Group(),
      successfulSend        = false,
      successfulReceived    = false,
      receivedContent       = "";
      
    group.addUser('123456');
    group.addUser('567899');
    
    group.send({
      mode    : "distribute",
      payload : "Hello",
      success : function() {
        successfulSend = true;
      },
      error   : function() {}
    });
 
    assert.ok(!successfulSend);
    assert.ok(!successfulReceived); 
    
    group.receive({
      "mode": "distribute",
      success: function(content) {
        successfulReceived = true;
        receivedContent = content;
      },
      error: function() {}
    });
    
    assert.ok(successfulSend);
    assert.ok(successfulReceived);
    assert.equal("Hello", receivedContent); 
  }
  
  // 'test two servers': function(assert) {
  //   var s1 = require("../server").create();
  //   var s2 = require("../server").create();
  //   
  //   s1.groupPool.addUser(123);
  //   s2.groupPool.addUser(456);
  //   
  //   assert.ok(s1 !== s2);
  //   
  //   assert.equal(1, s1.groupPool.groupForUser(123).users.length);
  //   assert.equal(1, s2.groupPool.groupForUser(456).users.length);
  // }
  
  
}