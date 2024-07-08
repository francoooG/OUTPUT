DROP EVENT auto_reassign_sales_rep;
DELIMITER $$
CREATE EVENT auto_reassign_sales_rep
ON SCHEDULE EVERY 1 DAY
STARTS  NOW() -- '2024-07-01 18:00:00'
DO
BEGIN
    DECLARE prev_sales DECIMAL(9,2);
    DECLARE currEmployeeNumber INT;
    DECLARE new_quota DECIMAL(9,2);
    DECLARE totalSales DECIMAL(9,2);
    DECLARE finalQuota DECIMAL(9,2);
    DECLARE firstQuota DECIMAL(9,2);

    -- Check if no new assignment is provided
    IF EXISTS (    SELECT employeeNumber, quota
					FROM salesRepAssignments
					WHERE endDate = CURDATE()) THEN
                    
		UPDATE customers c
		JOIN 	(		SELECT sra.employeeNumber AS employeeNumber, sra.quota - SUM(od.quantityOrdered * od.priceEach) AS finalQuota
						FROM 	salesRepAssignments sra LEFT JOIN customers c 		ON sra.employeeNumber = c.salesRepEmployeeNumber
														LEFT JOIN orders o 			ON o.customerNumber = c.customerNumber
														LEFT JOIN orderdetails od 	ON od.orderNumber = o.orderNUmber
						WHERE endDate = CURDATE()
						AND		YEAR(o.orderDate) = 2005 OR YEAR(o.orderDate) = 2024
						GROUP BY sra.employeeNumber, sra.quota
				) AS n ON c.salesRepEmployeeNumber = n.employeeNumber
		SET 	c.startDate = NULL, c.officeCode = NULL
		WHERE c.salesRepEmployeeNumber = n.employeeNumber;
                    
        
        -- Reassign the sales representative for an additional week
        UPDATE salesRepAssignments sra
        JOIN ( 	SELECT sra.employeeNumber, sra.quota - SUM(od.quantityOrdered * od.priceEach) AS finalQuota
				FROM 	salesRepAssignments sra LEFT JOIN customers c 		ON sra.employeeNumber = c.salesRepEmployeeNumber
												LEFT JOIN orders o 			ON o.customerNumber = c.customerNumber
												LEFT JOIN orderdetails od 	ON od.orderNumber = o.orderNUmber
				WHERE endDate = CURDATE()
				AND		YEAR(o.orderDate) = 2005 OR YEAR(o.orderDate) = 2024
				GROUP BY sra.employeeNumber, sra.quota
			 ) AS n ON sra.employeeNumber = n.employeeNumber
        SET startDate = NOW(), endDate = NOW() + INTERVAL 1 WEEK, end_username = 'System', end_userreason = 'System Reassignment', sra.quota = n.finalQuota;
        
		UPDATE customers c
		JOIN 	(		SELECT sra.employeeNumber AS employeeNumber, sra.startDate AS startDate, sra.officeCode AS officeCode
						FROM 	salesRepAssignments sra LEFT JOIN customers c 		ON sra.employeeNumber = c.salesRepEmployeeNumber
														LEFT JOIN orders o 			ON o.customerNumber = c.customerNumber
														LEFT JOIN orderdetails od 	ON od.orderNumber = o.orderNUmber
						WHERE endDate = CURDATE()
						AND		YEAR(o.orderDate) = 2005 OR YEAR(o.orderDate) = 2024
						GROUP BY sra.employeeNumber, sra.quota, sra.startDate, sra.officeCode
				) AS n ON c.salesRepEmployeeNumber = n.employeeNumber
		SET 	c.startDate = n.startDate, c.officeCode = n.officeCode
		WHERE c.salesRepEmployeeNumber = n.employeeNumber;
	
        UPDATE salesRepAssignments sra
        SET sra.quota = 0
        WHERE sra.quota < 0;
	END IF;
END $$
DELIMITER ;
REFERENCES `salesrepassignments` (`employeeNumber`, `officeCode`, `start)



DROP TRIGGER IF EXISTS `dbsalesV2.5G211`.`salesRepAssignments_BEFORE_UPDATE`;

DELIMITER $$
USE `dbsalesV2.5G211`$$
CREATE TRIGGER `salesRepAssignments_BEFORE_UPDATE` BEFORE UPDATE ON `salesRepAssignments` FOR EACH ROW BEGIN
	DECLARE last_end_date DATE;
    
    IF (isIntChanged(OLD.employeeNumber, NEW.employeeNumber) = TRUE) THEN
		SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "Error: Cannot change employeeNumber";
    END IF;
    
    IF NOT EXISTS (SELECT employeeNumber FROM sales_managers WHERE employeeNumber = NEW.salesManagerNumber) THEN
		SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "Employee is not a sales manager";
    END IF;
    
    IF EXISTS (SELECT employeeNumber FROM resigned_employees WHERE employeeNumber = NEW.employeeNumber) THEN
		SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "ERROR: Employee has resigned.";
    END IF;
    
    IF EXISTS (SELECT employeeNumber FROM resigned_employees WHERE employeeNumber = NEW.salesManagerNumber) THEN
		SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "ERROR: Employee has resigned.";
    END IF;
    
    -- Fetch the end date of the current assignment for the sales representative
    IF (isStringChanged(OLD.officeCode, NEW.officeCode) = TRUE) THEN
		SELECT endDate INTO last_end_date
		FROM salesRepAssignments
		WHERE employeeNumber = NEW.employeeNumber;
        
        SET NEW.startDate = last_end_date + INTERVAL 1 DAY;
    END IF;
    -- Restrict the end date to be a maximum of one month from the start date
    IF (DATEDIFF(NEW.endDate, NEW.startDate) > DAY(NEW.startDate + INTERVAL 1 MONTH)) THEN 
		SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "ERROR: End date cannot exceed 1 month.";
    END IF;
END$$
DELIMITER ;



