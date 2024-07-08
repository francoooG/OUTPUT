CREATE TABLE `dbsalesV2.5G211`.`rpt_sales` (
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
    REFERENCES `dbsalesV2.5G211`.`rpt_masterlist` (`report_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION);



-- sales Report View Start -- 
CREATE VIEW rptview_sales AS
SELECT 		pl.productLine, p.productName,
			oc.country,
			oc.officeCode,
			c.salesRepEmployeeNumber,
			MONTH(o.orderDate) 								 AS MONTH,
			YEAR(o.orderDate) 								 AS YEAR,
			ROUND(SUM(od.quantityOrdered + od.priceEach), 2) AS total_sales
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
GROUP BY pl.productLine, p.productName, oc.country, oc.officeCode, c.salesRepEmployeeNumber, MONTH(o.orderDate), YEAR(o.orderDate)
ORDER BY pl.productLine, p.productName, oc.country, oc.officeCode, c.salesRepEmployeeNumber, MONTH(o.orderDate), YEAR(o.orderDate);
-- Markups sales View End -- 

-- DROP EVENT generate_salesreport;
-- Event to Generate the sales Report Start--
DELIMITER $$
CREATE EVENT generate_salesreport
ON SCHEDULE EVERY 1 MONTH
STARTS '2024-07-01' -- CHANGE TO START OF MONTH
DO
BEGIN
    DECLARE previousMonth INT;
    DECLARE previousYear INT;
	DECLARE report_desc VARCHAR(100);
    DECLARE reportID 	INT;

    SET previousMonth = MONTH(NOW()) - 1;
    SET previousYear = YEAR(NOW());
    IF (previousMonth = 0) THEN
        SET previousMonth = 12;
        SET previousYear = YEAR(NOW()) - 1;
    END IF;
    
    SET report_desc := CONCAT("sales Report for ", previousMonth, " month on year ", previousYear);
    INSERT INTO rpt_masterlist (description, reportgenerationDate) VALUES (report_desc, NOW());
    SELECT MAX(report_ID) INTO reportID FROM rpt_masterlist;
    
    INSERT INTO rpt_sales
		SELECT reportID, rs.*
        FROM rptview_sales rs
        WHERE month = previousMonth
        AND year = previousYear;
END $$
DELIMITER ;





CREATE TABLE `dbsalesV2.5G211`.`rpt_discounts` (
  `report_id` INT NOT NULL,
  `productLine` VARCHAR(50) NOT NULL,
  `product` VARCHAR(70) NOT NULL,
  `country` VARCHAR(50) NOT NULL,
  `office` VARCHAR(10) NOT NULL,
  `salesrepresentative` INT NOT NULL,
  `month` INT(4) NOT NULL,
  `year` INT(4) NOT NULL,
  `total_discounts` DECIMAL(9,2) NULL,
  PRIMARY KEY (`report_id`, `productLine`, `country`, `product`, `office`, `salesrepresentative`, `month`, `year`),
  CONSTRAINT `FK88_8803`
    FOREIGN KEY (`report_id`)
    REFERENCES `dbsalesV2.5G211`.`rpt_masterlist` (`report_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION);



-- Discounts Report View Start -- 
CREATE VIEW rptview_discounts AS
SELECT 		pl.productLine, p.productName,
			oc.country,
			oc.officeCode,
			c.salesRepEmployeeNumber,
			MONTH(o.orderDate) 								 AS MONTH,
			YEAR(o.orderDate) 								 AS YEAR,
            SUM(ROUND((od.priceEach - COALESCE(pp.MSRP, pw.MSRP))*od.quantityOrdered,2)) AS total_discounts
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
GROUP BY pl.productLine, p.productName, oc.country, oc.officeCode, c.salesRepEmployeeNumber, MONTH(o.orderDate), YEAR(o.orderDate)
HAVING total_discounts < 0
ORDER BY pl.productLine, p.productName, oc.country, oc.officeCode, c.salesRepEmployeeNumber, MONTH(o.orderDate), YEAR(o.orderDate);
-- Markups Discounts View End -- 

DROP EVENT generate_discountsreport;
-- Event to Generate the Discounts Report Start--
DELIMITER $$
CREATE EVENT generate_discountsreport
ON SCHEDULE EVERY 1 MONTH
STARTS '2024-07-01' -- CHANGE TO START OF MONTH
DO
BEGIN
    DECLARE previousMonth INT;
    DECLARE previousYear INT;
	DECLARE report_desc VARCHAR(100);
    DECLARE reportID 	INT;

    SET previousMonth = MONTH(NOW()) - 1;
    SET previousYear = YEAR(NOW());
    IF (previousMonth = 0) THEN
        SET previousMonth = 12;
        SET previousYear = YEAR(NOW()) - 1;
    END IF;
    
    SET report_desc := CONCAT("Discounts Report for ", previousMonth, " month on year ", previousYear);
    INSERT INTO rpt_masterlist (description, reportgenerationDate) VALUES (report_desc, NOW());
    SELECT MAX(report_ID) INTO reportID FROM rpt_masterlist;
    
    INSERT INTO rpt_discounts
		SELECT reportID, rs.*
        FROM rptview_discounts rs
        WHERE month = previousMonth
        AND year = previousYear;
END $$
DELIMITER ;



CREATE TABLE `dbsalesV2.5G211`.`rpt_markups` (
  `report_id` INT NOT NULL,
  `productLine` VARCHAR(50) NOT NULL,
  `product` VARCHAR(70) NOT NULL,
  `country` VARCHAR(50) NOT NULL,
  `office` VARCHAR(10) NOT NULL,
  `salesrepresentative` INT NOT NULL,
  `month` INT(4) NOT NULL,
  `year` INT(4) NOT NULL,
  `total_markups` DECIMAL(9,2) NULL,
  PRIMARY KEY (`report_id`, `productLine`, `country`, `product`, `office`, `salesrepresentative`, `month`, `year`),
  CONSTRAINT `FK88_8802`
    FOREIGN KEY (`report_id`)
    REFERENCES `dbsalesV2.5G211`.`rpt_masterlist` (`report_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION);



-- Markups Report View Start -- 
CREATE VIEW rptview_markups AS
SELECT 		pl.productLine, p.productName,
			oc.country,
			oc.officeCode,
			c.salesRepEmployeeNumber,
			MONTH(o.orderDate) 								 AS MONTH,
			YEAR(o.orderDate) 								 AS YEAR,
            SUM(ROUND((od.priceEach - COALESCE(pp.MSRP, pw.MSRP))*od.quantityOrdered,2)) AS total_markups
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
GROUP BY pl.productLine, p.productName, oc.country, oc.officeCode, c.salesRepEmployeeNumber, MONTH(o.orderDate), YEAR(o.orderDate)
HAVING total_markups > 0
ORDER BY pl.productLine, p.productName, oc.country, oc.officeCode, c.salesRepEmployeeNumber, MONTH(o.orderDate), YEAR(o.orderDate);

-- Markups Report View End -- 


-- Event to Generate the Markups Report Start--
DELIMITER $$
CREATE EVENT generate_markupsreport
ON SCHEDULE EVERY 1 MONTH
STARTS '2024-07-01' -- CHANGE TO START OF MONTH
DO
BEGIN
    DECLARE previousMonth INT;
    DECLARE previousYear INT;
	DECLARE report_desc VARCHAR(100);
    DECLARE reportID 	INT;

    SET previousMonth = MONTH(NOW()) - 1;
    SET previousYear = YEAR(NOW());
    IF (previousMonth = 0) THEN
        SET previousMonth = 12;
        SET previousYear = YEAR(NOW()) - 1;
    END IF;
    
    SET report_desc := CONCAT("Markups Report for ", previousMonth, " month on year ", previousYear);
    INSERT INTO rpt_masterlist (description, reportgenerationDate) VALUES (report_desc, NOW());
    SELECT MAX(report_ID) INTO reportID FROM rpt_masterlist;
    
    INSERT INTO rpt_markups
		SELECT reportID, rs.*
        FROM rptview_markups rs
        WHERE month = previousMonth
        AND year = previousYear;
END $$
DELIMITER ;