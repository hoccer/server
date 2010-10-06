var sys = require("sys"), 
   uuid = require("uuid"); 

var  express = require('express');

var    Group = require('./lib/group'),
   GroupPool = require('./lib/groupPool');

exports.create = function() {
  var app   = express.createServer(
    express.logger()
  );
  
  app.configure(function() {
    app.use(express.methodOverride());
    // app.use(express.bodyDecoder());
  });
  
  app.groupPool = GroupPool();
    
  app.post('/clients', function(req, res) {
    var id = uuid.generate("ascii").replace(/-/g, "");
    app.groupPool.addUser(id)
    res.redirect("http://" + req.headers.host + "/clients/" + id, 303);
  });
  
  app.get('/clients/:id', function(req, res) {
    res.send({uri: "/clients/" + req.params.id}, 
             {'Content-Type': 'application/json'});
  });
  
  app.put('/clients/:id/environment', function(req, res) {
    // app.groupPool.updateUser(req.params.id, req.body);
    
    res.send(200);
  });
  
  app.post("/clients/:id/action/:mode", function(req, res) {
    var group = app.groupPool.groupForUser(req.params.id);
    if (!group) {
      res.send(412);
    }
    
    sys.puts("group ok");
    var rawBody = "";
    req.addListener("data", function(chunk) {rawBody += chunk});
    req.addListener("end", function() {
      sys.puts("data ok");
      group.send({
        mode: req.params.mode,
        payload: rawBody,
        success: function(content) { sys.puts("success") },
        error: function() { }
      });
      
      sys.puts("redirect");
      res.redirect("http://" + req.headers.host + "/client/12/action/distribute/12", 303);
    });
  });
  
  app.get("/client/12/action/distribute/12", function(req, res) {
    setTimeout(function() {
      res.send(200);  
    }, 1000);
    
  });
  
  
  
  app.get("/clients/:id/action/:mode", function(req, res) {
    var group = app.groupPool.groupForUser(req.params.id);
        
    if (!group) {
      res.send(412);
    }
    
    group.receive({
      mode: req.params.mode,
      success: function(content) { res.send(content); },
      error: function() { res.send(204); }
    });
  });
  
  return app;
}