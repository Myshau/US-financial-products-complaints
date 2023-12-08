USE db_complaints_staging

-- First phase of transformation done in Staging layer, mostly done for purpose of unification of possible categories
-- product transformations
UPDATE tbl_Staging
SET product =
	CASE 
		WHEN product = 'Consumer Loan' THEN 'Consumer loan'
		ELSE product END;
GO
-- sub_product transformations
UPDATE tbl_Staging
SET sub_product = REPLACE(sub_product,'’','''')

UPDATE tbl_Staging
SET sub_product =
	CASE 
		WHEN sub_product = 'I do not know' THEN ''
		WHEN sub_product = 'Traveler''s check or cashier''s check' THEN 'Traveler''s/Cashier''s checks'
		WHEN sub_product = 'Other banking product or service' THEN 'Other bank product/service' 
		ELSE sub_product END;
GO
-- issue transformations
UPDATE tbl_Staging
SET issue =
	CASE 
		WHEN issue = 'Charged fees or interest you didn''t expect' THEN 'Charged fees or interest I didn''t expect'
		WHEN issue = 'Closing your account' THEN 'Closing an account' 
		WHEN issue = 'Closing/Cancelling account' THEN 'Closing an account'
		WHEN issue = 'Credit monitoring or identity theft protection services' THEN 'Credit monitoring or identity protection'
		WHEN issue = 'Customer service / Customer relations' THEN 'Customer service/Customer relations'
		WHEN issue = 'Dealing with your lender or servicer' THEN 'Dealing with my lender or servicer'
		WHEN issue = 'Getting the loan' THEN 'Getting a loan'
		WHEN issue = 'Identity theft protection or other monitoring services' THEN 'Credit monitoring or identity protection'
		WHEN issue = 'Improper use of your report' THEN 'Improper use of my credit report'
		WHEN issue = 'Incorrect information on your report' THEN 'Incorrect information on credit report'
		WHEN issue = 'Other service problem' THEN 'Other service issues'
		WHEN issue = 'Other transaction problem' THEN 'Other transaction issues'
		WHEN issue = 'Overdraft, savings, or rewards features' THEN 'Overdraft, savings or rewards features'
		WHEN issue = 'Problem with overdraft' THEN 'Closing an account'
		WHEN issue = 'Received a loan you didn''t apply for' THEN 'Received a loan I didn''t apply for'
		WHEN issue = 'Struggling to repay your loan' THEN 'Closing an account'
		WHEN issue = 'Trouble using your card' THEN 'Trouble using the card'
		WHEN issue = 'Unable to get your credit report or credit score' THEN 'Unable to get credit report/credit score'
		WHEN issue = 'Unauthorized transactions or other transaction problem' THEN 'Unauthorized transactions/trans. issues'
		WHEN issue = 'Unexpected or other fees' THEN 'Unexpected/Other fees'
		WHEN issue = 'Was approved for a loan, but didn''t receive money' THEN 'Was approved for a loan, but didn''t receive the money'
		ELSE issue END;
GO
-- sub_issue transformations
UPDATE tbl_Staging
SET sub_issue =
	CASE 
		WHEN sub_issue = 'Called before 8am or after 9pm' THEN 'Called outside of 8am-9pm'
		WHEN sub_issue = 'Can''t get other flexible options for repaying your loan' THEN 'Can''t get flexible payment options' 
		WHEN sub_issue = 'Can''t temporarily delay making payments' THEN 'Can''t temporarily postpone payments' 
		WHEN sub_issue = 'Confusing or misleading advertising about the credit card' THEN 'Confusing or misleading advertising about the card' 
		WHEN sub_issue = 'Debt is not yours' THEN '' 
		WHEN sub_issue = 'Debt is not yours' THEN 'Debt is not mine' 
		WHEN sub_issue = 'Debt was already discharged in bankruptcy and is no longer owed' THEN 'Debt was discharged in bankruptcy' 
		WHEN sub_issue = 'Debt was result of identity theft' THEN 'Debt resulted from identity theft' 
		WHEN sub_issue = 'Deposits and withdrawals' THEN 'Deposits or withdrawals' 
		WHEN sub_issue = 'Don''t agree with the fees charged' THEN 'Don''t agree with fees charged' 
		WHEN sub_issue = 'Impersonated attorney, law enforcement, or government official' THEN 'Impersonated an attorney or official' 
		WHEN sub_issue = 'Information is missing that should be on the report' THEN 'Information that should be on the report is missing' 
		WHEN sub_issue = 'Keep getting calls about your loan' THEN 'Keep getting calls about my loan' 
		WHEN sub_issue = 'Investigation took more than 30 days' THEN 'Investigation took too long' 
		WHEN sub_issue = 'Need information about your loan balance or loan terms' THEN 'Need information about my balance/terms' 
		WHEN sub_issue = 'Overcharged for a purchase or transfer you did make with the card' THEN 'Overcharged for something you did purchase with the card' 
		WHEN sub_issue = 'Overdraft charges' THEN 'Overdrafts and overdraft fees' 
		WHEN sub_issue = 'Problem getting your free annual credit report' THEN 'Problem getting my free annual report' 
		WHEN sub_issue = 'Problem with additional add-on products or services purchased with the loan' THEN 'Problem with additional products or services purchased with the loan' 
		WHEN sub_issue = 'Received bad information about your loan' THEN 'Received bad information about my loan' 
		WHEN sub_issue = 'Received unwanted marketing or advertising' THEN 'Receiving unwanted marketing/advertising' 
		WHEN sub_issue = 'Seized or attempted to seize your property' THEN 'Seized/Attempted to seize property' 
		WHEN sub_issue = 'Sued you in a state where you do not live or did not sign for the debt' THEN 'Sued where didn''t live/sign for debt' 
		WHEN sub_issue = 'Talked to a third-party about your debt' THEN 'Talked to a third party about my debt' 
		WHEN sub_issue = 'Threatened to arrest you or take you to jail if you do not pay' THEN 'Threatened arrest/jail if do not pay' 
		WHEN sub_issue = 'Threatened to sue you for very old debt' THEN 'Threatened to sue on too old debt' 
		WHEN sub_issue = 'Trouble with how payments are being handled' THEN 'Trouble with how payments are handled' 
		WHEN sub_issue = 'Used obscene, profane, or other abusive language' THEN 'Used obscene/profane/abusive language' 
		ELSE sub_issue END;
GO 
-- company transformations
UPDATE tbl_Staging
SET company = UPPER(REPLACE(company,'’',''''))
GO

-- zip_code transformations - creating list of common ZIP codes, excluding unusual codes (e.g. military bases outside US territory) and adding corresponding addres attributes like city or county from ZIP list
DECLARE @StateCodes VARCHAR(MAX) = 'AL,AK,AZ,AR,CA,CO,CT,DE,DC,FL,GA,HI,ID,IL,IN,IA,KS,KY,LA,ME,MD,MA,MI,MN,MS,MO,MT,NE,NV,NH,NJ,NM,NY,NC,ND,OH,OK,OR,PA,PR,RI,SC,SD,TN,TX,UT,VT,VA,WA,WV,WI,WY,Unknown/Undisclosed'

INSERT INTO tbl_Zipcodes 
VALUES ('Unknown/Undisclosed','Unknown/Undisclosed','Unknown/Undisclosed','Unknown/Undisclosed','Unknown/Undisclosed','Unknown/Undisclosed')

UPDATE s
SET s.zip_code = 'Unknown/Undisclosed'
FROM tbl_Staging s
LEFT JOIN tbl_Zipcodes z ON s.zip_code = z.zip
WHERE z.zip IS NULL OR z.state NOT IN (SELECT value FROM STRING_SPLIT(@StateCodes, ','));
	
UPDATE tbl_Staging
SET
	city = 'Unknown/Undisclosed',
	county = 'Unknown/Undisclosed',
	longitude = 'Unknown/Undisclosed',
	latitude = 'Unknown/Undisclosed'
FROM tbl_Staging AS s
WHERE s.state IN (SELECT value FROM STRING_SPLIT(@StateCodes, ',')) AND zip_code = 'Unknown/Undisclosed'

--
UPDATE tbl_Staging
SET
	state = z.state,
	city = z.city,
	county = z.county,
	longitude = z.longitude,
	latitude = z.latitude
FROM tbl_Staging as s
LEFT JOIN tbl_Zipcodes as z ON s.zip_code = z.zip
WHERE 
	(s.state NOT IN (SELECT value FROM STRING_SPLIT(@StateCodes, ',')) AND zip_code = 'Unknown/Undisclosed')
	OR
	zip_code != 'Unknown/Undisclosed'

