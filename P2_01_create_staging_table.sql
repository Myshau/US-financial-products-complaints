--Query is based on assumption that Database db_complaints_staging already exists so it needs to be created beforehand
--Create staging table
USE db_complaints_staging

IF EXISTS (SELECT * FROM sys.objects where name = 'tbl_Staging')
BEGIN
	DROP TABLE tbl_Staging
END

ELSE

BEGIN
CREATE TABLE tbl_Staging
(
complaint_id int,
date_received varchar(30),
product varchar(150),
sub_product varchar(150),
issue varchar(150),
sub_issue varchar(150),
public_response varchar(30),
company varchar(150),
consumer_consent_status varchar(50),
submitted_via varchar(30),
date_sent_to_company varchar(30),
on_time varchar(30),
consumer_disputed varchar(30),
company_response varchar(50),
state varchar(50),
zip_code varchar(30),
city varchar(50),
county varchar(50),
longitude varchar(50),
latitude varchar(50),
)
END
GO

--Create ZIP table to map addresses with existing official ZIP codes list from another .csv file
IF EXISTS (SELECT * FROM sys.objects where name = 'tbl_Zipcodes')
BEGIN
	DROP TABLE tbl_Zipcodes
END

ELSE

BEGIN
CREATE TABLE tbl_Zipcodes(
zip varchar(30),
city varchar (50),
county varchar (50),
state varchar (50),
longitude varchar (50),
latitude varchar (50)
)
END
GO