USE db_complaints_staging 

--Query used to Populate core layer with transformed data from Staging layer
--dim_Issue
INSERT INTO db_complaints_core.dbo.dim_Issue(issue, sub_issue)
SELECT DISTINCT
	issue,
	sub_issue
FROM tbl_Staging

--dim_Product
INSERT INTO db_complaints_core.dbo.dim_Product(product, sub_product)
SELECT DISTINCT 
	product,
	sub_product
FROM tbl_Staging

--dim_Response - due to high cardinality of attributes dim_Response consists of cartesian product of possible values in each of those attributes

INSERT INTO db_complaints_core.dbo.dim_Response(response, public_response, on_time, consumer_disputed)
SELECT 
	company_response,
		CASE 
		WHEN public_response = 'Yes' THEN 1
		ELSE 0 END,
	 CASE 
		WHEN on_time = 'Yes' THEN 1
		ELSE 0 END,
	consumer_disputed
FROM 
	(SELECT DISTINCT company_response FROM tbl_Staging)  as company_response_options
CROSS JOIN
	(SELECT DISTINCT on_time FROM tbl_Staging) as on_time_options
CROSS JOIN
	(SELECT DISTINCT consumer_disputed FROM tbl_Staging) as consumer_disputed_options
CROSS JOIN
	(SELECT DISTINCT public_response FROM tbl_Staging) as public_response_options

--dim_Date - every possible date from minimum to maximum of what is in data
CREATE TABLE #tempdates(
	dateday date
	)

DECLARE @mindate date
SET @mindate = (SELECT MIN(CAST (date_received AS date)) FROM tbl_Staging)

DECLARE @maxdate date
SET @maxdate = 
	CASE 
		WHEN (SELECT MAX(CAST (date_received AS date)) FROM tbl_Staging) >= (SELECT MAX(CAST (date_sent_to_company AS date)) FROM tbl_Staging) 
			THEN (SELECT MAX(CAST (date_received AS date)) FROM tbl_Staging)
		ELSE 
			(SELECT MAX(CAST (date_sent_to_company AS date)) FROM tbl_Staging) 
		END

INSERT INTO #tempdates(dateday)
SELECT
	DATEADD(DAY,value,@mindate)
FROM 
	GENERATE_SERIES(0,DATEDIFF(DAY, @mindate, @maxdate),1)

SET DATEFIRST 1

INSERT INTO db_complaints_core.dbo.dim_Date(date_key, date, day_of_week, month, month_num, quarter, year)
SELECT 
	YEAR(dateday) * 10000 + MONTH(dateday) * 100 + DAY(dateday),
	dateday,
	DATENAME(WEEKDAY,dateday) as day_of_week,
	DATENAME(MONTH,dateday) as month,
	MONTH(dateday) as month_num,
	DATEPART(QUARTER,dateday) as quarter,
	DATEPART(YEAR,dateday) as year
FROM #tempdates

--SELECT * FROM db_complaints_core.dbo.dim_Date
DROP table #tempdates 

--dim_Address
DECLARE @StateCodes VARCHAR(MAX) = 'AL,AK,AZ,AR,CA,CO,CT,DE,DC,FL,GA,HI,ID,IL,IN,IA,KS,KY,LA,ME,MD,MA,MI,MN,MS,MO,MT,NE,NV,NH,NJ,NM,NY,NC,ND,OH,OK,OR,PA,PR,RI,SC,SD,TN,TX,UT,VT,VA,WA,WV,WI,WY,Unknown/Undisclosed'

DELETE TOP (1) FROM tbl_Zipcodes WHERE zip = 'Unknown/Undisclosed' AND state = 'Unknown/Undisclosed'

INSERT INTO db_complaints_core.dbo.dim_Address(zip_code,city,county,state,longitude,latitude)
SELECT 'Unknown/Undisclosed', 'Unknown/Undisclosed', 'Unknown/Undisclosed', value, 'Unknown/Undisclosed', 'Unknown/Undisclosed' FROM STRING_SPLIT(@StateCodes, ',')

INSERT INTO db_complaints_core.dbo.dim_Address(zip_code,city,county,state,longitude,latitude)
SELECT DISTINCT zip, city, county, state, longitude, latitude
FROM tbl_Zipcodes
WHERE state IN (SELECT value FROM STRING_SPLIT(@StateCodes, ','))

--fact_Complaint

INSERT INTO db_complaints_core.dbo.fact_Complaint(original_id,received_date_key,sent_to_company_date_key,company,submitted_via,consumer_consent_status,product_id,issue_id,response_id,zip_code_id)
SELECT 
complaint_id,
D1.date_key,
D2.date_key,
company,
submitted_via,
consumer_consent_status,
P.product_id,
I.issue_id,
R.response_id,
A.zip_code_id
FROM tbl_Staging as S
LEFT JOIN db_complaints_core.dbo.dim_Issue as I 
	ON 
	S.issue = I.issue AND 
	S.sub_issue = I.sub_issue
LEFT JOIN db_complaints_core.dbo.dim_Product as P 
	ON 
	S.product = P.product AND 
	S.sub_product = P.sub_product
LEFT JOIN db_complaints_core.dbo.dim_Response as R 
	ON 
	S.company_response = R.response AND 
	(S.public_response = CASE WHEN R.public_response = 0 THEN 'No' ELSE 'Yes' END) AND 
	(S.on_time = CASE WHEN R.on_time = 0 THEN 'No' ELSE 'Yes' END) AND
	S.consumer_disputed = R.consumer_disputed
LEFT JOIN db_complaints_core.dbo.dim_Date as D1
	ON
	S.date_received = D1.date
LEFT JOIN db_complaints_core.dbo.dim_Date as D2
	ON
	S.date_sent_to_company = D2.date
LEFT JOIN db_complaints_core.dbo.dim_Address as A
	ON
	S.zip_code = A.zip_code AND S.state = A.state