
--                 			sales_order_module								product_management_module		employee_management_module				logistics_module					payment_receivables_modules
-- orders      					C,R,U,D       										No Access          				No Access							R,U									R (orderNumber)
-- orderdetails      			C,R,U,D  											No Access       				No Access							R,U									No Access
-- products						R,U (productCode, productName)						C,R,U,D							No Access							R (productName, productCode)		No Access
-- product_productlines			R,U (productLine)									C,R,U,D							No Access							No Access							No Access
-- productlines					R (productLine)										C,R,U,D							No Access							No Access							No Access
-- current_products				R,U	(productCode, quantityInStock)					C,R,U,D							No Access							No Access							No Access
-- product_wholesale			R,U (productCode, MSRP)								C,R,U,D							No Access							No Access							No Access
-- product_retail				R													C,R,U,D							No Access							No Access							No Access
-- product_pricing				R,U (productCode, MSRP)								C,R,U,D							No Access							No Access							No Access
-- customers					R (customerNumber, creditLimit)						No Access						No Access							No Access							R (customerNumber, totalOrders)
-- discontinued_products		No Access											C,R,U,D							No Access							No Access							No Access
-- employees					No Access											No Access						C,R,U,D								No Access							No Access
-- salesRepAssignments			No Access											No Access						C,R,U,D								No Access							No Access
-- salesRepresentatives			No Access											No Access						C,R,U,D								No Access							No Access				
-- Non_SalesRepresentatives		No Access											No Access						C,R,U,D								No Access							No Access
-- offices						No Access											No Access						R (officeCode, city, country)		No Access							No Access
-- departments					No Access											No Access						R,U									No Access							No Access
-- sales_managers				No Access											No Access						C,R,U,D								No Access							No Access
-- inventory_managers			No Access											No Access						C,R,U,D								No Access							No Access
-- job_titles_list				No Access											No Access						C,R,U,D								No Access							No Access
-- payments						No Access											No Access						No Access							No Access							R,U,D
-- shipments					No Access											No Access						No Access							C,R,U,D								No Access
-- shipmentStatus				No Access											No Access						No Access							C,R,U,D								No Access
-- ref_shipmentstatus			No Access											No Access						No Access							R									No Access
-- couriers						No Access											No Access						No Access							C,R,U,D								No Access
-- riders						No Access											No Access						No Access							C,R,U,D								No Access

-- SALES_ORDER_MODULE
CREATE USER sales_order_module IDENTIFIED BY 'DBADM211';

CREATE VIEW product_sales_order AS
	SELECT p.productCode, p.productName, ppl.productLine, cp.product_type,
		CASE 
			WHEN cp.product_type = 'W' THEN pw.MSRP
			WHEN cp.product_type = 'R' THEN pp.MSRP
			ELSE NULL
		END AS MSRP, cp.quantityInStock
	FROM products p LEFT JOIN current_products cp ON p.productCode = cp.productCode
					LEFT JOIN product_wholesale pw ON p.productCode = pw.productCode
					LEFT JOIN product_pricing pp ON p.productCode = pp.productCode
					LEFT JOIN product_productlines ppl ON p.productCode = ppl.productCode;

CREATE VIEW customers_sales_order AS
	SELECT customerNumber, creditLimit
    FROM customers;
    
CREATE VIEW products_view AS
	SELECT productCode, productName
    FROM products;   
    
CREATE VIEW product_productlines_view AS
	SELECT productLine
    FROM product_productlines;    
    
CREATE VIEW productlines_view AS
	SELECT productLine
    FROM productlines;    
    
CREATE VIEW current_products_view AS
	SELECT productCode, quantityInStock
    FROM current_products;
    
CREATE VIEW product_wholesale_view AS
	SELECT productCode, MSRP
    FROM product_wholesale;
    
CREATE VIEW current_products_view AS
	SELECT productCode, quantityInStock
    FROM current_products;
    
CREATE VIEW product_pricing_view AS
	SELECT productCode, MSRP
    FROM product_pricing;
    
GRANT SELECT, INSERT, UPDATE, DELETE 	ON orders 							    TO sales_order_module;
GRANT SELECT, INSERT, UPDATE, DELETE 	ON orderdetails						    TO sales_order_module;
GRANT SELECT, UPDATE 	                ON product_sales_order 					TO sales_order_module;
GRANT SELECT, UPDATE 	                ON products_view 						TO sales_order_module;
GRANT SELECT, UPDATE 	                ON product_productlines_view 			TO sales_order_module;
GRANT SELECT, UPDATE 	                ON productlines_view 					TO sales_order_module;
GRANT SELECT, UPDATE 	                ON current_products_view 				TO sales_order_module;
GRANT SELECT, UPDATE 	                ON product_wholesale_view 				TO sales_order_module;
GRANT SELECT, UPDATE 	                ON current_products_view 				TO sales_order_module;
GRANT SELECT, UPDATE 	                ON product_pricing_view 				TO sales_order_module;
GRANT SELECT				 	        ON customers_sales_order 			    TO sales_order_module;


-- PRODUCT_MANAGEMENT_MODULE
CREATE USER product_management_module IDENTIFIED BY 'DBADM211';

GRANT SELECT, INSERT, UPDATE, DELETE 	ON products					TO product_management_module;
GRANT SELECT, INSERT, UPDATE, DELETE 	ON product_productLines		TO product_management_module;
GRANT SELECT, INSERT, UPDATE, DELETE 	ON productlines				TO product_management_module;
GRANT SELECT, INSERT, UPDATE, DELETE 	ON current_products			TO product_management_module;
GRANT SELECT, INSERT, UPDATE, DELETE 	ON product_wholesale		TO product_management_module;
GRANT SELECT, INSERT, UPDATE, DELETE 	ON product_retail			TO product_management_module;
GRANT SELECT, INSERT, UPDATE, DELETE 	ON product_pricing			TO product_management_module;
GRANT SELECT, INSERT, UPDATE, DELETE 	ON discontinued_products	TO product_management_module;

-- EMPLOYEE_MANAGEMENT_MODULE
CREATE USER employee_management_module IDENTIFIED BY 'DBADM211';

CREATE VIEW offices_employee_management AS
	SELECT officeCode, city, country FROM offices;

GRANT SELECT, INSERT, UPDATE, DELETE 	ON employees 					TO employee_management_module;
GRANT SELECT, INSERT, UPDATE, DELETE	ON salesRepAssignments 			TO employee_management_module;
GRANT SELECT, INSERT, UPDATE, DELETE	ON salesRepresentatives 		TO employee_management_module;
GRANT SELECT, INSERT, UPDATE, DELETE	ON Non_SalesRepresentatives 	TO employee_management_module;
GRANT SELECT, UPDATE 					ON departments 					TO employee_management_module;
GRANT SELECT							ON offices_employee_management 	TO employee_management_module;
GRANT SELECT, INSERT, UPDATE, DELETE	ON sales_managers			 	TO employee_management_module;
GRANT SELECT, INSERT, UPDATE, DELETE	ON inventory_managers		 	TO employee_management_module;
GRANT SELECT, INSERT, UPDATE, DELETE	ON job_titles_list			 	TO employee_management_module;