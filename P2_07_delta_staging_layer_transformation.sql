USE db_complaints_staging 

--Populate core layer with delta load data already transformed, most of the query is similar to P2_03 query
--dim_Issue
INSERT INTO db_complaints_core.dbo.dim_Issue(issue, sub_issue)
SELECT DISTINCT
	S.issue,
	S.sub_issue
FROM tbl_Staging AS S
LEFT OUTER JOIN db_complaints_core.dbo.dim_Issue AS I ON S.issue = I.issue AND S.sub_issue = I.sub_issue
WHERE I.issue_id IS NULL


--dim_Product
INSERT INTO db_complaints_core.dbo.dim_Product(product, sub_product)
SELECT DISTINCT 
	S.product,
	S.sub_product
FROM tbl_Staging AS S
LEFT OUTER JOIN db_complaints_core.dbo.dim_Product AS I ON S.product = I.product AND S.sub_product = I.sub_product
WHERE I.product_id IS NULL
GO
--dim_Date
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
FROM #tempdates temp
WHERE dateday NOT IN (SELECT date FROM db_complaints_core.dbo.dim_Date)
GO
DROP TABLE #tempdates 

--fact_Complaint
SELECT * FROM db_complaints_core.dbo.fact_Complaint

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