
var    sys = require("sys");
 
module.exports = {  
  'POST client': function(assert) {
    var server = require("../server").create();
    assert.response(server, {url: "/client", method: "POST"}, {status: 303}, 
        function(res) {
          assert.isNotNull(res.headers.location);                 
        });
  },  
  
  'GET client/:id': function(assert) {
    var clientUrl = "";
    var server = require("../server").create();
    
    assert.response(
        server, {url: "/client", method: "POST"}, 
        {status: 303}, 
        function(res) {
          clientUrl = res.headers.location;                 
          
          assert.response(server, 
            {url: clientUrl, method: "GET"}, 
            {status: 200, body: '{"uri":"' + clientUrl + '"}'});
        });
  },
  
  'PUT client/:id/environment': function(assert) { 
    var server = require("../server").create();
    
    body = '{"name": "robert"}';
    assert.response(server, 
      {url: "/client/1234567/environment", method:"PUT", 
                data: body, headers: { 'Content-Type': "application/json"}}, 
      {status: 200});
  },
  
  'GET client/:id/environment/:mode': function(assert) {
    var server2 = require("../server").create();
    // server2.groupPool.clear();
    // server2.groupPool.addUser("123456");

    assert.response(
      server2, 
      {url: "/client/123456/action/distribute"},
      {status: 404}
    );  
  }
  
  
}