SELECT 
	ci.cst_id,
	ci.cst_key,
	ci.cst_firstname,
	ci.cst_lastname,
	ci.cst_marital_status,
	ci.cst_gndr,
	ci.cst_create_date,
	ca.bdate,
	ca.gen,
	la.cntry
FROM silver.crm_cust_info AS ci -- Start with the master table
LEFT JOIN silver.erp_cust_az12 AS ca
ON		  ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 AS la
ON		  ci.cst_key = la.cid;

-- If you want to check if the above query had any duplicates
SELECT cst_id, COUNT(*) FROM
	(SELECT 
		ci.cst_id,
		ci.cst_key,
		ci.cst_firstname,
		ci.cst_lastname,
		ci.cst_marital_status,
		ci.cst_gndr,
		ci.cst_create_date,
		ca.bdate,
		ca.gen,
		la.cntry
	FROM silver.crm_cust_info AS ci -- Start with the master table
	LEFT JOIN silver.erp_cust_az12 AS ca
	ON		  ci.cst_key = ca.cid
	LEFT JOIN silver.erp_loc_a101 AS la
	ON		  ci.cst_key = la.cid)t
GROUP BY cst_id
HAVING COUNT(*) > 1


-- Check to see if the genders match
SELECT DISTINCT
	ci.cst_gndr,
	ca.gen
FROM silver.crm_cust_info AS ci -- Start with the master table
LEFT JOIN silver.erp_cust_az12 AS ca
ON		  ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 AS la
ON		  ci.cst_key = la.cid
ORDER BY 1,2;

-- change the information from above
SELECT DISTINCT
	ci.cst_gndr,
	ca.gen,
	CASE WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr -- CRM is the Master for gender information
		 ELSE COALESCE(ca.gen, 'n/a')
	END AS new_gen
FROM silver.crm_cust_info AS ci -- Start with the master table
LEFT JOIN silver.erp_cust_az12 AS ca
ON		  ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 AS la
ON		  ci.cst_key = la.cid
ORDER BY 1,2;


-- We want friendly names that are more easy to understand for analysts and business users
CREATE VIEW gold.dim_customers AS ( -- Remember: For the gold dimension we make views not tables!
SELECT 
	ROW_NUMBER() OVER (ORDER BY cst_id) AS customer_key, -- We can create a primary key by creating a new row 
	ci.cst_id AS customer_id,
	ci.cst_key AS customer_number,
	ci.cst_firstname AS first_name,
	ci.cst_lastname AS last_name,
	ci.cst_marital_status AS marital_status,
	CASE WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr -- CRM is the Master for gender information
		 ELSE COALESCE(ca.gen, 'n/a')
	END AS gender,
	ca.bdate AS birthdate,
	ci.cst_create_date AS create_date,
	la.cntry AS country
FROM silver.crm_cust_info AS ci -- Start with the master table
LEFT JOIN silver.erp_cust_az12 AS ca
ON		  ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 AS la
ON		  ci.cst_key = la.cid);

------------------
-- Products Table
CREATE VIEW gold.dim_products AS
SELECT 
	ROW_NUMBER() OVER (ORDER BY pn.prd_start_dt, pn.prd_key) AS product_key,
	pn.prd_id AS product_id,
	pn.cat_id AS category_id,
	pn.prd_key AS product_number,
	pn.prd_nm AS product_name,
	pn.prd_cost AS cost,
	pn.prd_line AS product_line,
	pn.prd_start_dt AS start_date,
	pc.cat AS category,
	pc.subcat AS subcategory,
	pc.maintenance
FROM silver.crm_prd_info pn
LEFT JOIN silver.erp_px_cat_g1v2 pc
ON pn.cat_id = pc.id
WHERE prd_end_dt IS NULL -- NULL means that that is the most up-to-date entry


-- Joining the silver key with the gold surrogate key

SELECT 
	sd.sls_ord_num AS order_number,
	pr.product_key,
	cu.customer_key,
	sd.sls_order_dt AS order_date,
	sd.sls_ship_dt AS shipping_date,
	sd.sls_due_dt AS shipping_date,
	sd.sls_sales,
	sd.sls_quantity,
	sd.sls_price
FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_products pr
ON sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customers cu
ON sd.sls_cust_id = cu.customer_id;