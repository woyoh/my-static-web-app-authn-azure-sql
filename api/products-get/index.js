var Connection = require('tedious').Connection;
var Request = require('tedious').Request
var TYPES = require('tedious').TYPES;

module.exports = function (context, req) {
    const method = req.method.toLowerCase();

    var payload = null;
    var entity = "";
    if (req.params.id) {
        entity = "product"
        payload = { "ProductId": req.params.id };            
    } else {
        entity = "products"                
    }
    
    executeSQL(context, method, entity, payload)
}

const executeSQL = (context, verb, entity, payload) => {
    var result = "";    
    const paramPayload = (payload != null) ? JSON.stringify(payload) : '';
    context.log("payload: " + payload);

    let config = {
        server: process.env["db_server"],
        authentication: {
            type: 'default',
            options: {
                userName: process.env["db_user"],
                password: process.env["db_password"],
            }
        },
        options: {
            database: process.env["db_database"],
            encrypt: true,
            connectTimeout: 15000,
            validateBulkLoadParameters: true
        }
    };
    
    // Create Connection object
    const connection = new Connection(config);

    // // Call Procedure
    // const request = new Request(`web.${verb}_${entity}`, (err) => {
    //     if (err) {
    //         context.log.error(err);            
    //         context.res.status = 500;
    //         context.res.body = "Error executing T-SQL command";
    //     } else {
    //         context.res = {
    //             body: result
    //         }
    //     }
    //     context.done();
    //     console.log("Context BODY: " + context.res.body);
    // });    
    // if (payload) {
    //     request.addParameter('Json', TYPES.NVarChar, paramPayload, Infinity);
    // }

    // Execute SQL
    var request = new Request("select * from dbo.Product", function(err) {
        if (err) {
            console.log(err);
            context.res.status = 500;
            context.res.body = "Error executing SQL command";
       } else {
            context.res = {
                body: result
            }
        }
        context.done();
        console.log("Result:" + result);
    });
    
    // Handle 'connect' event
    connection.on('connect', err => {
        if (err) {
            context.log.error(err);              
            context.res.status = 500;
            context.res.body = "Error connecting to Azure SQL query";
            context.done();
        }
        else {
            // connection.callProcedure(request);
            connection.execSql(request);
        }
    });

    // Handle result set sent back from Azure SQL
    request.on('row', columns => {
        columns.forEach(column => {
            result += column.value;
        });
    });

    // Connect
    connection.connect();
}
