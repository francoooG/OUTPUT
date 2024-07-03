CREATE TABLE `dbsalesv2.5g211`.`rpt_masterlist` (
  `report_id` INT NOT NULL AUTO_INCREMENT,
  `description` VARCHAR(100) NULL,
  `reportgenerationDate` DATETIME NULL,
  PRIMARY KEY (`report_id`));

CREATE TABLE `dbsalesv2.5g211`.`rpt_sales` (
  `report_id` INT NOT NULL,
  `productLine` VARCHAR(50) NOT NULL,
  `product` VARCHAR(70) NOT NULL,
  `country` VARCHAR(50) NOT NULL,
  `office` VARCHAR(10) NOT NULL,
  `salesrepresentative` INT NOT NULL,
  `month` INT(4) NOT NULL,
  `year` INT(4) NOT NULL,
  `total_sales` DECIMAL(9,2) NULL,
  PRIMARY KEY (`report_id`, `productLine`, `country`, `product`, `office`, `salesrepresentative`, `month`, `year`),
  CONSTRAINT `FK88_8801`
    FOREIGN KEY (`report_id`)
    REFERENCES `dbsalesv2.5g211`.`rpt_masterlist` (`report_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION);



-- Sales Report View Start -- 
CREATE VIEW rptview_sales AS
SELECT 		pl.productLine, p.productName,
			oc.country,
			oc.officeCode,
			c.salesRepEmployeeNumber,
			MONTH(o.orderDate) 								 AS MONTH,
			YEAR(o.orderDate) 								 AS YEAR,
			ROUND(SUM(od.quantityOrdered * od.priceEach), 2) AS total_sales,
			ROUND(SUM(od.quantityOrdered * COALESCE(pp.MSRP, pw.MSRP)), 2) AS total_original_price,
            ROUND((od.priceEach - COALESCE(pp.MSRP, pw.MSRP))*od.quantityOrdered,2) AS total_discount_or_markup
FROM 		orderdetails od JOIN products p 				 ON od.productCode = p.productCode
							JOIN product_productlines pl 	 ON p.productCode = pl.productCode
							JOIN orders o 					 ON od.orderNumber = o.orderNumber
							JOIN customers c 				 ON o.customerNumber = c.customerNumber
							JOIN salesRepAssignments sra 	 ON (c.salesRepEmployeeNumber = sra.employeeNumber AND
																 c.officeCode = sra.officeCode 				   AND
																 c.startDate = sra.startdate
																)
							JOIN offices oc					 ON oc.officeCode = sra.officeCode
                            LEFT JOIN product_wholesale pw		 ON od.productCode = pw.productCode
                            LEFT JOIN product_pricing pp		 ON od.productCode = pp.productCode
                            LEFT JOIN current_products cp		 ON od.productCode = cp.productCode
GROUP BY pl.productLine, p.productName, oc.country, oc.officeCode, c.salesRepEmployeeNumber, pw.MSRP, pp.MSRP, od.priceEach, od.quantityOrdered, MONTH(o.orderDate), YEAR(o.orderDate)
ORDER BY pl.productLine, p.productName, oc.country, oc.officeCode, c.salesRepEmployeeNumber, pw.MSRP, pp.MSRP, od.priceEach, od.quantityOrdered, MONTH(o.orderDate), YEAR(o.orderDate);

-- Sales Report View End -- 


-- Event to Generate the Sales Report Start--
DELIMITER $$
CREATE EVENT generate_salesreport
ON SCHEDULE EVERY 1 MONTH
STARTS '2024-07-01'
DO
BEGIN
	DECLARE report_desc VARCHAR(100);
    DECLARE reportID 	INT;
    
    SET report_desc := CONCAT("Sales Report for ", MONTH (NOW()), "month on year", YEAR (NOW()));
    INSERT INTO rpt_masterlist (description, reportgenerationDate) VALUES (report_desc, NOW());
    SELECT MAX(report_ID) INTO reportID FROM rpt_masterlist;
    
    INSERT INTO rpt_sales
		SELECT reportID, rs.*
        FROM rptview_sales rs
        WHERE month = MONTH(NOW())
        AND year = YEAR(NOW());
    
END $$
DELIMITER ;

-- Event to Generate the Sales Report End--




  CREATE TABLE `dbsalesv2.5g211`.`rpt_quantityordered` (
  `report_id` INT NOT NULL,
  `productLine` VARCHAR(50) NOT NULL,
  `product` VARCHAR(70) NOT NULL,
  `country` VARCHAR(50) NOT NULL,
  `office` VARCHAR(10) NOT NULL,
  `salesrepresentative` INT NOT NULL,
  `month` INT(2) NOT NULL,
  `year` INT(2) NOT NULL,
  `quantityordered` INT NULL,
  PRIMARY KEY (`report_id`, `productLine`, `product`, `country`, `office`, `salesrepresentative`, `month`, `year`),
  CONSTRAINT `FK88_8808`
    FOREIGN KEY (`report_id`)
    REFERENCES `dbsalesv2.5g211`.`rpt_masterlist` (`report_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION);
    
    
-- Generate report in SQL

CREATE VIEW rptview_quantityordered AS
SELECT		pl.productLine, p.productName,
			oc.country,
            oc.officeCode,
            c.salesRepEmployeeNumber,
			MONTH(o.orderDate) 								 	AS MONTH,
			YEAR(o.orderDate) 								 	AS YEAR,
			ROUND(SUM(od.quantityOrdered),2)					AS total_quantityordered
FROM 		orderdetails od JOIN products p 					ON od.productCode = p.productCode
							JOIN product_productlines pl		ON p.productCode = pl.productCode
                            JOIN orders	o						ON od.orderNumber = o.orderNumber								
                            JOIN customers c					ON o.customerNumber = c.customerNumber
                            JOIN salesRepAssignments sra 		ON ( c.salesRepEmployeeNumber = sra.employeeNumber AND
																	 c.officeCode			  = sra.officeCode	   AND
																	 c.startDate			  = sra.startDate	   
																   )
							JOIN offices oc						ON oc.officeCode = sra.officeCode

GROUP BY 	pl.productLine, p.productName, oc.country, oc.officeCode,c.salesRepEmployeeNumber, MONTH(o.orderDate),YEAR(o.orderDate)
ORDER BY 	pl.productLine, p.productName, oc.country, oc.officeCode,c.salesRepEmployeeNumber, MONTH(o.orderDate),YEAR(o.orderDate);


-- EVENT TO GENERATE THE QUANTITYORDERED REPORT
DELIMITER $$
CREATE EVENT generate_quantityOrderedReport
ON SCHEDULE EVERY 1 MONTH
STARTS '2024-07-01'
DO
BEGIN
    DECLARE report_desc VARCHAR(100);
    DECLARE reportID INT;
    
    SET report_desc = CONCAT("Quantity Ordered Report for ", MONTH(NOW()), "month on year", YEAR(NOW()));
	INSERT INTO rpt_masterlist (description, reportgenerationDate) VALUES (report_desc, NOW());
    SELECT MAX(report_ID) INTO reportID FROM rpt_masterlist;
    
    -- Create Data
    INSERT INTO rpt_quantityordered
    SELECT 	reportID, rs.*
	FROM 	rptview_quantityordered rs
	WHERE month = MONTH(NOW())
	AND year = YEAR(NOW());
    

END$$
DELIMITER ;





-- Turnaround Time Report View Start --
CREATE VIEW rptview_turnaround_time AS
SELECT     oc.country,
           oc.officeCode,
           MONTH(o.orderDate) AS month,
           YEAR(o.orderDate) AS year,
           AVG(DATEDIFF(o.shippedDate, o.orderDate)) AS avg_turnaround_time
FROM       orders o
JOIN       offices oc ON oc.officeCode = o.customerNumber
GROUP BY   oc.country, oc.officeCode, MONTH(o.orderDate), YEAR(o.orderDate)
ORDER BY   oc.country, oc.officeCode, MONTH(o.orderDate), YEAR(o.orderDate);

-- Turnaround Time Report View End --


-- Event to Generate the Turnaround Time Report Start --
DELIMITER $$
CREATE EVENT generate_turnaround_time_report
ON SCHEDULE EVERY 1 MONTH
STARTS '2024-07-01'
DO
BEGIN
    DECLARE report_desc VARCHAR(100);
    DECLARE reportID INT;
    
    SET report_desc := CONCAT("Turnaround Time Report for ", MONTH(NOW()), " month on year ", YEAR(NOW()));
    INSERT INTO rpt_masterlist (description, reportgenerationDate) VALUES (report_desc, NOW());
    SELECT MAX(report_ID) INTO reportID FROM rpt_masterlist;
    
    INSERT INTO rpt_turnaround_time
        SELECT reportID, rt.*
        FROM rptview_turnaround_time rt
        WHERE month = MONTH(NOW())
        AND year = YEAR(NOW());
    
END $$
DELIMITER ;
-- Event to Generate the Turnaround Time Report End --



-- Pricing Variation Report View Start --
-- Used the LAG function to access the previous price of the product. --
-- PARTITION BY p.productCode: Process each product individually. --

CREATE VIEW rptview_pricing_variation AS
SELECT		pl.productLine,
			p.productName,
			MONTH(NOW()) AS MONTH,
			YEAR(NOW()) AS YEAR,
			ROUND(AVG((p.buyPrice - prev_p.prev_buyPrice) / prev_p.prev_buyPrice * 100), 2) AS avg_pricing_variation
FROM 		products p 		JOIN productlines pl ON p.productCode = pl.productLine
							LEFT JOIN (	SELECT productCode,
											   buyPrice AS prev_buyPrice,
											   YEAR(NOW()) AS YEAR,
											   MONTH(NOW()) - 1 AS MONTH
										FROM products
										WHERE MONTH(NOW()) - 1 = MONTH(NOW()) - 1
									  ) prev_p ON p.productCode = prev_p.productCode 
											   AND prev_p.YEAR = YEAR(NOW())
											   AND prev_p.MONTH = MONTH(NOW()) - 1
GROUP BY pl.productLine, p.productName, MONTH, YEAR
ORDER BY pl.productLine, p.productName, MONTH, YEAR;


-- Pricing Variation Report View End --


-- Event to Generate the Pricing Variation Report Start --
DELIMITER $$
CREATE EVENT generate_pricing_variation_report
ON SCHEDULE EVERY 1 MONTH
STARTS '2024-07-01'
DO
BEGIN
    DECLARE report_desc VARCHAR(100);
    DECLARE reportID INT;
    
    SET report_desc := CONCAT("Pricing Variation Report for ", MONTH(NOW()), " month on year ", YEAR(NOW()));
    INSERT INTO rpt_masterlist (description, reportgenerationDate) VALUES (report_desc, NOW());
    SELECT MAX(report_ID) INTO reportID FROM rpt_masterlist;
    
    INSERT INTO rpt_pricing_variation
        SELECT reportID, pv.*
        FROM rptview_pricing_variation pv
        WHERE month = MONTH(NOW())
        AND year = YEAR(NOW());
    
END $$
DELIMITER ;
-- Event to Generate the Pricing Variation Report End --