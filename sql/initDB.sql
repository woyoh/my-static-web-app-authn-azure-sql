SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Customers](
	[CustomerId] [int] NOT NULL,
	[Name] [nvarchar](50) NOT NULL,
	[Location] [nvarchar](50) NOT NULL,
	[Email] [nvarchar](50) NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Customers] ADD PRIMARY KEY CLUSTERED 
(
	[CustomerId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Product](
	[id] [int] NOT NULL,
	[name] [nvarchar](50) NOT NULL,
	[description] [nvarchar](50) NULL,
	[quantity] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Product] ADD PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO

INSERT [dbo].[Product]([id], [name], [description], [quantity]) VALUES (1, N'', N'', 10);
INSERT [dbo].[Product]([id], [name], [description], [quantity]) VALUES (2, N'Sliced bread', N'Loaf of fresh sliced wheat bread', 20);
INSERT [dbo].[Product]([id], [name], [description], [quantity]) VALUES (3, N'Apples', N'Bag of 7 fresh McIntosh apples', 30);
GO

/*
	Create schema
*/
IF SCHEMA_ID('web') IS NULL BEGIN	
	EXECUTE('CREATE SCHEMA [web]');
END
GO

/*
	Create user to be used in the sample API solution
*/
IF USER_ID('NodeFuncApp') IS NULL BEGIN	
	CREATE USER [NodeFuncApp] WITH PASSWORD = 'aN0ThErREALLY#$%TRONGpa44w0rd!';	
END

/*
	Grant execute permission to created users
*/
GRANT EXECUTE ON SCHEMA::[web] TO [NodeFuncApp];
GRANT select,insert,update,delete ON SCHEMA::[dbo] TO [NodeFuncApp];
GO

/*
	Return details on a specific product
*/
CREATE OR ALTER PROCEDURE web.get_product
@Json NVARCHAR(MAX)
AS
SET NOCOUNT ON;
DECLARE @ProductId INT = JSON_VALUE(@Json, '$.ProductId');
SELECT 
	[id], 
	[name], 
	[description], 
	[quantity]
FROM 
	[dbo].[Product] 
WHERE 
	[id] = @ProductId
FOR JSON PATH
GO

/*
	Delete a specific customer
*/
CREATE OR ALTER PROCEDURE web.delete_customer
@Json NVARCHAR(MAX)
AS
SET NOCOUNT ON;
DECLARE @CustomerId INT = JSON_VALUE(@Json, '$.CustomerID');
DELETE FROM [Sales].[Customers] WHERE CustomerId = @CustomerId;
SELECT * FROM (SELECT CustomerID = @CustomerId) D FOR JSON AUTO;
GO

/*
	Update (Patch) a specific customer
*/
CREATE OR ALTER PROCEDURE web.patch_customer
@Json NVARCHAR(MAX)
AS
SET NOCOUNT ON;
DECLARE @CustomerId INT = JSON_VALUE(@Json, '$.CustomerID');
WITH [source] AS 
(
	SELECT * FROM OPENJSON(@Json) WITH (
		[CustomerID] INT, 
		[CustomerName] NVARCHAR(100), 
		[PhoneNumber] NVARCHAR(20), 
		[FaxNumber] NVARCHAR(20), 
		[WebsiteURL] NVARCHAR(256),
		[DeliveryAddressLine1] NVARCHAR(60) '$.Delivery.AddressLine1',
		[DeliveryAddressLine2] NVARCHAR(60) '$.Delivery.AddressLine2',
		[DeliveryPostalCode] NVARCHAR(10) '$.Delivery.PostalCode'	
	)
)
UPDATE
	t
SET
	t.[CustomerName] = COALESCE(s.[CustomerName], t.[CustomerName]),
	t.[PhoneNumber] = COALESCE(s.[PhoneNumber], t.[PhoneNumber]),
	t.[FaxNumber] = COALESCE(s.[FaxNumber], t.[FaxNumber]),
	t.[WebsiteURL] = COALESCE(s.[WebsiteURL], t.[WebsiteURL]),
	t.[DeliveryAddressLine1] = COALESCE(s.[DeliveryAddressLine1], t.[DeliveryAddressLine1]),
	t.[DeliveryAddressLine2] = COALESCE(s.[DeliveryAddressLine2], t.[DeliveryAddressLine2]),
	t.[DeliveryPostalCode] = COALESCE(s.[DeliveryPostalCode], t.[DeliveryPostalCode])
FROM
	[Sales].[Customers] t
INNER JOIN
	[source] s ON t.[CustomerID] = s.[CustomerID]
WHERE
	t.CustomerId = @CustomerId;

DECLARE @Json2 NVARCHAR(MAX) = N'{"CustomerID": ' + CAST(@CustomerId AS NVARCHAR(9)) + N'}'
EXEC web.get_customer @Json2;
GO


CREATE SEQUENCE ProductId
    START WITH 100  
    INCREMENT BY 1 ;  
GO

/*
	Create a new product
*/

CREATE OR ALTER PROCEDURE web.put_product
@Json NVARCHAR(MAX)
AS
SET NOCOUNT ON;
DECLARE @ProductId INT = NEXT VALUE FOR dbo.ProductId;
WITH [source] AS 
(
	SELECT * FROM OPENJSON(@Json) WITH (		
		[Name] NVARCHAR(50), 
		[Description] NVARCHAR(50), 
		[Quantity] INT
	)
)
INSERT INTO [dbo].[Product] 
(
	id, 
	name, 	
	description, 
	quantity
)
SELECT
	@ProductId, 
	Name, 
	Description, 
	Quantity
FROM
	[source]
;

DECLARE @Json2 NVARCHAR(MAX) = N'{"ProductId": ' + CAST(@ProductId AS NVARCHAR(9)) + N'}'
EXEC web.get_product @Json2;
GO

CREATE OR ALTER PROCEDURE web.get_customers
AS
SET NOCOUNT ON;
-- Cast is needed to simplify JSON management on the client side:
-- https://docs.microsoft.com/en-us/sql/relational-databases/json/use-for-json-output-in-sql-server-and-in-client-apps-sql-server
-- as a single JSON result can be returned as chunked into several rows. By casting it into a NVARCHAR(MAX) it will always be
-- returned as one row instead (but with a 2GB limit...which shouldn't be a problem.)
SELECT CAST((
	SELECT 
		[CustomerID], 
		[CustomerName]
	FROM 
		[dbo].[Customers] 
	FOR JSON PATH) AS NVARCHAR(MAX)) AS JsonResult
GO

