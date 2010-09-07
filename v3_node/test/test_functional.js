
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
  
  'GET client/:id/action/:mode - without partner': function(assert) {
    var server = require("../server").create();
    server.groupPool.addUser("123456");

    assert.response(
      server, 
      {url: "/client/123456/action/distribute"},
      {status: 204}
    );  
  },
  
  'POST client/:id/action/:mode': function(assert) {
    var server = require("../server").create();
    server.groupPool.addUser("123456");

    assert.response(
      server,
      { url: "/client/123456/action/distribute", 
          method: "POST",
          body: '{"Hello": "World"}'
      },
      { status: 402 });
  },
  
  'valid distribution 1-to-1': function(assert) {
    var server = require("../server").create();
    server.groupPool.addUser("123456");
    server.groupPool.addUser("456789");
    
    assert.response(
      server,
      { url: "/client/123456/action/distribute", 
          method: "POST",
          body: '{"Hello":"World"}',
          headers: {"Content-Type": "application/json"}
      },
      { status: 402 }
    );
    
    assert.response(
      server,
      { url: "/client/456789/action/distribute"},
      { status: 200 },
      function(res) {
        assert.equal('{"Hello":"World"}', res.body);
      }
    );
    
    
  }
  
  
}