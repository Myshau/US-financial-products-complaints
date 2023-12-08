--Query is based on assumption that Database db_complaints_core already exists so it needs to be created beforehand
--Create Core layer schema for Initial load
--dim_Product
USE db_complaints_core 

IF EXISTS (SELECT * FROM sys.objects where name = 'dim_Product')
BEGIN
	DROP TABLE dim_Product
END

ELSE

BEGIN
CREATE TABLE dim_Product
(
product_id int PRIMARY KEY IDENTITY(1,1),
product varchar(150) NOT NULL,
sub_product varchar(150) NULL
)
END
GO

--dim_date
USE db_complaints_core

IF EXISTS (SELECT * FROM sys.objects where name = 'dim_Date')
BEGIN
	DROP TABLE dim_Date
END

ELSE

BEGIN
CREATE TABLE dim_Date
(
date_key int PRIMARY KEY,
date date NOT NULL,
day_of_week varchar(20) NOT NULL,
month varchar (20) NOT NULL,
month_num tinyint NOT NULL,
quarter varchar(5) NOT NULL,
year smallint NOT NULL
)
END
GO

--dimIssue
USE db_complaints_core

IF EXISTS (SELECT * FROM sys.objects where name = 'dim_Issue')
BEGIN
	DROP TABLE dim_Issue
END

ELSE

BEGIN
CREATE TABLE dim_Issue
(
issue_id int PRIMARY KEY IDENTITY(1,1),
issue varchar(150) NOT NULL,
sub_issue varchar(150) NULL
)
END
GO

--dimResponse
USE db_complaints_core

IF EXISTS (SELECT * FROM sys.objects where name = 'dimResponse')
BEGIN
	DROP TABLE dim_Response
END

ELSE

BEGIN
CREATE TABLE dim_Response
(
response_id int PRIMARY KEY IDENTITY(1,1),
response varchar(50) NOT NULL,
public_response bit NOT NULL,
on_time bit NOT NULL,
consumer_disputed varchar(30) NULL
)
END
GO

--dimAddress
USE db_complaints_core

IF EXISTS (SELECT * FROM sys.objects where name = 'dim_Address')
BEGIN
	DROP TABLE dim_Address
END

ELSE

BEGIN
CREATE TABLE dim_Address
(
zip_code_id int PRIMARY KEY IDENTITY(1,1),
zip_code varchar(30),
city varchar(50) NOT NULL,
county varchar(50) NOT NULL,
state varchar(50) NOT NULL,
longitude varchar(50) NULL,
latitude varchar(50) NULL,
)
END
GO


--Fact table
USE db_complaints_core

IF EXISTS (SELECT * FROM sys.objects where name = 'fact_Complaint')
BEGIN
	DROP TABLE fact_Complaint
END

ELSE

BEGIN
CREATE TABLE fact_Complaint
(
complaint_id int PRIMARY KEY IDENTITY(1,1),
original_id int NOT NULL,
received_date_key int FOREIGN KEY REFERENCES dim_Date(date_key) NOT NULL,
sent_to_company_date_key int FOREIGN KEY REFERENCES dim_Date(date_key) NULL,
company varchar(150) NOT NULL,
submitted_via varchar(30) NULL,
consumer_consent_status varchar(50) NULL,
product_id int FOREIGN KEY REFERENCES dim_Product(product_id),
issue_id int FOREIGN KEY REFERENCES dim_Issue(issue_id),
response_id int FOREIGN KEY REFERENCES dim_Response(response_id),
zip_code_id int FOREIGN KEY REFERENCES dim_Address(zip_code_id)
)
END
GO
