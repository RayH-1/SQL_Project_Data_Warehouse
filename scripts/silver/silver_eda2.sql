-- Checks for NULLs or duplicates in primary key
-- Expectation: No Results

SELECT 
cst_id,
COUNT(*)
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;


-- Retrieves the row number of a certain row by cast_id, but orders it by date so that the most recent date is first
SELECT 
*,
ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_last
FROM silver.crm_cust_info
WHERE cst_id IN ('29449', '29473', '29433', '29483', '29466');



-- Checks for unwanted spaces in the names
-- Expectation: no results
SELECT cst_firstname
FROM silver.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname); -- Trimming removes spaces!

SELECT cst_lastname
FROM silver.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname); -- Trimming removes spaces!


-- Data Standardization & Consistency
SELECT DISTINCT cst_gndr
FROM silver.crm_cust_info;

SELECT DISTINCT cst_marital_status
FROM silver.crm_cust_info;