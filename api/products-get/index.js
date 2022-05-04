var Connection = require('tedious').Connection;
var Request = require('tedious').Request
var TYPES = require('tedious').TYPES;

module.exports = function (context, req) {
    const method = req.method.toLowerCase();

    var payload = null;
    var entity = "";
    if (req.params.id) {
        entity = "customer"
        payload = { "CustomerId": req.params.id };            
    } else {
        entity = "customers"                
    }
    
    executeSQL(context, method, entity, payload)
}

const executeSQL = (context, verb, entity, payload) => {
    var result = "";    
    const paramPayload = (payload != null) ? JSON.stringify(payload) : '';
    context.log("payload: " + payload);

    // Create Connection object
    const connection = new Connection({
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
    });

    // let config = {
    //     server: process.env["db_server"],
    //     authentication: {
    //         type: 'default',
    //         options: {
    //             userName: process.env["db_user"],
    //             password: process.env["db_password"],
    //         }
    //     },
    //     options: {
    //         database: process.env["db_database"],
    //         encrypt: true,
    //         connectTimeout: 15000,
    //         validateBulkLoadParameters: true
    //     }
    // };
    
    // // Create Connection object
    // const connection = new Connection(config);

    // Create the command to be executed
    const request = new Request(`web.${verb}_${entity}`, (err) => {
        if (err) {
            context.log.error(err);            
            context.res.status = 500;
            context.res.body = "Error executing T-SQL command";
        } else {
            context.res = {
                body: result
            }
        }
        context.done();
        console.log("Context BODY: " + context.res.body);
    });    
    if (payload) {
        request.addParameter('Json', TYPES.NVarChar, paramPayload, Infinity);
    }

    // // 1111111111111111111111111111111111111
    // var request = new Request("select * from dbo.Customers", function(err, rowCount) {
    //     if (err) {
    //         console.log(err);
    //     } else {
    //         console.log(rowCount + ' rows');
    //     }
    // });
    
    // Handle 'connect' event
    connection.on('connect', err => {
        if (err) {
            context.log.error(err);              
            context.res.status = 500;
            context.res.body = "Error connecting to Azure SQL query";
            context.done();
        }
        else {
            // Connection succeeded so execute T-SQL stored procedure
            // if you want to executer ad-hoc T-SQL code, use connection.execSql instead
            
            connection.callProcedure(request);
            // connection.execSql(request);
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
