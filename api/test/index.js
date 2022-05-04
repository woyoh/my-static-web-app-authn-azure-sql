// module.exports = async function (context, req) {
//     context.log('JavaScript HTTP trigger function processed a request.');

//     const name = (req.query.name || (req.body && req.body.name));
//     const responseMessage = "11111111111111111111";

//     context.res = {
//         // status: 200, /* Defaults to 200 */
//         body: responseMessage
//     };
// }


var Connection = require('tedious').Connection;
var Request = require('tedious').Request
var TYPES = require('tedious').TYPES;

module.exports = async function (context, req) {

    var config = {
      server: "helloserver01.database.windows.net", // or "localhost"
      options: {
            database: "TutorialDB",
      },
      authentication: {
        type: "default",
        options: {  
          userName: "NodeFuncApp",
          password: "aN0ThErREALLY#$%TRONGpa44w0rd!",
        }
      }
    };
  
    var connection = new Connection(config);
  
    // Setup event handler when the connection is established. 
    connection.on('connect', function(err) {
      if(err) {
        console.log('Error: ', err)
      }
      // If no error, then good to go...
      var request = new Request("select * from dbo.Customers", function(err, rowCount) {
        if (err) {
          console.log(err);
        } else {
          console.log(rowCount + ' rows');
        }
      });
  
      request.on('row', function(columns) {
        columns.forEach(function(column) {
          console.log(column.value);
        });
      });
  
      connection.execSql(request);
    });
  
    // Initialize the connection.
    connection.connect();
}

 