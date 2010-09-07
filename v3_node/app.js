var sys = require('sys');

var app = require('./server').create();
app.listen(9292);
  
// var db = new mongo.Db(
//   'test', //dbname
//    new mongo.Server(  'localhost', // host
//                         27017 // port default 27017
//                         , {}), {});
//                         
// db.addListener("error", function(error) {
// sys.puts("Error connecting to mongo -- perhaps it isn't running?"); });
// db.open(function(p_db) {
//   sys.puts("mongo rulez"); 
//   app.db = db;
// });
   