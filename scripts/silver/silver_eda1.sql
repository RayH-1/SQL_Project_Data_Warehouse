-- Checks for NULLs or duplicates in primary key
-- Expectation: No Results

SELECT 
cst_id,
COUNT(*)
FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;


-- Retrieves the row number of a certain row by cast_id, but orders it by date so that the most recent date is first
SELECT 
*,
ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_last
FROM bronze.crm_cust_info
WHERE cst_id IN ('29449', '29473', '29433', '29483', '29466');



-- Checks for unwanted spaces in the names
-- Expectation: no results
SELECT cst_firstname
FROM bronze.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname); -- Trimming removes spaces!

SELECT cst_lastname
FROM bronze.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname); -- Trimming removes spaces!


-- Data Standardization & Consistency
SELECT DISTINCT cst_gndr
FROM bronze.crm_cust_info;

SELECT DISTINCT cst_marital_status
FROM bronze.crm_cust_info;

SELECT DISTINCT prd_line
FROM bronze.crm_prd_info;

SELECT DISTINCT cntry 
FROM bronze.erp_loc_a101
ORDER BY cntry;

-- Adjusting table
SELECT
prd_id,
prd_key,
REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id, -- Get the first 5 characters and put it into its own column while replaceing the dash
SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key, -- Get the second part of prd_key and we use length so the SUBSTRING is dynamic
prd_nm,
ISNULL(prd_cost, 0) AS prd_cost, -- Replace null values of prd_cost with 0
CASE WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
	 WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
	 WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'other'
	 WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
	 ELSE 'n/a'
END AS prd_line,-- Use CASE for simple remapping
CAST(prd_start_dt AS DATE) AS prd_start_dt,
CAST(LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)-1 AS DATE) AS prd_end_dt
FROM bronze.crm_prd_info;

/* Check for invalid date orders
We do not want our start date to be before the end date
Potential solution, in the cases where there is a mismatch:
- If end date is missing: make the end date the start date of the next order minus 1
- If start date is missing, take the end date of the previous order and add one
*/

SELECT *
FROM bronze.crm_prd_info
WHERE prd_end_dt < prd_start_dt;

-- Trying out a limited implementation of date shenaningans before implementing it 
SELECT 
prd_id,
prd_key,
prd_nm,
prd_start_dt,
prd_end_dt,
LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)-1 AS prd_end_dt_test
FROM bronze.crm_prd_info
WHERE prd_key in ('AC-HE-HL-U509-R','AC-HE-HL-U509');



-- >> Sales = Quantity * Price
-- >> Values must not be NULL, zero, or negative

SELECT DISTINCT
sls_sales,
sls_quantity,
sls_price
FROM bronze.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
ORDER BY sls_sales, sls_quantity, sls_price;

/*
Since there are mismatches, it is best to ask around to figure out why the data is like that at source.
Afterwards it will help you make some rules:
1. If sales is negative, zero, or null - do Quantity*Price
2. If price is zero or null, calculate using Sales/Quantity
3. If price is negative, convert to a positive value
*/


SELECT DISTINCT
sls_sales AS old_sales,
sls_quantity AS old_quanity,
sls_price AS old_price,
CASE WHEN sls_sales IS NULL OR sls_sales <= 0 OR (sls_sales != sls_quantity * ABS(sls_price)) 
		THEN sls_quantity * ABS(sls_price)
	 ELSE sls_sales
END AS sls_sales,
CASE WHEN sls_price IS NULL OR sls_price <= 0  
		THEN ABS(sls_sales) / ABS(sls_quantity) 
	 ELSE sls_price
END AS sls_price
FROM bronze.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
ORDER BY sls_sales, sls_quantity, sls_price;