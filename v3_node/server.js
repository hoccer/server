var sys = require("sys"), 
   uuid = require("uuid"); 

var express = require('express');
var app   = express.createServer();
var Group = require('./lib/group'); 

var GroupPool = function() {
  var users = [];
  var fakeGlobalGroup = Group();

  return {
    addUser: function(user) {
      fakeGlobalGroup.addUser(user);
    },
    
    groupForUser: function(user) {
      return fakeGlobalGroup;
    },
    
    clear: function() {
      fakeGlobalGroup = Group();
      sys.puts(sys.inspect(fakeGlobalGroup));
    }
  }
};

exports.create = function() {
  app.configure(function() {
    app.use(express.methodOverride());
    app.use(express.bodyDecoder());
  });
  
  var groupPool = GroupPool();
    
  app.post('/client', function(req, res) {
    var id = uuid.generate("hex");
    groupPool.addUser(id)
    res.redirect("/client/" + id, 303);
  });
  
  app.get('/client/:id', function(req, res) {
    res.send({uri: "/client/" + req.params.id}, 
             {'Content-Type': 'application/json'});
  });
  
  app.put('/client/:id/environment', function(req, res) {
    res.send(200);
  });
  
  app.post("/client/:id/action/:mode", function(req, res) {
    
  });
  
  app.get("/client/:id/action/:mode", function(req, res) {
    var group = groupPool.groupForUser(req.params.id);
        
    if (!group) {
      res.send(500);
    }
    
    group.receive({
      mode: req.params.mode,
      success: function(content) { res.send(content); },
      error: function() { res.send(500); }
    });
  });
  
  return app;
}