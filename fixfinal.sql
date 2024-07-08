DROP TRIGGER IF EXISTS `dbsalesV2.5G211`.`orders_BEFORE_INSERT`;

DELIMITER $$
USE `dbsalesV2.5G211`$$
CREATE TRIGGER `orders_BEFORE_INSERT` BEFORE INSERT ON `orders` FOR EACH ROW BEGIN
	-- OrderNumber Generation
    DECLARE NEW_ordernumber	INT;
    SELECT MAX(orderNumber)+1 INTO NEW_ordernumber FROM orders_audit;
    IF (NEW_ordernumber IS NULL) THEN
		SET NEW_ordernumber := 700001;
    END IF;
    SET NEW.orderNumber := NEW_ordernumber;
    
    -- OrderDate must be System Date
    SET NEW.orderDate := NOW();
    
    -- Check for Delivery Date
    IF (isTargetDeliveryValid(NEW.requiredDate, NEW.orderdate) = 0) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "ERROR 1001: Required Date must be at least three days";
    END IF;
    
    -- Status must be in Process
    SET NEW.status := 'In Process'; 

    SET NEW.end_username = CURRENT_USER;
    
    IF NOT EXISTS (SELECT customerNumber FROM customers WHERE customerNumber = NEW.customerNumber) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "ERROR : Customer must be valid";
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `dbsalesV2.5G211`.`orders_BEFORE_UPDATE`;

DELIMITER $$
USE `dbsalesV2.5G211`$$
CREATE TRIGGER `orders_BEFORE_UPDATE` BEFORE UPDATE ON `orders` FOR EACH ROW BEGIN
	DECLARE concat_string TEXT;

    -- Completed / Cancelled orders can't be updated
    IF (OLD.status = "Completed") THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "ERROR 1002: Completed Orders can't be updated";
	END IF;
    
	IF (OLD.status = "Cancelled") THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "ERROR 1002: Cancelled Orders can't be updated";
	END IF;

	-- Restrict identifier update
    IF (isIntChanged(OLD.orderNumber, NEW.orderNumber) = TRUE) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "ERROR 1002: Order Number cannot be updated";
    END IF;

	IF (isDatetimeChanged(OLD.orderDate, NEW.orderDate) = TRUE) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "ERROR 1002: Order Date cannot be updated";
    END IF;
        
	IF (isDatetimeChanged(OLD.shippedDate, NEW.shippedDate) = TRUE) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "ERROR 1002: Shipped Date cannot be updated";
    END IF;
    
	IF (isIntChanged(OLD.customerNumber, NEW.customerNumber) = TRUE) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "ERROR 1002: Customer Number cannot be updated";
    END IF;
    
    -- Check for Delivery Date
	IF (isTargetDeliveryValid(NEW.requiredDate, OLD.orderDate) = 0) THEN 
	 	SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "ERROR 1001: Required Date cannot be less than 3 days of Order Date";
	END IF;
 
	-- Append comments
	IF (NEW.comments IS NOT NULL AND (NEW.comments <> OLD.comments)) THEN 
		SET NEW.comments = appendComments(OLD.comments, NEW.comments);
	ELSEIF (NEW.comments IS NULL) THEN
		SET NEW.comments := OLD.comments;
    END IF;
    
    IF(NEW.status != OLD.status) THEN
		-- Check audit if previous status is found
		IF EXISTS (SELECT NEW_status FROM orders_audit WHERE orderNumber = OLD.orderNumber AND NEW_status = NEW.status) THEN
			SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "ERROR 1003: Status cannot be a previous state";
		-- Updated status must be sequential
		ELSEIF (isStatusUpdateValid(OLD.status, NEW.status) = FALSE) THEN
			SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "ERROR 1003: Status must follow sequence";
		-- Once the status of an order is Shipped, the shipped date must be updated immediately
		ELSEIF (NEW.status = "Shipped" AND OLD.shippedDate IS NULL) THEN
			SET NEW.shippedDate = NOW();
		 END IF;
    END IF; 
    
     -- Check if the status is being changed to "Cancelled"
    IF NEW.status = 'Cancelled' THEN
        -- Ensure there is a comment provided for cancellation
        IF (OLD.comments = NEW.comments OR NEW.comments = NULL) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'ERROR 1003: Comment is null. A comment is required when cancelling an order.';
        END IF;
    END IF; 
    
    IF NEW.status = 'Shipped' THEN
		IF NOT EXISTS (SELECT * FROM orderdetails WHERE orderNumber = NEW.orderNumber) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'ERROR: There are no products to ship.';
        END IF;
    END IF;

    IF (NEW.status = 'Completed') THEN
		IF EXISTS (SELECT referenceNo FROM orderdetails WHERE orderNumber = NEW.orderNumber) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'ERROR: All products must have a referenceNo before completing order.';
        END IF;
    END IF;
END$$
DELIMITER ;



-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


DROP TRIGGER IF EXISTS `dbsalesV2.5G211`.`orderdetails_BEFORE_INSERT`;

DELIMITER $$
USE `dbsalesV2.5G211`$$
CREATE TRIGGER `orderdetails_BEFORE_INSERT` BEFORE INSERT ON `orderdetails` FOR EACH ROW BEGIN
    DECLARE NEW_lineNumber		INT;
	DECLARE currentCategory CHAR(1);

	SELECT product_category INTO currentCategory FROM products WHERE productCode = NEW.productCode;
    
    -- Discontinued procuts can't be ordered
	IF (currentCategory = 'D') THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "ERROR 100x: Product is discontinued";
    END IF;
    
    -- Reference No must be empty
    SET NEW.referenceNo := NULL;
    
    -- Generate Line Number
    SELECT MAX(orderLineNumber)+1 INTO NEW_lineNumber FROM orderdetails WHERE orderNumber = NEW.orderNumber;
    IF (NEW_lineNumber IS NULL) THEN
		SET NEW_lineNumber := 1;
    END IF;
    SET NEW.orderLineNumber := NEW_lineNumber;
    
    -- Check for Inventory
    IF (NEW.quantityOrdered <= 0) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "ERROR: Please input a valid quantity.";
    END IF; 
    
    IF (checkProjectedQuantity(NEW.productCode, NEW.quantityOrdered, 0) < 0) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "ERROR 100x: Ordered quantity will cause below zero inventory quantity";
    END IF;   
    
    -- Check for Price Range
    IF (validPrice(NEW.productCode, NEW.priceEach) = 0) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "ERROR 100x: Price indicated is beyond price Range allowed";
    END IF; 
	-- For Testing if the correct price range is retrieve
	-- SET message := CONCAT(max_price, min_price);
	-- SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = message;

    SET NEW.end_username = CURRENT_USER;
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesV2.5G211`.`orderdetails_BEFORE_UPDATE`;

DELIMITER $$
USE `dbsalesV2.5G211`$$
CREATE TRIGGER `orderdetails_BEFORE_UPDATE` BEFORE UPDATE ON `orderdetails` FOR EACH ROW BEGIN
    -- No updates on LineNumbers
    SET NEW.orderLineNumber := OLD.orderLineNumber;
    
    -- Restrict changes to Identifiers
    IF (isIntChanged(OLD.orderNumber, NEW.orderNumber) = TRUE) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "ERROR: Order Number cannot be updated";
    END IF;

    IF (isStringChanged(OLD.productCode, NEW.productCode) = TRUE) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "ERROR: Product Code cannot be updated";
    END IF; 
    
    -- Determine difference of updated quantity
    IF (NEW.quantityOrdered <= 0) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "ERROR: Please input a valid quantity.";
    END IF; 
    
    IF (checkProjectedQuantity(NEW.productCode, NEW.quantityOrdered, OLD.quantityOrdered) < 0) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "ERROR: Ordered quantity will cause below zero inventory quantity";
    END IF;   
    
    -- Check for Price Range
    IF (validPrice(NEW.productCode, NEW.priceEach) = 0) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "ERROR: Price indicated is beyond price Range allowed";
    END IF; 

    -- ReferenceNo can only be updated if status is Shipped
	IF (OLD.referenceNo IS NOT NULL AND isIntChanged(OLD.referenceNo, NEW.referenceNo) = TRUE) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ERROR: Updating referenceNo is not allowed.';
    END IF;
    
	IF (checkOrderStatus(OLD.orderNumber) = "Shipped" AND NEW.referenceNo IS NULL) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ERROR: A referenceNo must be chosen.';
    END IF;
    
	IF NOT EXISTS(SELECT referenceNo FROM shipments WHERE referenceNo = NEW.referenceNo) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ERROR: Invalid ReferenceNo. Please select a valid one.';
    END IF;
    
    -- QuantityOrdered and PriceEach can only be updated if status is In Process
    IF (checkOrderStatus(OLD.orderNumber) <> "In Process" AND (isIntChanged(OLD.quantityOrdered, NEW.quantityOrdered) = TRUE OR 
															   isDoubleChanged(OLD.priceEach, NEW.priceEach) = TRUE)) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ERROR: QuantityOrdered and PriceEach can only be updated if status is In Process.';
    END IF;

    SET NEW.end_username = CURRENT_USER;
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesV2.5G211`.`orderdetails_AFTER_DELETE`;

DELIMITER $$
USE `dbsalesV2.5G211`$$
CREATE TRIGGER `orderdetails_AFTER_DELETE` AFTER DELETE ON `orderdetails` FOR EACH ROW BEGIN
	DECLARE oldStatus VARCHAR(15);
	-- Update inventory: add back the ordered quantities
    UPDATE current_products 
    SET quantityInStock = quantityInStock + OLD.quantityOrdered, end_username = 'System'
    WHERE productCode = OLD.productCode;
    
    SELECT status INTO oldStatus FROM orders WHERE orderNumber = OLD.orderNumber;
    
    IF (oldStatus != 'Cancelled') THEN
		IF NOT EXISTS (SELECT orderNumber FROM orderdetails WHERE orderNumber = OLD.orderNumber) THEN
			UPDATE orders SET status = "Cancelled", 
							  end_username = "System", 
							  comments = "No more ordered products",
							  end_userreason = "No more ordered products"
			WHERE orderNumber = OLD.orderNumber;
		END IF; 
    END IF;
END$$
DELIMITER ;

-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

USE `dbsalesV2.5G211`;
DROP function IF EXISTS `getPriceRange`;

USE `dbsalesV2.5G211`;
DROP function IF EXISTS `dbsalesV2.5G211`.`getPriceRange`;
;

DELIMITER $$
USE `dbsalesV2.5G211`$$
CREATE FUNCTION `getPriceRange`(v_productCode VARCHAR(15), v_maxOrMin VARCHAR(15)) RETURNS double
    READS SQL DATA
BEGIN
	DECLARE curr_productType 	CHAR(1);
    DECLARE min_price 			DOUBLE;
    DECLARE max_price 			DOUBLE; 
    
	SELECT product_type INTO curr_productType FROM current_products 
    WHERE productCode = v_productCode;
    
    IF (curr_productType = 'W') THEN
		SELECT (MSRP*2), (MSRP*0.8) INTO max_price, min_price 
        FROM product_wholesale WHERE productCode = v_productCode;
    ELSEIF (curr_productType = 'R') THEN
		SELECT (MSRP*2), (MSRP*0.8) INTO max_price, min_price
        FROM   product_pricing 
        WHERE  productCode = v_productCode
        AND    DATE(NOW()) <= endDate AND DATE(NOW()) >= startDate;
    END IF;
    
    IF (v_maxOrMin = "min") THEN
		RETURN ROUND(min_price,2);
    ELSEIF (v_maxOrMin = "max") THEN
		RETURN ROUND(max_price,2);
    END IF;
RETURN 0;
END$$

DELIMITER ;
;



DROP TRIGGER IF EXISTS `dbsalesV2.5G211`.`employees_BEFORE_UPDATE`;

DELIMITER $$
USE `dbsalesV2.5G211`$$
CREATE TRIGGER `employees_BEFORE_UPDATE` BEFORE UPDATE ON `employees` FOR EACH ROW BEGIN
	DECLARE jobTitleStatus VARCHAR(1);
    DECLARE current_end_date DATE;

    IF EXISTS (SELECT employeeNumber 
               FROM resigned_employees 
               WHERE employeeNumber = OLD.employeeNumber) THEN
        SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "ERROR: Employee has resigned";
    END IF;

    IF (isIntChanged(OLD.employeeNumber, NEW.employeeNumber) = TRUE) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'You cannot modify the employeeNumber';
    END IF;
    
	IF (isStringChanged(OLD.lastName, NEW.lastName) = TRUE) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'You cannot modify the lastName';
    END IF;

    IF (isStringChanged(OLD.firstName, NEW.firstName) = TRUE) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'You cannot modify the firstName';
    END IF;
    
    IF NOT EXISTS (SELECT jobTitle FROM job_titles_list WHERE jobTitle = NEW.jobTitle) THEN
		SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "ERROR: Job Title does not exist. Please choose a valid one.";
    END IF;
    
    IF (NEW.employee_type IS NULL) THEN
		SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "ERROR: Please choose an employee type.";
    END IF;
    
    IF (isStringChanged(OLD.jobTitle, NEW.jobTitle) = TRUE) THEN
		SELECT status INTO jobTitleStatus FROM job_titles_list WHERE jobTitle = NEW.jobTitle;
		IF (jobTitleStatus = 'D') THEN
			SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "ERROR: Job position already filled.";
		END IF;
    END IF;

    
    IF (is_JobAndType_consistent(NEW.employee_type, NEW.jobTitle) = FALSE) THEN
		SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "ERROR: Job title and employee type do not match.";
    END IF; 


    -- Check if the employee type is being changed
    IF (isStringChanged(OLD.employee_type, NEW.employee_type) = TRUE) THEN
        -- Update the end date of the current assignment for the sales representative
        UPDATE salesRepAssignments
        SET endDate = CURDATE(), reason = 'Changed Employee Type'
        WHERE employeeNumber = OLD.employeeNumber;
    END IF;


    SET NEW.end_username = CURRENT_USER;
END$$
DELIMITER ;



USE `dbsalesV2.5G211`;
DROP procedure IF EXISTS `resign_employee`;

USE `dbsalesV2.5G211`;
DROP procedure IF EXISTS `dbsalesV2.5G211`.`resign_employee`;
;

DELIMITER $$
USE `dbsalesV2.5G211`$$
CREATE PROCEDURE `resign_employee`(IN v_employeeNumber INT)
BEGIN
	DECLARE currJobTitle VARCHAR(20);
    INSERT INTO resigned_employees VALUES (v_employeeNumber, CURRENT_USER, "NEW Record");
    SELECT jobTitle INTO currJobTitle FROM employees WHERE employeeNumber = v_employeeNumber;
    IF (currJobTitle != 'Sales Rep') THEN
		UPDATE job_titles_list SET status = 'U' WHERE jobTitle = currJobTitle;
	ELSE
		DELETE FROM salesRepresentatives
        WHERE employeeNumber = v_employeeNumber;
    END IF;
END$$

DELIMITER ;
;


DROP TRIGGER IF EXISTS `dbsalesV2.5G211`.`salesRepAssignments_BEFORE_INSERT`;

DELIMITER $$
USE `dbsalesV2.5G211`$$
CREATE TRIGGER `salesRepAssignments_BEFORE_INSERT` BEFORE INSERT ON `salesRepAssignments` FOR EACH ROW BEGIN
	DECLARE last_end_date DATE;
    SET new.startDate := now();
    
    IF EXISTS (SELECT employeeNumber FROM resigned_employees WHERE employeeNumber = NEW.employeeNumber) THEN
		SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "ERROR: Employee has resigned.";
    END IF;
    
    IF EXISTS (SELECT employeeNumber FROM resigned_employees WHERE employeeNumber = NEW.salesManagerNumber) THEN
		SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "ERROR: Employee has resigned.";
    END IF;

    IF NOT EXISTS (SELECT employeeNumber FROM employees WHERE jobTitle = 'Sales Rep' AND employeeNumber = NEW.employeeNumber) THEN
		SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "ERROR: Not a Sales Representatives.";
    END IF;
    
    -- Fetch the end date of the current assignment for the sales representative
    SELECT endDate INTO last_end_date
    FROM salesRepAssignments
    WHERE employeeNumber = NEW.employeeNumber
    ORDER BY endDate DESC
    LIMIT 1;

    -- If the end date is not NULL, set the new assignment's start date to the day after the current assignment's end date
    IF last_end_date IS NOT NULL THEN
        SET NEW.startDate = DATE_ADD(last_end_date, INTERVAL 1 DAY);
    END IF;

    -- Restrict the end date to be a maximum of one month from the start date
    IF NEW.endDate IS NOT NULL AND DATEDIFF(NEW.endDate, NEW.startDate) > 30 THEN
        SET NEW.endDate = DATE_ADD(NEW.startDate, INTERVAL 30 DAY);
    END IF;
    
	IF NOT EXISTS (SELECT employeeNumber FROM sales_managers WHERE employeeNumber = NEW.salesManagerNumber) THEN
		SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "Employee is not a sales manager";
    END IF;

    -- Set assigned_by to 'System' and add a reason
    -- SET NEW.reason = 'New assignment provided before the current assignment expired by System';
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `dbsalesV2.5G211`.`salesRepAssignments_BEFORE_UPDATE`;

DELIMITER $$
USE `dbsalesV2.5G211`$$
CREATE TRIGGER `salesRepAssignments_BEFORE_UPDATE` BEFORE UPDATE ON `salesRepAssignments` FOR EACH ROW BEGIN
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
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesV2.5G211`.`salesRepAssignments_BEFORE_INSERT`;

DELIMITER $$
USE `dbsalesV2.5G211`$$
CREATE TRIGGER `salesRepAssignments_BEFORE_INSERT` BEFORE INSERT ON `salesRepAssignments` FOR EACH ROW BEGIN
	SET NEW.startDate = NOW();
    IF EXISTS (SELECT employeeNumber FROM resigned_employees WHERE employeeNumber = NEW.employeeNumber) THEN
		SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "ERROR: Employee has resigned.";
    END IF;
    
    IF EXISTS (SELECT employeeNumber FROM resigned_employees WHERE employeeNumber = NEW.salesManagerNumber) THEN
		SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "ERROR: Employee has resigned.";
    END IF;

    IF NOT EXISTS (SELECT employeeNumber FROM employees WHERE jobTitle = 'Sales Rep' AND employeeNumber = NEW.employeeNumber) THEN
		SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "ERROR: Not a Sales Representatives.";
    END IF;
    
	IF NOT EXISTS (SELECT employeeNumber FROM sales_managers WHERE employeeNumber = NEW.salesManagerNumber) THEN
		SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "Employee is not a sales manager";
    END IF;

    -- Set assigned_by to 'System' and add a reason
    -- SET NEW.reason = 'New assignment provided before the current assignment expired by System';
END$$
DELIMITER ;


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
    IF NEW.endDate IS NOT NULL AND DATEDIFF(NEW.endDate, NEW.startDate) > 30 THEN
        SET NEW.endDate = DATE_ADD(NEW.startDate, INTERVAL 30 DAY);
    END IF;
END$$
DELIMITER ;



DELIMITER $$
CREATE EVENT dbm211_cancelOverdueOrders
ON SCHEDULE EVERY 1 DAY
STARTS '2024-07-01'
DO
BEGIN
    UPDATE  orders
    SET 	status = "Cancelled", comments = "System automatically cancelled order. Order wasn't shipped within 7 days.", end_username = 'System'
    WHERE   status = 'In Process' AND DATEDIFF(NOW(),orderDate) > 7;
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesV2.5G211`.`current_products_BEFORE_UPDATE`;

DELIMITER $$
USE `dbsalesV2.5G211`$$
CREATE TRIGGER `current_products_BEFORE_UPDATE` BEFORE UPDATE ON `current_products` FOR EACH ROW BEGIN
	IF (isStringChanged(OLD.product_type, NEW.product_type) = TRUE) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "ERROR 100x: Product categories cannot be modified.";
    END IF;
    
    IF (NEW.quantityInStock = 0) THEN
		CALL discontinueProduct(OLD.productCode, "No more stocks", NULL);
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `dbsalesV2.5G211`.`current_products_audit_BEFORE_INSERT`;

DELIMITER $$
USE `dbsalesV2.5G211`$$
CREATE TRIGGER `current_products_audit_BEFORE_INSERT` BEFORE INSERT ON `current_products_audit` FOR EACH ROW BEGIN
	DECLARE maxTimestamp DATETIME;
    IF EXISTS (	SELECT 	audit_timestamp 
				FROM 	current_products_audit 
                WHERE 	productCode = NEW.productCode 
                AND 	audit_timestamp = NEW.audit_timestamp) THEN
                
		SELECT MAX(audit_timestamp) INTO maxTimestamp 
        FROM current_products_audit 
        WHERE productCode = NEW.productCode 
        AND audit_timestamp = NEW.audit_timestamp;
        
		SET NEW.audit_timestamp := maxTimestamp + INTERVAL 1 SECOND;
    END IF;
END$$
DELIMITER ;



UPDATE `dbsalesV2.5G211`.`orders` SET `requiredDate` = '2005-06-30 00:00:00' WHERE (`orderNumber` = '10420');
UPDATE `dbsalesV2.5G211`.`orders` SET `requiredDate` = '2005-06-30 00:00:00' WHERE (`orderNumber` = '10421');
UPDATE `dbsalesV2.5G211`.`orders` SET `requiredDate` = '2005-06-30 00:00:00' WHERE (`orderNumber` = '10422');
UPDATE `dbsalesV2.5G211`.`orders` SET `requiredDate` = '2005-06-30 00:00:00' WHERE (`orderNumber` = '10423');
UPDATE `dbsalesV2.5G211`.`orders` SET `requiredDate` = '2005-06-30 00:00:00' WHERE (`orderNumber` = '10424');
UPDATE `dbsalesV2.5G211`.`orders` SET `requiredDate` = '2005-06-30 00:00:00' WHERE (`orderNumber` = '10425');
UPDATE `dbsalesV2.5G211`.`orders` SET `requiredDate` = '2024-05-30 00:00:00' WHERE (`orderNumber` = '700001');
UPDATE `dbsalesV2.5G211`.`orders` SET `requiredDate` = '2024-06-30 00:00:00' WHERE (`orderNumber` = '700002');
UPDATE `dbsalesV2.5G211`.`orders` SET `requiredDate` = '2024-05-30 00:00:00' WHERE (`orderNumber` = '700003');
UPDATE `dbsalesV2.5G211`.`orders` SET `requiredDate` = '2024-05-30 00:00:00' WHERE (`orderNumber` = '700004');
UPDATE `dbsalesV2.5G211`.`orders` SET `requiredDate` = '2017-01-01 00:00:00' WHERE (`orderNumber` = '10427');
UPDATE `dbsalesV2.5G211`.`orders` SET `requiredDate` = '2017-01-01 00:00:00' WHERE (`orderNumber` = '10426');




USE `dbsalesV2.5G211`;
DROP procedure IF EXISTS `discontinueProduct`;

USE `dbsalesV2.5G211`;
DROP procedure IF EXISTS `dbsalesV2.5G211`.`discontinueProduct`;
;

DELIMITER $$
USE `dbsalesV2.5G211`$$
CREATE PROCEDURE `discontinueProduct`(v_productCode VARCHAR(15), v_reason VARCHAR (45), v_inventory_manager INT)
BEGIN
	DECLARE currProductType CHAR(1);
    
	UPDATE products SET product_category = 'D'
	WHERE productCode = v_productCode;
    INSERT INTO discontinued_products VALUES (v_productCode, v_reason, v_inventory_manager, CURRENT_USER, "NEW Record");
    
    SELECT product_type INTO currProductType FROM current_products WHERE productCode = v_productCode;
    
	IF NOT EXISTS (SELECT employeeNumber FROM inventory_managers WHERE employeeNumber = v_inventory_manager) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "ERROR: Must be an inventory manager";
	END IF;
    
    IF (currProductType = 'R') THEN
    	DELETE FROM product_pricing WHERE productCode = v_productCode;
		DELETE FROM product_retail WHERE productCode = v_productCode;
		DELETE FROM current_products WHERE productCode = v_productCode;
	ELSE 
		DELETE FROM product_wholesale WHERE productCode = v_productCode;
		DELETE FROM current_products WHERE productCode = v_productCode;
    END IF;
END$$

DELIMITER ;
;

                                
DROP EVENT dbm211_creditLimitManagement;
DELIMITER $$
CREATE EVENT dbm211_creditLimitManagement
ON SCHEDULE EVERY 1 MONTH
STARTS '2024-07-01 00:00:00'
DO
BEGIN
    DECLARE previousMonth INT;
    DECLARE previousYear INT;

    SET previousMonth = MONTH(NOW()) - 1;
    SET previousYear = YEAR(NOW());
    IF (previousMonth = 0) THEN
        SET previousMonth = 12;
        SET previousYear = YEAR(NOW()) - 1;
    END IF;


    UPDATE customers c
    JOIN (  SELECT 		o.customerNumber, ROUND(SUM(od.quantityOrdered * od.priceEach) * 2,2) AS newCreditLimit
            FROM 		orders o 	JOIN orderdetails od ON o.orderNumber = od.orderNumber
            WHERE 		o.status != 'Cancelled'
            GROUP BY 	o.customerNumber 
         ) AS n ON c.customerNumber = n.customerNumber
    SET c.creditLimit = n.newCreditLimit;

    UPDATE customers c
    JOIN (  SELECT 		o.customerNumber, COUNT(DISTINCT(od.productCode)), MONTH(o.orderDate) AS MONTH, YEAR(o.orderDate) AS YEAR,
						ROUND(MAX(od.quantityOrdered * od.priceEach),2) AS highestOrderAmount
            FROM 		customers c JOIN orders o ON c.customerNumber
                                JOIN orderdetails od ON o.orderNumber = od.orderNumber
            WHERE 		MONTH(o.orderDate) = previousMonth
            AND 		YEAR(o.orderDate) = previousYear
            AND 		o.status != 'Cancelled'
            GROUP BY 	o.customerNumber
            HAVING 		COUNT(DISTINCT(od.productCode)) > 15
        ) AS n ON c.customerNumber = n.customerNumber
    SET c.creditLimit = c.creditLimit + n.highestOrderAmount;
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesV2.5G211`.`product_productlines_BEFORE_INSERT`;

DELIMITER $$
USE `dbsalesV2.5G211`$$
CREATE TRIGGER `dbsalesV2.5G211`.`product_productlines_BEFORE_INSERT` BEFORE INSERT ON `product_productlines` FOR EACH ROW
BEGIN
	IF NOT EXISTS (SELECT productLine FROM productlines WHERE productLine = NEW.productLine) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "ERROR: Product Line does not exist";
    END IF;
END$$
DELIMITER ;







DELIMITER $$
CREATE EVENT dbm211_TimedMessage
ON SCHEDULE EVERY 1 DAY
STARTS '2024-07-04 18:00:00'
DO
BEGIN
-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	DECLARE i 					INT DEFAULT 0;
	DECLARE n 					INT DEFAULT 0;
    DECLARE startDate 			DATE;
    DECLARE endDate 			DATE;
    DECLARE currEmployeeNumber 	INT DEFAULT 0;
    DECLARE salesManager        VARCHAR(255) DEFAULT 'System';
	DECLARE facilitatedSales    DECIMAL(10,2);
    DECLARE newQuota            DECIMAL(10,2);
    DECLARE previousQuota            DECIMAL(10,2);

    
    UPDATE salesRepAssignments s
    JOIN (  SELECT sd.endDate, 
            FROM salesRepAssignments sd
         ) AS n ON c.customerNumber = n.customerNumber
    SET c.creditLimit = n.newCreditLimit;
END$$
DELIMITER ;
-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-- ORDERS GAB YOU FORGOT ORDERS BEFORE UPDATE COMMENTS