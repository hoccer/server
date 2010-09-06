var server = require("../server").create();

module.exports = {  
  'test post#client': function(assert) {
    assert.response(server, {url: "/client", method: "POST"}, {status: 302});
  },  
  
  'test get#client/:id': function(assert) {
    assert.response(server, {url: "/client/1234567", method: "GET"}, {status: 200, body: '{"uri":"/client/1234567"}'});
  },
  
  'test put#client/:id/environment': function(assert) { 
    body = '{"name": "robert"}';
    assert.response(server, {url: "/client/1234567/environment", method:"PUT", data: body}, {status: 200});
  }
  
}