var sys = require("sys"); 
var uuid = require("uuid"); 

var app = require('express').createServer();

exports.create = function() {
  app.db = 0;

  app.get("/", function(req, res) {
    app.db.collection("test", function(err, collection) {
      collection.find(function(err, cursor) {
        cursor.toArray(function(err, docs) {
          sys.puts("Printing docs from Array")
          docs.forEach(function(doc) {
            res.send("Doc from Array " + sys.inspect(doc));
          });
        });
      });
    });
  });
  
  app.post('/client', function(req, res) {
    res.redirect("/client/" + uuid.generate("asci"));
  });
  
  app.get('/client/:id', function(req, res) {
    res.send({uri: "/client/" + req.params.id}, {'Content-Type': 'application/json'});
  });
  
  app.put('/client/:id/environment', function(req, res) {
    var data = ""; 
    req.addListener('data', function(chunk) {
      data += chunk;
    });
    
    req.addListener('end', function() {
      sys.puts(data);
      res.send(200);
    });
        
  });
  
  return app;
}