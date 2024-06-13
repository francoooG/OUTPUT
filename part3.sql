-- DBA Script
-- Group 211
-- Audit Script

-- Audit for Table - CUSTOMERS
ALTER TABLE `dbsalesv2.5G211`.`customers` 
ADD COLUMN `end_username` VARCHAR(45) NULL AFTER `startDate`,
ADD COLUMN `end_userreason` VARCHAR(45) NULL AFTER `end_username`;

CREATE TABLE `dbsalesv2.5G211`.`customers_audit` (
  `customerNumber` INT NOT NULL,
  `audit_timestamp` DATETIME NOT NULL,
  `activity` ENUM('C', 'U', 'D') NULL DEFAULT NULL,
  `old_customerName` VARCHAR(45) NULL DEFAULT NULL,
  `old_contactLastName` VARCHAR(45) NULL DEFAULT NULL,
  `old_contactFirstName` VARCHAR(45) NULL DEFAULT NULL,
  `old_phone` VARCHAR(45) NULL DEFAULT NULL,
  `old_addressLine1` VARCHAR(45) NULL DEFAULT NULL,
  `old_addressLine2` VARCHAR(45) NULL DEFAULT NULL,
  `old_city` VARCHAR(45) NULL DEFAULT NULL,
  `old_state` VARCHAR(45) NULL DEFAULT NULL,
  `old_postalCode` VARCHAR(45) NULL DEFAULT NULL,
  `old_country` VARCHAR(45) NULL DEFAULT NULL,
  `old_salesRepEmployeeNumber` INT NULL DEFAULT NULL,
  `old_officeCode` VARCHAR(45) NULL DEFAULT NULL,
  `old_startDate` DATE NULL DEFAULT NULL,
  `old_creditLimit` DOUBLE NULL DEFAULT NULL,
  `new_customerName` VARCHAR(45) NULL DEFAULT NULL,
  `new_contactLastName` VARCHAR(45) NULL DEFAULT NULL,
  `new_contactFirstName` VARCHAR(45) NULL DEFAULT NULL,
  `new_phone` VARCHAR(45) NULL DEFAULT NULL,
  `new_addressLine1` VARCHAR(45) NULL DEFAULT NULL,
  `new_addressLine2` VARCHAR(45) NULL DEFAULT NULL,
  `new_city` VARCHAR(45) NULL DEFAULT NULL,
  `new_state` VARCHAR(45) NULL DEFAULT NULL,
  `new_postalCode` VARCHAR(45) NULL DEFAULT NULL,
  `new_country` VARCHAR(45) NULL DEFAULT NULL,
  `new_salesRepEmployeeNumber` INT NULL DEFAULT NULL,
  `new_officeCode` VARCHAR(45) NULL DEFAULT NULL,
  `new_startDate` DATE NULL DEFAULT NULL,
  `new_creditLimit` DOUBLE NULL DEFAULT NULL,
  `end_username` VARCHAR(45) NULL DEFAULT NULL,
  `end_userreason` VARCHAR(45) NULL DEFAULT NULL,
  PRIMARY KEY (`customerNumber`, `audit_timestamp`));
  
  
DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`customers_BEFORE_INSERT`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `customers_BEFORE_INSERT` BEFORE INSERT ON `customers` FOR EACH ROW BEGIN
	DECLARE newCustomerNumber INT;
    
    SELECT MAX(customerNumber) + 1 INTO newCustomerNumber FROM customers;
    IF (newCustomerNumber IS NULL) THEN
		SET newCustomerNumber := 101;
	END IF;
    
    SET new.customerNumber := newCustomerNumber;
END$$
DELIMITER ;



DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`customers_AFTER_INSERT`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `customers_AFTER_INSERT` AFTER INSERT ON `customers` FOR EACH ROW BEGIN
	INSERT INTO customers_audit	VALUES (new.customerNumber, now(), 'C', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 
																		NULL, NULL, NULL, NULL, NULL, NULL, NULL,
                                                                        new.customerName, new.contactLastName, new.contactFirstName, 
                                                                        new.phone, new.addressLine1, new. addressLine2, 
                                                                        new.city, new.state, new.postalCode,
                                                                        new.country, new.salesRepEmployeeNumber, new.officeCode, 
                                                                        new.startDate, new.creditLimit, new.end_username, new.end_userreason);
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`customers_AFTER_UPDATE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `customers_AFTER_UPDATE` AFTER UPDATE ON `customers` FOR EACH ROW BEGIN
	IF (old.customerNumber <> new.customerNumber) THEN 
		SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "customerNumber cannot be modified";
	END IF;
    INSERT INTO customers_audit VALUES (old.customerNumber, now(), 'U', old.customerName, old.contactLastName, old.contactFirstName, 
																		old.phone, old.addressLine1, old. addressLine2, 
                                                                        old.city, old.state, old.postalCode,
                                                                        old.country, old.salesRepEmployeeNumber, old.officeCode, 
                                                                        old.startDate, old.creditLimit,
                                                                        new.customerName, new.contactLastName, new.contactFirstName, 
                                                                        new.phone, new.addressLine1, new. addressLine2, 
                                                                        new.city, new.state, new.postalCode,
                                                                        new.country, new.salesRepEmployeeNumber, new.officeCode, 
                                                                        new.startDate, new.creditLimit, new.end_username, new.end_userreason);
			
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`customers_AFTER_DELETE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `customers_AFTER_DELETE` AFTER DELETE ON `customers` FOR EACH ROW BEGIN
	INSERT INTO customers_audit	VALUES (old.customerNumber, now(), 'D', old.customerName, old.contactLastName, old.contactFirstName, old.phone, 
                                                                        old.addressLine1, old. addressLine2, old.city, old.state, old.postalCode,
                                                                        old.country, old.salesRepEmployeeNumber, old.officeCode, old.startDate, old.creditLimit,
                                                                        NULL, NULL, NULL, NULL, NULL, NULL, NULL, 
																		NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
		
END$$
DELIMITER ;


-- Audit for Table - OFFICES
ALTER TABLE `dbsalesv2.5G211`.`offices` 
ADD COLUMN `end_username` VARCHAR(45) NULL AFTER `territory`,
ADD COLUMN `end_userreason` VARCHAR(45) NULL AFTER `end_username`;

CREATE TABLE `dbsalesv2.5G211`.`offices_audit` (
  `officeCode` VARCHAR(10) NOT NULL,
  `audit_timestamp` DATETIME NOT NULL,
  `activity` ENUM('C', 'U', 'D') NULL,
  `old_city` VARCHAR(50) NULL,
  `old_phone` VARCHAR(50) NULL,
  `old_addressLine1` VARCHAR(50) NULL,
  `old_addressLine2` VARCHAR(50) NULL,
  `old_state` VARCHAR(45) NULL,
  `old_country` VARCHAR(45) NULL,
  `old_postalCode` VARCHAR(45) NULL,
  `old_territory` VARCHAR(45) NULL,
  `new_city` VARCHAR(50) NULL,
  `new_phone` VARCHAR(50) NULL,
  `new_addressLine1` VARCHAR(50) NULL,
  `new_addressLine2` VARCHAR(50) NULL,
  `new_state` VARCHAR(45) NULL,
  `new_country` VARCHAR(45) NULL,
  `new_postalCode` VARCHAR(45) NULL,
  `new_territory` VARCHAR(45) NULL,
  `end_username` VARCHAR(45) NULL,
  `end_userreason` VARCHAR(45) NULL,
  PRIMARY KEY (`officeCode`, `audit_timestamp`));
  
  
DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`offices_BEFORE_INSERT`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `offices_BEFORE_INSERT` BEFORE INSERT ON `offices` FOR EACH ROW BEGIN
	
    DECLARE newOfficeCode VARCHAR(10);
        
    SELECT MAX(officeCode) + 1 INTO newOfficeCode FROM offices;
    IF (newOfficeCode IS NULL) THEN
		SET newOfficeCode := 1;
	END IF;
    SET new.officeCode := newOfficeCode;
    
END$$
DELIMITER ;



DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`offices_AFTER_INSERT`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `offices_AFTER_INSERT` AFTER INSERT ON `offices` FOR EACH ROW BEGIN
	INSERT INTO offices_audit VALUES (new.officeCode, now(), 'C', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 
                                                                  new.city, new.phone, new.addressLine1, new.addressLine2, 
                                                                  new.state, new.country, new.postalCode, new.territory, 
                                                                  new.end_username, new.end_userreason);
	
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`offices_AFTER_UPDATE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `offices_AFTER_UPDATE` AFTER UPDATE ON `offices` FOR EACH ROW BEGIN
	IF (old.officeCode <> old.officeCode) THEN 
		SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "officeCode cannot be modified";
	END IF;
	INSERT INTO offices_audit VALUES (old.officeCode, now(), 'U', old.city, old.phone, old.addressLine1, old.addressLine2, 
                                                                  old.state, old. country, old.postalCode, old.territory,
                                                                  new.city, new.phone, new.addressLine1, new.addressLine2, 
                                                                  new.state, new.country, new.postalCode, new.territory,
                                                                  new.end_username, new.end_userreason);
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`offices_BEFORE_DELETE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `offices_BEFORE_DELETE` BEFORE DELETE ON `offices` FOR EACH ROW BEGIN
	INSERT INTO offices_audit VALUES (old.officeCode, now(), 'D', old.city, old.phone, old.addressLine1, old.addressLine2, 
                                                                  old.state, old. country, old.postalCode, old.territory,
                                                                  NULL, NULL, NULL, NULL, 
                                                                  NULL, NULL, NULL, NULL,
                                                                  NULL, NULL);
END$$
DELIMITER ;


-- Audit for Table - PRODUCTS
ALTER TABLE `dbsalesv2.5G211`.`products` 
ADD COLUMN `end_username` VARCHAR(45) NULL AFTER `product_category`,
ADD COLUMN `end_userreason` VARCHAR(45) NULL AFTER `end_username`;


CREATE TABLE `dbsalesv2.5G211`.`products_audit` (
  `productCode` VARCHAR(15) NOT NULL,
  `audit_timestamp` DATETIME NOT NULL,
  `activity` ENUM('C', 'U', 'D') NULL,
  `old_productName` VARCHAR(70) NULL,
  `old_productScale` VARCHAR(10) NULL,
  `old_productVendor` VARCHAR(50) NULL,
  `old_productDescription` TEXT NULL,
  `old_buyPrice` DOUBLE NULL,
  `old_product_category` ENUM('C', 'D') NULL,
  `new_productName` VARCHAR(70) NULL,
  `new_productScale` VARCHAR(10) NULL,
  `new_productVendor` VARCHAR(50) NULL,
  `new_productDescription` TEXT NULL,
  `new_buyPrice` DOUBLE NULL,
  `new_product_category` ENUM('C', 'D') NULL,
  `end_username` VARCHAR(45) NULL,
  `end_userreason` VARCHAR(45) NULL,
  PRIMARY KEY (`productCode`, `audit_timestamp`));
  
DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`products_BEFORE_INSERT`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `products_BEFORE_INSERT` BEFORE INSERT ON `products` FOR EACH ROW BEGIN
	DECLARE newProductCode VARCHAR(15);
    DECLARE newProductScale VARCHAR(15);
    DECLARE productScaleConcat VARCHAR(15);
    
    SET newProductScale = SUBSTRING_INDEX(new.productScale, ':', -1);
    SET productScaleConcat = CONCAT('S', newProductScale);
    SET productScaleConcat = CONCAT(productScaleConcat, '_');
    
    
    SELECT MAX(CAST(SUBSTRING_INDEX(productCode, '_', -1) AS UNSIGNED)) + 1 AS maxProductCode INTO newProductCode FROM products;
    IF (newProductCode IS NULL) THEN
		SET newProductCode := 1001;
	END IF;
    
    SET new.productCode := CONCAT(productScaleConcat, '_');
    SET new.productCode := CONCAT(productScaleConcat, newProductCode);
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`products_AFTER_INSERT`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `products_AFTER_INSERT` AFTER INSERT ON `products` FOR EACH ROW BEGIN
	INSERT INTO products_audit VALUES(new.productCode, now(), 'C', NULL, NULL, NULL, NULL, NULL, NULL,
																   new.productName, new.productScale, new.productVendor,
																   new.productDescription, new.buyPrice, new.product_category,
																   new.end_username, new.end_userreason);
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`products_AFTER_UPDATE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `products_AFTER_UPDATE` AFTER UPDATE ON `products` FOR EACH ROW BEGIN
	IF (old.productCode <> new.productCode) THEN 
		SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "productCode cannot be modified";
	END IF;
	INSERT INTO products_audit 	VALUES (old.productCode, now(), 'U', old.productName, old.productScale, old.productVendor, 
                                                                     old.productDescription, old.buyPrice, old.product_category,
																	 new.productName, new.productScale, new.productVendor, 
                                                                     new.productDescription, new.buyPrice, new.product_category,
                                                                     new.end_username, new.end_userreason);
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`products_BEFORE_DELETE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `products_BEFORE_DELETE` BEFORE DELETE ON `products` FOR EACH ROW BEGIN
	INSERT INTO products_audit 	VALUES (old.productCode, now(), 'D', old.productName, old.productScale, old.productVendor, 
                                                                     old.productDescription, old.buyPrice, old.product_category,
																	 NULL, NULL, NULL, NULL, NULL, NULL,
                                                                     NULL, NULL);
END$$
DELIMITER ;


-- Audit for Table - EMPLOYEES
ALTER TABLE `dbsalesv2.5G211`.`employees` 
ADD COLUMN `end_username` VARCHAR(45) NULL AFTER `employee_type`,
ADD COLUMN `end_userreason` VARCHAR(45) NULL AFTER `end_username`;

CREATE TABLE `dbsalesv2.5G211`.`employees_audit` (
  `employeeNumber` INT NOT NULL,
  `audit_timestamp` DATETIME NOT NULL,
  `activity` ENUM('C', 'U', 'D') NULL,
  `old_lastName` VARCHAR(50) NULL,
  `old_firstName` VARCHAR(50) NULL,
  `old_extension` VARCHAR(10) NULL,
  `old_email` VARCHAR(100) NULL,
  `old_jobTitle` VARCHAR(50) NULL,
  `old_employee_type` ENUM('S', 'N') NULL,
  `new_lastName` VARCHAR(50) NULL,
  `new_firstName` VARCHAR(50) NULL,
  `new_extension` VARCHAR(10) NULL,
  `new_email` VARCHAR(100) NULL,
  `new_jobTitle` VARCHAR(50) NULL,
  `new_employee_type` ENUM('S', 'N') NULL,
  `end_username` VARCHAR(45) NULL,
  `end_userreason` VARCHAR(45) NULL,
  PRIMARY KEY (`employeeNumber`, `audit_timestamp`));
  
  
DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`employees_BEFORE_INSERT`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `dbsalesv2.5G211`.`employees_BEFORE_INSERT` BEFORE INSERT ON `employees` FOR EACH ROW
BEGIN
	DECLARE newEmployeeNumber INT;
    
    SELECT MAX(employeeNumber) + 1 INTO newEmployeeNumber FROM employees;
    IF (newEmployeeNumber IS NULL) THEN
		SET newEmployeeNumber := 1;
	END IF;
    
    SET new.employeeNumber := newEmployeeNumber;
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`employees_AFTER_INSERT`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `employees_AFTER_INSERT` AFTER INSERT ON `employees` FOR EACH ROW BEGIN
	INSERT INTO employees_audit VALUES (new.employeeNumber, now(), 'C', NULL, NULL, NULL, NULL, NULL, NULL,
																		new.lastName, new.firstName, new.extension, 
																		new.email, new.jobTitle, new.employee_type,
                                                                        new.end_username, new.end_userreason);
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`employees_AFTER_UPDATE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `employees_AFTER_UPDATE` AFTER UPDATE ON `employees` FOR EACH ROW BEGIN
	IF (old.employeeNumber <> new.employeeNumber) THEN 
		SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "employeeNumber cannot be modified";
	END IF;
	INSERT INTO employees_audit VALUES (old.employeeNumber, now(), 'U', old.lastName, old.firstName, old.extension, 
																		old.email, old.jobTitle, old.employee_type,
																		new.lastName, new.firstName, new.extension, 
																		new.email, new.jobTitle, new.employee_type,
                                                                        new.end_username, new.end_userreason);
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`employees_BEFORE_DELETE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `employees_BEFORE_DELETE` BEFORE DELETE ON `employees` FOR EACH ROW BEGIN
	INSERT INTO employees_audit VALUES (old.employeeNumber, now(), 'D', old.lastName, old.firstName, old.extension, 
																		old.email, old.jobTitle, old.employee_type,
																		NULL, NULL, NULL, 
																		NULL, NULL, NULL,
                                                                        NULL, NULL);
END$$
DELIMITER ;


-- Audit for Table - ORDERS
  
DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`orders_BEFORE_INSERT`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `orders_BEFORE_INSERT` BEFORE INSERT ON `orders` FOR EACH ROW BEGIN
	DECLARE newOrderNumber INT;
    
    SELECT MAX(orderNumber) + 1 INTO newOrderNumber FROM orders;
    IF (newOrderNumber IS NULL) THEN
		SET newOrderNumber := 10100;
	END IF;
    
    SET new.orderNumber := newOrderNumber;
END$$
DELIMITER ;



DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`orders_AFTER_INSERT`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `orders_AFTER_INSERT` AFTER INSERT ON `orders` FOR EACH ROW BEGIN
	INSERT INTO orders_audit VALUES (new.orderNumber, now(), 'C', NULL, NULL, NULL, NULL, NULL, NULL,
																  new.orderDate, new.requiredDate, new.shippedDate, 
																  new.status, new.comments, new.customerNumber,
																  new.end_username, new.end_userreason);
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`orders_AFTER_UPDATE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `orders_AFTER_UPDATE` AFTER UPDATE ON `orders` FOR EACH ROW BEGIN
	IF (old.orderNumber <> new.orderNumber) THEN 
		SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "orderNumber cannot be modified";
	END IF;
	INSERT INTO orders_audit VALUES (old.orderNumber, now(), 'U', old.orderDate, old.requiredDate, old.shippedDate, 
																					  old.status, old.comments, old.customerNumber,
																					  new.orderDate, new.requiredDate, new.shippedDate, 
																					  new.status, new.comments, new.customerNumber,
                                                                                      new.end_username, new.end_userreason);
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`orders_BEFORE_DELETE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `orders_BEFORE_DELETE` BEFORE DELETE ON `orders` FOR EACH ROW BEGIN
	INSERT INTO orders_audit VALUES (old.orderNumber, now(), 'D', old.orderDate, old.requiredDate, old.shippedDate, 
																  old.status, old.comments, old.customerNumber,
																  NULL, NULL, NULL, NULL, NULL, NULL,
																  NULL, NULL);
END$$
DELIMITER ;



-- Audit for Table - salesRepAssignments
ALTER TABLE `dbsalesv2.5G211`.`salesRepAssignments` 
ADD COLUMN `end_username` VARCHAR(45) NULL AFTER `salesManagerNumber`,
ADD COLUMN `end_userreason` VARCHAR(45) NULL AFTER `end_username`;


CREATE TABLE `dbsalesv2.5G211`.`salesRepAssignments_audit` (
  `employeeNumber` INT NOT NULL,
  `officeCode` VARCHAR(10) NOT NULL,
  `startDate` DATE NOT NULL,
  `audit_timestamp` DATETIME NOT NULL,
  `activity` ENUM('C', 'U', 'D') NULL,
  `old_endDate` DATE NULL,
  `old_reason` VARCHAR(45) NULL,
  `old_quota` DECIMAL(9,2) NULL,
  `old_salesManagerNumber` INT NULL,
  `new_endDate` DATE NULL,
  `new_reason` VARCHAR(45) NULL,
  `new_quota` DECIMAL(9,2) NULL,
  `new_salesManagerNumber` INT NULL,
  `end_username` VARCHAR(45) NULL,
  `end_userreason` VARCHAR(45) NULL,
  PRIMARY KEY (`employeeNumber`, `officeCode`, `startDate`, `audit_timestamp`));


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`salesRepAssignments_BEFORE_INSERT`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `dbsalesv2.5G211`.`salesRepAssignments_BEFORE_INSERT` BEFORE INSERT ON `salesRepAssignments` FOR EACH ROW
BEGIN
	SET new.startDate := now();
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`salesRepAssignments_AFTER_INSERT`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `salesRepAssignments_AFTER_INSERT` AFTER INSERT ON `salesRepAssignments` FOR EACH ROW BEGIN
	INSERT INTO salesRepAssignments_audit VALUES (new.employeeNumber, new.officeCode, new.startDate, now(), 'C',
												  NULL, NULL, NULL, NULL,
                                                  new.endDate, new.reason, new.quota, new.salesManagerNumber,
                                                  new.end_username, new.end_userreason);
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`salesRepAssignments_AFTER_UPDATE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `dbsalesv2.5G211`.`salesRepAssignments_AFTER_UPDATE` AFTER UPDATE ON `salesRepAssignments` FOR EACH ROW
BEGIN
	INSERT INTO salesRepAssignments_audit VALUES (old.employeeNumber, old.officeCode, old.startDate, now(), 'U',
												  old.endDate, old.reason, old.quota, old.salesManagerNumber,
                                                  new.endDate, new.reason, new.quota, new.salesManagerNumber,
                                                  new.end_username, new.end_userreason);
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`salesRepAssignments_BEFORE_DELETE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `dbsalesv2.5G211`.`salesRepAssignments_BEFORE_DELETE` BEFORE DELETE ON `salesRepAssignments` FOR EACH ROW
BEGIN
	INSERT INTO salesRepAssignments_audit VALUES (old.employeeNumber, old.officeCode, old.startDate, now(), 'D',
												  old.endDate, old.reason, old.quota, old.salesManagerNumber,
                                                  NULL, NULL, NULL, NULL,
                                                  NULL, NULL);
END$$
DELIMITER ;



-- Audit for Table - ORDERDETAILS

DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`orderdetails_AFTER_INSERT`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `orderdetails_AFTER_INSERT` AFTER INSERT ON `orderdetails` FOR EACH ROW BEGIN
	INSERT INTO orderdetails_audit VALUES (new.orderNumber, new.productCode, now(), 'C', 
										   NULL, NULL, NULL, NULL,
										   new.quantityOrdered, new.priceEach, new.orderLineNumber, new.referenceNo,
                                           new.end_username, new.end_userreason);
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`orderdetails_BEFORE_UPDATE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `orderdetails_BEFORE_UPDATE` BEFORE UPDATE ON `orderdetails` FOR EACH ROW BEGIN
	IF (old.orderNumber <> new.orderNumber || old.productCode <> new.productCode) THEN 
		SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "orderNumber/productCode cannot be modified";
	END IF;
	INSERT INTO orderdetails_audit VALUES (old.orderNumber, old.productCode, now(), 'U', 
										   old.quantityOrdered, old.priceEach, old.orderLineNumber, old.referenceNo,
										   new.quantityOrdered, new.priceEach, new.orderLineNumber, new.referenceNo,
                                           new.end_username, new.end_userreason);
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`orderdetails_BEFORE_DELETE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `orderdetails_BEFORE_DELETE` BEFORE DELETE ON `orderdetails` FOR EACH ROW BEGIN
	INSERT INTO orderdetails_audit VALUES (old.orderNumber, old.productCode, now(), 'D', 
										   old.quantityOrdered, old.priceEach, old.orderLineNumber, old.referenceNo,
										   NULL, NULL, NULL, NULL,
                                           NULL, NULL);
END$$
DELIMITER ;


-- Audit for Table - SHIPMENTSTATUS
ALTER TABLE `dbsalesv2.5G211`.`shipmentstatus` 
ADD COLUMN `end_username` VARCHAR(45) NULL AFTER `ridermobileno`,
ADD COLUMN `end_userreason` VARCHAR(45) NULL AFTER `end_username`;


CREATE TABLE `dbsalesv2.5G211`.`shipmentstatus_audit` (
  `referenceNo` INT NOT NULL,
  `statusTimeStamp` DATETIME NOT NULL,
  `audit_timestamp` DATETIME NOT NULL,
  `activity` ENUM('C', 'U', 'D') NULL,
  `old_status` INT NULL,
  `old_comments` VARCHAR(45) NULL,
  `old_ridermobileno` INT NULL,
  `new_status` INT NULL,
  `new_comments` VARCHAR(45) NULL,
  `new_ridermobileno` INT NULL,
  `end_username` VARCHAR(45) NULL,
  `end_userreason` VARCHAR(45) NULL,
  PRIMARY KEY (`referenceNo`, `statusTimeStamp`, `audit_timestamp`));
  
  
DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`shipmentstatus_BEFORE_INSERT`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `dbsalesv2.5G211`.`shipmentstatus_BEFORE_INSERT` BEFORE INSERT ON `shipmentstatus` FOR EACH ROW
BEGIN
	SET new.statusTimeStamp := NOW();
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`shipmentstatus_AFTER_INSERT`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `shipmentstatus_AFTER_INSERT` AFTER INSERT ON `shipmentstatus` FOR EACH ROW BEGIN
	INSERT INTO shipmentstatus_audit VALUES (new.referenceNo, new.statusTimeStamp, now(), 'C',
											 NULL, NULL, NULL,
                                             new.status, new.comments, new.ridermobileno,
                                             new.end_username, new.end_userreason);
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`shipmentstatus_AFTER_UPDATE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `shipmentstatus_AFTER_UPDATE` AFTER UPDATE ON `shipmentstatus` FOR EACH ROW BEGIN
	IF (old.referenceNo <> new.referenceNo || old.statusTimeStamp <> new.statusTimeStamp) THEN 
		SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "referenceNo/statusTimeStamp cannot be modified";
	END IF;
	INSERT INTO shipmentstatus_audit VALUES (old.referenceNo, old.statusTimeStamp, now(), 'U',
											 old.status, old.comments, old.ridermobileno,
                                             new.status, new.comments, new.ridermobileno,
                                             new.end_username, new.end_userreason);
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`shipmentstatus_BEFORE_DELETE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `shipmentstatus_BEFORE_DELETE` BEFORE DELETE ON `shipmentstatus` FOR EACH ROW BEGIN
	INSERT INTO shipmentstatus_audit VALUES (old.referenceNo, old.statusTimeStamp, now(), 'D',
											 old.status, old.comments, old.ridermobileno,
                                             NULL, NULL, NULL,
                                             NULL, NULL);
END$$
DELIMITER ;


-- Audit for Table - RIDERS
ALTER TABLE `dbsalesv2.5G211`.`riders` 
ADD COLUMN `end_username` VARCHAR(45) NULL AFTER `courierName`,
ADD COLUMN `end_userreason` VARCHAR(45) NULL AFTER `end_username`;


CREATE TABLE `dbsalesv2.5G211`.`riders_audit` (
  `mobileno` INT NOT NULL,
  `audit_timestamp` DATETIME NOT NULL,
  `activity` ENUM('C', 'U', 'D') NULL,
  `old_lastName` VARCHAR(45) NULL,
  `old_firstName` VARCHAR(45) NULL,
  `old_courierName` VARCHAR(100) NULL,
  `new_lastName` VARCHAR(45) NULL,
  `new_firstName` VARCHAR(45) NULL,
  `new_courierName` VARCHAR(100) NULL,
  `end_username` VARCHAR(45) NULL,
  `end_userreason` VARCHAR(45) NULL,
  PRIMARY KEY (`mobileno`, `audit_timestamp`));

DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`riders_AFTER_INSERT`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `riders_AFTER_INSERT` AFTER INSERT ON `riders` FOR EACH ROW BEGIN
	INSERT INTO riders_audit VALUES (new.mobileno, now(), 'C', NULL, NULL, NULL, new.lastName, new.firstName, new.courierName,
									 new.end_username, new.end_userreason);
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`riders_AFTER_UPDATE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `riders_AFTER_UPDATE` AFTER UPDATE ON `riders` FOR EACH ROW BEGIN
	IF (old.mobileno <> new.mobileno) THEN 
		SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "mobileno/courierName cannot be modified";
	END IF;
	INSERT INTO riders_audit VALUES (new.mobileno, now(), 'C',
									 old.lastName, old.firstName, old.courierName, 
                                     new.lastName, new.firstName, new.courierName,
									 new.end_username, new.end_userreason);
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`riders_BEFORE_DELETE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `riders_BEFORE_DELETE` BEFORE DELETE ON `riders` FOR EACH ROW BEGIN
	INSERT INTO riders_audit VALUES (old.mobileno, now(), 'D', old.lastName, old.firstName, old.courierName, NULL, NULL, NULL, NULL, NULL);
END$$
DELIMITER ;


-- Audit for Table - PRODUCTLINES
ALTER TABLE `dbsalesv2.5G211`.`productlines` 
ADD COLUMN `end_username` VARCHAR(45) NULL AFTER `image`,
ADD COLUMN `end_userreason` VARCHAR(45) NULL AFTER `end_username`;


CREATE TABLE `dbsalesv2.5G211`.`productlines_audit` (
  `productLine` VARCHAR(50) NOT NULL,
  `audit_timestamp` DATETIME NOT NULL,
  `activity` ENUM('C', 'U', 'D') NULL,
  `old_textDescription` VARCHAR(4000) NULL,
  `old_htmlDescription` MEDIUMTEXT NULL,
  `old_image` MEDIUMBLOB NULL,
  `new_textDescription` VARCHAR(4000) NULL,
  `new_htmlDescription` MEDIUMTEXT NULL,
  `new_image` MEDIUMBLOB NULL,
  `end_username` VARCHAR(45) NULL,
  `end_userreason` VARCHAR(45) NULL,
  PRIMARY KEY (`productLine`, `audit_timestamp`));


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`productlines_AFTER_INSERT`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `productlines_AFTER_INSERT` AFTER INSERT ON `productlines` FOR EACH ROW BEGIN
	INSERT INTO productlines_audit VALUES (new.productLine, now(), 'C', NULL, NULL, NULL,
																		new.textDescription, new.htmlDescription, new.image,
                                                                        new.end_username, new.end_userreason);
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`productlines_AFTER_UPDATE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `productlines_AFTER_UPDATE` AFTER UPDATE ON `productlines` FOR EACH ROW BEGIN
	IF (old.productLine <> new.productLine) THEN 
		SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "productLine cannot be modified";
	END IF;
	INSERT INTO productlines_audit VALUES (old.productLine, now(), 'U', old.textDescription, old.htmlDescription, old.image,
																		new.textDescription, new.htmlDescription, new.image,
                                                                        new.end_username, new.end_userreason);
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`productlines_BEFORE_DELETE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `productlines_BEFORE_DELETE` BEFORE DELETE ON `productlines` FOR EACH ROW BEGIN
	INSERT INTO productlines_audit VALUES (old.productLine, now(), 'D', old.textDescription, old.htmlDescription, old.image,
																		NULL, NULL, NULL, NULL, NULL);
END$$
DELIMITER ;

-- Audit for Table - CHECKPAYMENTS
ALTER TABLE `dbsalesv2.5G211`.`check_payments` 
ADD COLUMN `end_username` VARCHAR(45) NULL AFTER `checkno`,
ADD COLUMN `end_userreason` VARCHAR(45) NULL AFTER `end_username`;

CREATE TABLE `dbsalesv2.5G211`.`check_payments_audit` (
  `customerNumber` INT NOT NULL,
  `paymentTimestamp` DATETIME NOT NULL,
  `audit_timestamp` DATETIME NOT NULL,
  `activity` ENUM('C', 'U', 'D') NULL,
  `old_checkno` INT NULL,
  `new_checkno` INT NULL,
  `end_username` VARCHAR(45) NULL,
  `end_userreason` VARCHAR(45) NULL,
  PRIMARY KEY (`customerNumber`, `paymentTimestamp`, `audit_timestamp`));


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`check_payments_AFTER_INSERT`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `check_payments_AFTER_INSERT` AFTER INSERT ON `check_payments` FOR EACH ROW BEGIN
	INSERT INTO check_payments_audit VALUES (new.customerNumber, new.paymentTimestamp, now(), "C", 
											 NULL, new.checkno, new.end_username, new.end_userreason);
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`check_payments_AFTER_UPDATE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `check_payments_AFTER_UPDATE` AFTER UPDATE ON `check_payments` FOR EACH ROW BEGIN
	IF (old.customerNumber <> new.customerNumber) THEN
		SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "Customer ID cannot be modified";
	END IF;
    IF (old.paymentTimestamp <> new.paymentTimestamp) THEN
		SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "paymentTimestamp cannot be modified";
	END IF;
    INSERT INTO check_payments_audit VALUES (new.customerNumber, new.paymentTimestamp, now(), "U", old.checkno, new.checkno, new.end_username, new.end_userreason);
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`check_payments_BEFORE_DELETE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `check_payments_BEFORE_DELETE` BEFORE DELETE ON `check_payments` FOR EACH ROW BEGIN
	INSERT INTO check_payments_audit VALUES(old.customerNumber, old.paymentTimestamp, now(), "D", 
											old.checkno, NULL, NULL, "Deletion of Record");
END$$
DELIMITER ;


-- Audit for Table - CREDITPAYMENTS
ALTER TABLE `dbsalesv2.5G211`.`credit_payments` 
ADD COLUMN `end_username` VARCHAR(45) NULL AFTER `paymentReferenceNo`,
ADD COLUMN `end_userreason` VARCHAR(45) NULL AFTER `end_username`;

CREATE TABLE `dbsalesv2.5G211`.`credit_payments_audit` (
  `customerNumber` INT NOT NULL,
  `paymentTimestamp` DATETIME NOT NULL,
  `audit_timestamp` DATETIME NOT NULL,
  `activity` ENUM('C', 'U', 'D') NULL,
  `old_postingDate` DATE NULL,
  `old_paymentReferenceNo` INT NULL,
  `new_postingDate` DATE NULL,
  `new_paymentReferenceNo` INT NULL,
  `end_username` VARCHAR(45) NULL,
  `end_userreason` VARCHAR(45) NULL,
  PRIMARY KEY (`customerNumber`, `paymentTimestamp`, `audit_timestamp`));


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`credit_payments_AFTER_INSERT`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `credit_payments_AFTER_INSERT` AFTER INSERT ON `credit_payments` FOR EACH ROW
BEGIN
	INSERT INTO credit_payments_audit VALUES (new.customerNumber, new.paymentTimestamp, now(), "C", NULL, NULL, new.postingDate, new.paymentReferenceNo, new.end_username, new.end_userreason);
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`credit_payments_AFTER_UPDATE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `credit_payments_AFTER_UPDATE` AFTER UPDATE ON `credit_payments` FOR EACH ROW BEGIN
	IF (old.customerNumber <> new.customerNumber) THEN
		SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "Customer ID cannot be modified";
	END IF;
    IF (old.paymentTimestamp <> new.paymentTimestamp) THEN
		SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "paymentTimestamp cannot be modified";
	END IF;
    INSERT INTO credit_payments_audit VALUES (new.customerNumber, new.paymentTimestamp, now(), "U", old.postingDate, old.paymentReferenceNo, new.postingDate, new.paymentReferenceNo, new.end_username, new.end_userreason);
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`credit_payments_BEFORE_DELETE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `dbsalesv2.5G211`.`credit_payments_BEFORE_DELETE` BEFORE DELETE ON `credit_payments` FOR EACH ROW
BEGIN
	INSERT INTO credit_payments_audit VALUES (old.customerNumber, old.paymentTimestamp, now(), "D", old.postingDate, old.paymentReferenceNo, NULL, NULL, NULL, "Deletion of Record");
END$$
DELIMITER ;


-- Audit for Table - CURRENTPRODUCTS
ALTER TABLE `dbsalesv2.5G211`.`current_products` 
ADD COLUMN `end_username` VARCHAR(45) NULL AFTER `quantityInStock`,
ADD COLUMN `end_userreason` VARCHAR(45) NULL AFTER `end_username`;

CREATE TABLE `dbsalesv2.5G211`.`current_products_audit` (
  `productCode` VARCHAR(15) NOT NULL,
  `audit_timestamp` DATETIME NOT NULL,
  `activity` ENUM('C', 'U', 'D') NULL,
  `old_product_type` ENUM('R', 'W') NULL,
  `old_quantityInStock` SMALLINT NULL,
  `new_product_type` ENUM('R', 'W') NULL,
  `new_quantityInStock` SMALLINT NULL,
  `end_username` VARCHAR(45) NULL,
  `end_userreason` VARCHAR(45) NULL,
  PRIMARY KEY (`productCode`, `audit_timestamp`));


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`current_products_AFTER_INSERT`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `current_products_AFTER_INSERT` AFTER INSERT ON `current_products` FOR EACH ROW
BEGIN
	INSERT INTO current_products_audit VALUES (new.productCode, now(), "C", NULL, NULL, new.product_type, new.quantityInStock, new.end_username, new.end_userreason);
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`current_products_AFTER_UPDATE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `current_products_AFTER_UPDATE` AFTER UPDATE ON `current_products` FOR EACH ROW BEGIN
	IF (old.productCode <> new.productCode) THEN
		SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "Product Code cannot be modified";
	END IF;
	INSERT INTO current_products_audit VALUES (new.productCode, now(), "U", old.product_type, old.quantityInStock, new.product_type, new.quantityInStock, new.end_username, new.end_userreason);
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`current_products_BEFORE_DELETE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `dbsalesv2.5G211`.`current_products_BEFORE_DELETE` BEFORE DELETE ON `current_products` FOR EACH ROW
BEGIN
	INSERT INTO current_products_audit VALUES (old.productCode, now(), "D", old.product_type, old.quantityInStock, NULL, NULL, NULL, "Deletion of Record");
END$$
DELIMITER ;


-- Audit for Table - DISCONTINUEDPRODUCTS
ALTER TABLE `dbsalesv2.5G211`.`discontinued_products` 
ADD COLUMN `end_username` VARCHAR(45) NULL AFTER `inventory_manager`,
ADD COLUMN `end_userreason` VARCHAR(45) NULL AFTER `end_username`;

CREATE TABLE `dbsalesv2.5G211`.`discontinued_products_audit` (
  `productCode` VARCHAR(15) NOT NULL,
  `audit_timestamp` DATETIME NOT NULL,
  `activity` ENUM('C', 'U', 'D') NULL,
  `old_reason` VARCHAR(45) NULL,
  `old_inventory_manager` INT NULL,
  `new_reason` VARCHAR(45) NULL,
  `new_inventory_manager` INT NULL,
  `end_username` VARCHAR(45) NULL,
  `end_userreason` VARCHAR(45) NULL,
  PRIMARY KEY (`productCode`, `audit_timestamp`));
DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`discontinued_products_AFTER_INSERT`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `discontinued_products_AFTER_INSERT` AFTER INSERT ON `discontinued_products` FOR EACH ROW
BEGIN
	INSERT INTO discontinued_products_audit VALUES (new.productCode, now(), "C", NULL, NULL, new.reason, new.inventory_manager, new.end_username, new.end_userreason);
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`discontinued_products_AFTER_UPDATE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `discontinued_products_AFTER_UPDATE` AFTER UPDATE ON `discontinued_products` FOR EACH ROW BEGIN
	IF (old.productCode <> new.productCode) THEN
		SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "Product Code cannot be modified";
	END IF; 
    INSERT INTO discontinued_products_audit VALUES (new.productCode, now(), "U", old.reason, old.inventory_manager, new.reason, new.inventory_manager, new.end_username, new.end_userreason);	
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`discontinued_products_BEFORE_DELETE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `discontinued_products_BEFORE_DELETE` BEFORE DELETE ON `discontinued_products` FOR EACH ROW
BEGIN
	INSERT INTO discontinued_products_audit VALUES (old.productCode, now(), "D", old.reason, old.inventory_manager, NULL, NULL, NULL, "Deletion of Record");
END$$
DELIMITER ;

-- Audit for Table - INVENTORYMANAGERS
ALTER TABLE `dbsalesv2.5G211`.`inventory_managers` 
ADD COLUMN `end_username` VARCHAR(45) NULL AFTER `employeeNumber`,
ADD COLUMN `end_userreason` VARCHAR(45) NULL AFTER `end_username`;

CREATE TABLE `dbsalesv2.5G211`.`inventory_managers_audit` (
  `employeeNumber` INT NOT NULL,
  `audit_timestamp` DATETIME NOT NULL,
  `activity` ENUM('C', 'U', 'D') NULL,
  `end_username` VARCHAR(45) NULL,
  `end_userreason` VARCHAR(45) NULL,
  PRIMARY KEY (`employeeNumber`, `audit_timestamp`));


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`inventory_managers_AFTER_INSERT`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `inventory_managers_AFTER_INSERT` AFTER INSERT ON `inventory_managers` FOR EACH ROW
BEGIN
	INSERT INTO inventory_managers_audit VALUES (new.employeeNumber, now(), "C", 
												 new.end_username, new.end_userreason);
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`inventory_managers_AFTER_UPDATE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `inventory_managers_AFTER_UPDATE` AFTER UPDATE ON `inventory_managers` FOR EACH ROW BEGIN
	IF (old.employeeNumber <> new.employeeNumber) THEN
		SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "Employee Number cannot be modified";
	END IF; 
    INSERT INTO inventory_managers_audit VALUES (new.employeeNumber, now(), "U", 
												 new.end_username, new.end_userreason);
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`inventory_managers_BEFORE_DELETE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `dbsalesv2.5G211`.`inventory_managers_BEFORE_DELETE` BEFORE DELETE ON `inventory_managers` FOR EACH ROW
BEGIN
	INSERT INTO inventory_managers_audit VALUES (old.employeeNumber, now(), "D", 
												 NULL, "Deletion of Record");
END$$
DELIMITER ;

-- Audit for Table - NONSALESREPRESENTATIVE
ALTER TABLE `dbsalesv2.5G211`.`Non_SalesRepresentatives` 
ADD COLUMN `end_username` VARCHAR(45) NULL AFTER `deptCode`,
ADD COLUMN `end_userreason` VARCHAR(45) NULL AFTER `end_username`;

CREATE TABLE `dbsalesv2.5G211`.`Non_SalesRepresentatives_audit` (
  `employeeNumber` INT NOT NULL,
  `audit_timestamp` DATETIME NOT NULL,
  `activity` ENUM('C', 'U', 'D') NULL,
  `old_deptCode` INT NULL,
  `new_deptCode` INT NULL,
  `end_username` VARCHAR(45) NULL,
  `end_userreason` VARCHAR(45) NULL,
  PRIMARY KEY (`employeeNumber`, `audit_timestamp`));


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`Non_SalesRepresentatives_AFTER_INSERT`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `Non_SalesRepresentatives_AFTER_INSERT` AFTER INSERT ON `Non_SalesRepresentatives` FOR EACH ROW
BEGIN
	INSERT INTO Non_SalesRepresentatives_audit VALUES (new.employeeNumber, now(), "C", NULL, new.deptCode, new.end_username, new.end_userreason);
END$$
DELIMITER ;
DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`Non_SalesRepresentatives_AFTER_UPDATE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `Non_SalesRepresentatives_AFTER_UPDATE` AFTER UPDATE ON `Non_SalesRepresentatives` FOR EACH ROW BEGIN
	IF (old.employeeNumber <> new.employeeNumber) THEN
		SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "Employee ID cannot be modiifed";
	END IF;
    INSERT INTO Non_SalesRepresentatives_audit VALUES (new.employeeNumber, now(), "U", old.deptCode, new.deptCode, new.end_username, new.end_userreason);
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`Non_SalesRepresentatives_BEFORE_DELETE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `Non_SalesRepresentatives_BEFORE_DELETE` BEFORE DELETE ON `Non_SalesRepresentatives` FOR EACH ROW
BEGIN
	INSERT INTO Non_SalesRepresentatives_audit VALUES (old.employeeNumber, now(), "D", old.deptCode, NULL, NULL, "Deletion of Record");
END$$
DELIMITER ;


-- Audit for Table - PAYMENTS
ALTER TABLE `dbsalesv2.5G211`.`payments` 
ADD COLUMN `end_username` VARCHAR(45) NULL AFTER `paymentType`,
ADD COLUMN `end_userreason` VARCHAR(45) NULL AFTER `end_username`;

CREATE TABLE `dbsalesv2.5G211`.`payments_audit` (
  `customerNumber` INT NOT NULL,
  `paymentTimestamp` DATETIME NOT NULL,
  `audit_timestamp` DATETIME NOT NULL,
  `activity` ENUM('C', 'U', 'D') NULL,
  `paymentType` ENUM('S', 'H', 'C') NOT NULL,
  `end_username` VARCHAR(45) NULL,
  `end_userreason` VARCHAR(45) NULL,
  PRIMARY KEY (`customerNumber`, `paymentTimestamp`, `audit_timestamp`));


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`payments_BEFORE_INSERT`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `payments_BEFORE_INSERT` BEFORE INSERT ON `payments` FOR EACH ROW
BEGIN
	SET new.paymentTimestamp := NOW();
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`payments_AFTER_INSERT`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `payments_AFTER_INSERT` AFTER INSERT ON `payments` FOR EACH ROW
BEGIN
	INSERT INTO payments_audit VALUES (new.customerNumber, new.paymentTimestamp, now(), "C", 
									   new.paymentType, new.end_username, new.end_userreason);
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`payments_AFTER_UPDATE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `payments_AFTER_UPDATE` AFTER UPDATE ON `payments` FOR EACH ROW
BEGIN
	IF (old.customerNumber <> new.customerNumber) THEN
		SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "Customer ID cannot be modified";
	END IF;
	IF (old.paymentTimestamp <> new.paymentTimestamp) THEN
		SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "paymentTimestamp cannot be modified";
	END IF;
	INSERT INTO payments_audit VALUES (new.customerNumber, new.paymentTimestamp, now(), "U", 
									   new.paymentType, new.end_username, new.end_userreason);
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`payments_BEFORE_DELETE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `payments_BEFORE_DELETE` BEFORE DELETE ON `payments` FOR EACH ROW
BEGIN
	INSERT INTO payments_audit VALUES (old.customerNumber, old.paymentTimestamp, now(), "D", 
									   old.paymentType, NULL, "Deletion of Record");
END$$
DELIMITER ;


-- Audit for Table - PAYMENTORDERS
ALTER TABLE `dbsalesv2.5G211`.`payment_orders` 
ADD COLUMN `end_username` VARCHAR(45) NULL AFTER `amountpaid`,
ADD COLUMN `end_userreason` VARCHAR(45) NULL AFTER `end_username`;

CREATE TABLE `dbsalesv2.5G211`.`payment_orders_audit` (
  `customerNumber` INT NOT NULL,
  `paymentTimestamp` DATETIME NOT NULL,
  `orderNumber` INT NOT NULL,
  `audit_timestamp` DATETIME NOT NULL,
  `activity` ENUM('C', 'U', 'D') NULL,
  `old_amountpaid` DECIMAL(9,2) NULL,
  `new_amountpaid` DECIMAL(9,2) NULL,
  `end_username` VARCHAR(45) NULL,
  `end_userreason` VARCHAR(45) NULL,
  PRIMARY KEY (`customerNumber`, `paymentTimestamp`, `orderNumber`, `audit_timestamp`));
DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`payment_orders_AFTER_INSERT`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `payment_orders_AFTER_INSERT` AFTER INSERT ON `payment_orders` FOR EACH ROW
BEGIN
	INSERT INTO payment_orders_audit VALUE (new.customerNumber, new.paymentTimestamp, new.orderNumber, now(), "C", NULL, new.amountpaid, new.end_username, new.end_userreason);
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`payment_orders_AFTER_UPDATE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `payment_orders_AFTER_UPDATE` AFTER UPDATE ON `payment_orders` FOR EACH ROW BEGIN
	IF (old.customerNumber <> new.customerNumber) THEN
		SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "Customer ID cannot be modified";
	END IF;
	IF (old.paymentTimestamp <> new.paymentTimestamp) THEN
		SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "paymentTimestamp cannot be modified";
	END IF;
	IF (old.orderNumber <> new.orderNumber) THEN
		SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "orderNumber cannot be modified";
	END IF;
    INSERT INTO payment_orders_audit VALUE (new.customerNumber, new.paymentTimestamp, new.orderNumber, now(), "U", old.amountpaid, new.amountpaid, new.end_username, new.end_userreason);
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`payment_orders_BEFORE_DELETE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `payment_orders_BEFORE_DELETE` BEFORE DELETE ON `payment_orders` FOR EACH ROW
BEGIN
	INSERT INTO payment_orders_audit VALUE (old.customerNumber, old.paymentTimestamp, old.orderNumber, now(), "D", old.amountpaid, NULL, NULL, "Deletion of Record");
END$$
DELIMITER ;


-- Audit for Table - PRODUCTPRICING
ALTER TABLE `dbsalesv2.5G211`.`product_pricing` 
ADD COLUMN `end_username` VARCHAR(45) NULL AFTER `MSRP`,
ADD COLUMN `end_userreason` VARCHAR(45) NULL AFTER `end_username`;

CREATE TABLE `dbsalesv2.5G211`.`product_pricing_audit` (
  `productCode` VARCHAR(15) NOT NULL,
  `startdate` DATE NOT NULL,
  `audit_timestamp` DATETIME NOT NULL,
  `activity` ENUM('C', 'U', 'D') NULL,
  `old_enddate` DATE NULL,
  `old_MSRP` DECIMAL(9,2) NULL,
  `new_enddate` DATE NULL,
  `new_MSRP` DECIMAL(9,2) NULL,
  `end_username` VARCHAR(45) NULL,
  `end_userreason` VARCHAR(45) NULL,
  PRIMARY KEY (`productCode`, `startdate`, `audit_timestamp`));


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`product_pricing_BEFORE_INSERT`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `product_pricing_BEFORE_INSERT` BEFORE INSERT ON `product_pricing` FOR EACH ROW
BEGIN
	SET new.startdate := NOW();
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`product_pricing_AFTER_INSERT`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `product_pricing_AFTER_INSERT` AFTER INSERT ON `product_pricing` FOR EACH ROW
BEGIN
	INSERT INTO product_pricing_audit VALUES (new.productCode, new.startdate, now(), "C", NULL, NULL, new.enddate, new.MSRP, new.end_username, new.end_userreason);
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`product_pricing_AFTER_UPDATE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `product_pricing_AFTER_UPDATE` AFTER UPDATE ON `product_pricing` FOR EACH ROW BEGIN
	IF (old.productCode <> new.productCode) THEN
		SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "Product ID cannot be modified";
    END IF;
    IF (old.startdate <> new.startdate) THEN
		SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "startdate cannot be modified";
    END IF;
    INSERT INTO product_pricing_audit VALUES (new.productCode, new.startdate, now(), "U", old.enddate, old.MSRP, new.enddate, new.MSRP, new.end_username, new.end_userreason);
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`product_pricing_BEFORE_DELETE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `product_pricing_BEFORE_DELETE` BEFORE DELETE ON `product_pricing` FOR EACH ROW
BEGIN
	INSERT INTO product_pricing_audit VALUES (old.productCode, old.startdate, now(), "D", old.enddate, old.MSRP, NULL, NULL, NULL, "Deletion of Record");
END$$
DELIMITER ;


-- Audit for Table - SALESMANAGERS
ALTER TABLE `dbsalesv2.5G211`.`sales_managers` 
ADD COLUMN `end_username` VARCHAR(45) NULL AFTER `employeeNumber`,
ADD COLUMN `end_userreason` VARCHAR(45) NULL AFTER `end_username`;

CREATE TABLE `dbsalesv2.5G211`.`sales_managers_audit` (
  `employeeNumber` INT NOT NULL,
  `audit_timestamp` DATETIME NOT NULL,
  `activity` ENUM('C', 'U', 'D') NULL,
  `end_username` VARCHAR(45) NULL,
  `end_userreason` VARCHAR(45) NULL,
  PRIMARY KEY (`employeeNumber`, `audit_timestamp`));


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`sales_managers_AFTER_INSERT`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `sales_managers_AFTER_INSERT` AFTER INSERT ON `sales_managers` FOR EACH ROW
BEGIN
	INSERT INTO sales_managers_audit VALUES (new.employeeNumber, now(), "C", new.end_username, new.end_userreason);
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`sales_managers_AFTER_UPDATE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `sales_managers_AFTER_UPDATE` AFTER UPDATE ON `sales_managers` FOR EACH ROW BEGIN
	IF (old.employeeNumber <> new.employeeNumber) THEN
		SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "Employee ID cannot be modified";
	END IF;
    INSERT INTO sales_managers_audit VALUES (new.employeeNumber, now(), "U", new.end_username, new.end_userreason);
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`sales_managers_BEFORE_DELETE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `sales_managers_BEFORE_DELETE` BEFORE DELETE ON `sales_managers` FOR EACH ROW
BEGIN
	INSERT INTO sales_managers_audit VALUES (old.employeeNumber, now(), "D", NULL, "Deletion of Record");
END$$
DELIMITER ;


-- Audit for Table - COURIERS
ALTER TABLE `dbsalesv2.5G211`.`couriers` 
ADD COLUMN `end_username` VARCHAR(45) NULL AFTER `address`,
ADD COLUMN `end_userreason` VARCHAR(45) NULL AFTER `end_username`;


CREATE TABLE `dbsalesv2.5G211`.`couriers_audit` (
  `courierName` VARCHAR(100) NOT NULL,
  `audit_timestamp` DATETIME NOT NULL,
  `activity` ENUM('C', 'U', 'D') NULL,
  `old_address` VARCHAR(100) NULL,
  `new_address` VARCHAR(100) NULL,
  `end_username` VARCHAR(45) NULL,
  `end_userreason` VARCHAR(45) NULL,
  PRIMARY KEY (`courierName`, `audit_timestamp`))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`couriers_AFTER_INSERT`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `couriers_AFTER_INSERT` AFTER INSERT ON `couriers` FOR EACH ROW BEGIN
	INSERT INTO couriers_audit VALUES (new.courierName, now(), "C", NULL, new.address, new.end_username, new.end_userreason);
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`couriers_AFTER_UPDATE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `couriers_AFTER_UPDATE` AFTER UPDATE ON `couriers` FOR EACH ROW BEGIN
	IF (old.courierName <> new.courierName) THEN
		SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "Courier Name cannot be modified";
	END IF;
    INSERT INTO couriers_audit VALUES (new.courierName, now(), "U", old.address, new.address, new.end_username, new.end_userreason);
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`couriers_BEFORE_DELETE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `couriers_BEFORE_DELETE` BEFORE DELETE ON `couriers` FOR EACH ROW BEGIN
	INSERT INTO couriers_audit VALUES (old.courierName, now(), "D", old.address, NULL, NULL, 'Deletion of Record');
END$$
DELIMITER ;


-- Audit for Table - SHIPMENTS
ALTER TABLE `dbsalesv2.5G211`.`shipments` 
ADD COLUMN `end_username` VARCHAR(45) NULL AFTER `courierName`,
ADD COLUMN `end_userreason` VARCHAR(45) NULL AFTER `end_username`;


CREATE TABLE `dbsalesv2.5G211`.`shipments_audit` (
  `referenceNo` INT NOT NULL,
  `audit_timestamp` DATETIME NOT NULL,
  `activity` ENUM('C', 'U', 'D') NULL,
  `old_courierName` VARCHAR(100) NULL,
  `new_courierName` VARCHAR(100) NULL,
  `end_username` VARCHAR(45) NULL,
  `end_userreason` VARCHAR(45) NULL,
  PRIMARY KEY (`referenceNo`, `audit_timestamp`))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`shipmentso_BEFORE_INSERT`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `dbsalesv2.5G211`.`shipments_BEFORE_INSERT` BEFORE INSERT ON `shipments` FOR EACH ROW
BEGIN
	DECLARE newreferenceNo INT;
    
    SELECT MAX(referenceNo) + 1 INTO newreferenceNo FROM shipments;
    IF (newreferenceNo IS NULL) THEN
		SET newreferenceNo := 00001;
	END IF;
    
    SET new.referenceNo := newreferenceNo;
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`shipments_AFTER_INSERT`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `shipments_AFTER_INSERT` AFTER INSERT ON `shipments` FOR EACH ROW 
BEGIN
	INSERT INTO shipments_audit VALUES (new.referenceNo, now(), "C", NULL, new.courierName, new.end_username, new.end_userreason);
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`shipments_AFTER_UPDATE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `dbsalesv2.5G211`.`shipments_AFTER_UPDATE` AFTER UPDATE ON `shipments` FOR EACH ROW BEGIN
	IF (old.referenceNo <> new.referenceNo) THEN
		SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "Reference No cannot be modified";
	END IF;
    INSERT INTO shipments_audit VALUES (new.referenceNo, now(), "U", old.courierName, new.courierName, new.end_username, new.end_userreason);
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`shipments_BEFORE_DELETE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `dbsalesv2.5G211`.`shipments_BEFORE_DELETE` BEFORE DELETE ON `shipments` FOR EACH ROW
BEGIN
	INSERT INTO shipments_audit VALUES (old.referenceNo, now(), "D", old.courierName, NULL, NULL, 'Deletion of Record');
END$$
DELIMITER ;


-- Audit for Table - PRODUCT_WHOLESALE
ALTER TABLE `dbsalesv2.5G211`.`product_wholesale` 
ADD COLUMN `end_username` VARCHAR(45) NULL AFTER `MSRP`,
ADD COLUMN `end_userreason` VARCHAR(45) NULL AFTER `end_username`;


CREATE TABLE `dbsalesv2.5G211`.`product_wholesale_audit` (
  `productCode` VARCHAR(15) NOT NULL,
  `audit_timestamp` DATETIME NOT NULL,
  `activity` ENUM('C', 'U', 'D') NULL,
  `old_MSRP` DECIMAL(9,2) NULL,
  `new_MSRP` DECIMAL(9,2) NULL,
  `end_username` VARCHAR(45) NULL,
  `end_userreason` VARCHAR(45) NULL,
  PRIMARY KEY (`productCode`, `audit_timestamp`))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`product_wholesale_AFTER_INSERT`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `dbsalesv2.5G211`.`product_wholesale_AFTER_INSERT` AFTER INSERT ON `product_wholesale` FOR EACH ROW
BEGIN
	INSERT INTO product_wholesale_audit VALUES (new.productCode, now(), "C", NULL, new.MSRP, new.end_username, new.end_userreason);
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`product_wholesale_AFTER_UPDATE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `dbsalesv2.5G211`.`product_wholesale_AFTER_UPDATE` AFTER UPDATE ON `product_wholesale` FOR EACH ROW BEGIN
	IF (old.productCode <> new.productCode) THEN
		SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "Product Code cannot be modified";
	END IF;
    INSERT INTO product_wholesale_audit VALUES (new.productCode, now(), "U", old.MSRP, new.MSRP, new.end_username, new.end_userreason);
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`product_wholesale_BEFORE_DELETE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `dbsalesv2.5G211`.`product_wholesale_BEFORE_DELETE` BEFORE DELETE ON `product_wholesale` FOR EACH ROW
BEGIN
	INSERT INTO product_wholesale_audit VALUES (old.productCode, now(), "D", old.MSRP, NULL, NULL, 'Deletion of Record');
END$$
DELIMITER ;


-- Audit for Table - PRODUCT_RETAIL
ALTER TABLE `dbsalesv2.5G211`.`product_retail` 
ADD COLUMN `end_username` VARCHAR(45) NULL AFTER `productCode`,
ADD COLUMN `end_userreason` VARCHAR(45) NULL AFTER `end_username`;

CREATE TABLE `dbsalesv2.5G211`.`product_retail_audit` (
  `productCode` VARCHAR(15) NOT NULL,
  `audit_timestamp` DATETIME NOT NULL,
  `activity` ENUM('C', 'U', 'D') NULL,
  `end_username` VARCHAR(45) NULL,
  `end_userreason` VARCHAR(45) NULL,
  PRIMARY KEY (`productCode`, `audit_timestamp`));


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`product_retail_AFTER_INSERT`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `product_retail_AFTER_INSERT` AFTER INSERT ON `product_retail` FOR EACH ROW
BEGIN
	INSERT INTO product_retail_audit VALUES (new.productCode, now(), "C", new.end_username, new.end_userreason);
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`product_retail_AFTER_UPDATE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `dbsalesv2.5G211`.`product_retail_AFTER_UPDATE` AFTER UPDATE ON `product_retail` FOR EACH ROW BEGIN
	IF (old.productCode <> new.productCode) THEN
		SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "Product Code cannot be modified";
	END IF;
    INSERT INTO product_retail_audit VALUES (new.productCode, now(), "U", new.end_username, new.end_userreason);
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`product_retail_BEFORE_DELETE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `dbsalesv2.5G211`.`product_retail_BEFORE_DELETE` BEFORE DELETE ON `product_retail` FOR EACH ROW
BEGIN
	INSERT INTO product_retail_audit VALUES (old.productCode, now(), "D", NULL, 'Deletion of Record');
END$$
DELIMITER ;


-- Audit for Table - PRODUCT_PRODUCTLINES
ALTER TABLE `dbsalesv2.5G211`.`product_productlines` 
ADD COLUMN `end_username` VARCHAR(45) NULL AFTER `productLine`,
ADD COLUMN `end_userreason` VARCHAR(45) NULL AFTER `end_username`;


CREATE TABLE `dbsalesv2.5G211`.`product_productlines_audit` (
  `productCode` VARCHAR(15) NOT NULL,
  `productLine` VARCHAR(50) NOT NULL,
  `audit_timestamp` DATETIME NOT NULL,
  `activity` ENUM('C', 'U', 'D') NULL,
  `end_username` VARCHAR(45) NULL,
  `end_userreason` VARCHAR(45) NULL,
  PRIMARY KEY (`productCode`, `productLine`, `audit_timestamp`));


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`product_productlines_AFTER_INSERT`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `dbsalesv2.5G211`.`product_productlines_AFTER_INSERT` AFTER INSERT ON `product_productlines` FOR EACH ROW
BEGIN
	INSERT INTO product_productlines_audit VALUES (new.productCode, new.productLine, now(), "C", new.end_username, new.end_userreason);
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`product_productlines_AFTER_UPDATE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `dbsalesv2.5G211`.`product_productlines_AFTER_UPDATE` AFTER UPDATE ON `product_productlines` FOR EACH ROW BEGIN
	IF (old.productCode <> new.productCode) THEN
		SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "Product Code cannot be modified";
	END IF;
IF (old.productLine <> new.productLine) THEN
		SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "Product Line cannot be modified";
	END IF;
    INSERT INTO product_productlines_audit VALUES (new.productCode, new.productLine, now(), "U", new.end_username, new.end_userreason);
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`product_productlines_BEFORE_DELETE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `dbsalesv2.5G211`.`product_productlines_BEFORE_DELETE` BEFORE DELETE ON `product_productlines` FOR EACH ROW
BEGIN
	INSERT INTO product_productlines_audit VALUES (old.productCode, old.productLine, now(), "D", NULL, 'Deletion of Record');
END$$
DELIMITER ;


-- Audit for Table - REF_SHIPMENTSTATUS
ALTER TABLE `dbsalesv2.5G211`.`ref_shipmentstatus` 
ADD COLUMN `end_username` VARCHAR(45) NULL AFTER `description`,
ADD COLUMN `end_userreason` VARCHAR(45) NULL AFTER `end_username`;


CREATE TABLE `dbsalesv2.5G211`.`ref_shipmentstatus_audit` (
  `status` INT NOT NULL,
  `audit_timestamp` DATETIME NOT NULL,
  `activity` ENUM('C', 'U', 'D') NULL,
  `old_description` VARCHAR(45) NULL,
  `new_description` VARCHAR(45) NULL,
  `end_username` VARCHAR(45) NULL,
  `end_userreason` VARCHAR(45) NULL,
  PRIMARY KEY (`status`, `audit_timestamp`));


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`ref_shipmentstatus_AFTER_INSERT`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `dbsalesv2.5G211`.`ref_shipmentstatus_AFTER_INSERT` AFTER INSERT ON `ref_shipmentstatus` FOR EACH ROW
BEGIN
	INSERT INTO ref_shipmentstatus_audit VALUES (new.status, now(), "C", NULL, new.description, new.end_username, new.end_userreason);
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`ref_shipmentstatus_AFTER_UPDATE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `dbsalesv2.5G211`.`ref_shipmentstatus_AFTER_UPDATE` AFTER UPDATE ON `ref_shipmentstatus` FOR EACH ROW BEGIN
	IF (old.status <> new.status) THEN
		SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "Status cannot be modified";
	END IF;
    INSERT INTO ref_shipmentstatus_audit VALUES (new.status, now(), "U", old.description, new.description, new.end_username, new.end_userreason);
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`ref_shipmentstatus_BEFORE_DELETE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `dbsalesv2.5G211`.`ref_shipmentstatus_BEFORE_DELETE` BEFORE DELETE ON `ref_shipmentstatus` FOR EACH ROW
BEGIN
	INSERT INTO ref_shipmentstatus_audit VALUES (old.status, now(), "D", old.description, NULL, NULL, 'Deletion of Record');
END$$
DELIMITER ;


-- Audit for Table - REF_CHECKNO
ALTER TABLE `dbsalesv2.5G211`.`ref_checkno` 
ADD COLUMN `end_username` VARCHAR(45) NULL AFTER `bank`,
ADD COLUMN `end_userreason` VARCHAR(45) NULL AFTER `end_username`;


CREATE TABLE `dbsalesv2.5G211`.`ref_checkno_audit` (
  `checkno` INT NOT NULL,
  `audit_timestamp` DATETIME NOT NULL,
  `activity` ENUM('C', 'U', 'D') NULL,
  `old_bank` INT NULL,
  `new_bank` INT NULL,
  `end_username` VARCHAR(45) NULL,
  `end_userreason` VARCHAR(45) NULL,
  PRIMARY KEY (`checkno`, `audit_timestamp`))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`ref_checkno_BEFORE_INSERT`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `dbsalesv2.5G211`.`ref_checkno_BEFORE_INSERT` BEFORE INSERT ON `ref_checkno` FOR EACH ROW
BEGIN
	DECLARE newcheckno INT;
    
    SELECT MAX(checkno) + 1 INTO newcheckno FROM ref_checkno;
    IF (newcheckno IS NULL) THEN
		SET newcheckno := 00001;
	END IF;
    
    SET new.checkno := newcheckno;
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`ref_checkno_AFTER_INSERT`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `dbsalesv2.5G211`.`ref_checkno_AFTER_INSERT` AFTER INSERT ON `ref_checkno` FOR EACH ROW
BEGIN
	INSERT INTO ref_checkno_audit VALUES (new.checkno, now(), "C", NULL, new.bank, new.end_username, new.end_userreason);
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`ref_checkno_AFTER_UPDATE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `dbsalesv2.5G211`.`ref_checkno_AFTER_UPDATE` AFTER UPDATE ON `ref_checkno` FOR EACH ROW BEGIN
	IF (old.checkno <> new.checkno) THEN
		SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "Check No cannot be modified";
	END IF;
    INSERT INTO ref_checkno_audit VALUES (new.checkno, now(), "U", old.bank, new.bank, new.end_username, new.end_userreason);
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`ref_checkno_BEFORE_DELETE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `dbsalesv2.5G211`.`ref_checkno_BEFORE_DELETE` BEFORE DELETE ON `ref_checkno` FOR EACH ROW
BEGIN
	INSERT INTO ref_checkno_audit VALUES (old.checkno,  now(), "D", old.bank, NULL, NULL, 'Deletion of Record');
END$$
DELIMITER ;


-- Audit for Table - ref_paymentreferenceNo
ALTER TABLE `dbsalesv2.5G211`.`ref_paymentreferenceNo` 
ADD COLUMN `end_username` VARCHAR(45) NULL AFTER `bank`,
ADD COLUMN `end_userreason` VARCHAR(45) NULL AFTER `end_username`;

CREATE TABLE `dbsalesv2.5G211`.`ref_paymentreferenceNo_audit` (
  `referenceNo` INT NOT NULL,
  `audit_timestamp` DATETIME NOT NULL,
  `activity` ENUM('C', 'U', 'D') NULL,
  `old_bank` INT NULL,
  `new_bank` INT NULL,
  `end_username` VARCHAR(45) NULL,
  `end_userreason` VARCHAR(45) NULL,
  PRIMARY KEY (`referenceNo`, `audit_timestamp`))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`ref_paymentreferenceNo_BEFORE_INSERT`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `dbsalesv2.5G211`.`ref_paymentreferenceNo_BEFORE_INSERT` BEFORE INSERT ON `ref_paymentreferenceNo` FOR EACH ROW
BEGIN
	DECLARE newreferenceNo INT;
    
    SELECT MAX(referenceNo) + 1 INTO newreferenceNo FROM ref_paymentreferenceNo;
    IF (newreferenceNo IS NULL) THEN
		SET newreferenceNo := 00001;
	END IF;
    
    SET new.referenceNo := newreferenceNo;
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`ref_paymentreferenceNo_AFTER_INSERT`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `dbsalesv2.5G211`.`ref_paymentreferenceNo_AFTER_INSERT` AFTER INSERT ON `ref_paymentreferenceNo` FOR EACH ROW
BEGIN
	INSERT INTO ref_paymentreferenceNo_audit VALUES (new.referenceNo, now(), "C", NULL, new.bank, new.end_username, new.end_userreason);
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`ref_paymentreferenceNo_AFTER_UPDATE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `dbsalesv2.5G211`.`ref_paymentreferenceNo_AFTER_UPDATE` AFTER UPDATE ON `ref_paymentreferenceNo` FOR EACH ROW BEGIN
	IF (old.referenceNo <> new.referenceNo) THEN
		SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "Reference No cannot be modified";
	END IF;
    INSERT INTO ref_paymentreferenceNo_audit VALUES (new.referenceNo, now(), "U", old.bank, new.bank, new.end_username, new.end_userreason);
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`ref_paymentreferenceNo_BEFORE_DELETE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `dbsalesv2.5G211`.`ref_paymentreferenceNo_BEFORE_DELETE` BEFORE DELETE ON `ref_paymentreferenceNo` FOR EACH ROW
BEGIN
	INSERT INTO ref_paymentreferenceNo_audit VALUES (old.referenceNo, now(), "D", old.bank, NULL, NULL, 'Deletion of Record');
END$$
DELIMITER ;


-- Audit for Table - salesRepresentatives
ALTER TABLE `dbsalesv2.5G211`.`salesRepresentatives` 
ADD COLUMN `end_username` VARCHAR(45) NULL AFTER `employeeNumber`,
ADD COLUMN `end_userreason` VARCHAR(45) NULL AFTER `end_username`;

CREATE TABLE `dbsalesv2.5G211`.`salesRepresentatives_audit` (
  `employeeNumber` INT NOT NULL,
  `audit_timestamp` DATETIME NOT NULL,
  `activity` ENUM('C', 'U', 'D') NULL,
  `end_username` VARCHAR(45) NULL,
  `end_userreason` VARCHAR(45) NULL,
  PRIMARY KEY (`employeeNumber`, `audit_timestamp`));


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`salesRepresentatives_AFTER_INSERT`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `salesRepresentatives_AFTER_INSERT` AFTER INSERT ON `salesRepresentatives` FOR EACH ROW
BEGIN
	INSERT INTO salesRepresentatives_audit VALUES (new.employeeNumber, now(), "C", new.end_username, new.end_userreason);
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`salesRepresentatives_AFTER_UPDATE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `dbsalesv2.5G211`.`salesRepresentatives_AFTER_UPDATE` AFTER UPDATE ON `salesRepresentatives` FOR EACH ROW BEGIN
	IF (old.employeeNumber <> new.employeeNumber) THEN
		SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "Employee Number cannot be modified";
	END IF;
    INSERT INTO salesRepresentatives_audit VALUES (new.employeeNumber, now(), "U", new.end_username, new.end_userreason);
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`salesRepresentatives_BEFORE_DELETE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `dbsalesv2.5G211`.`salesRepresentatives_BEFORE_DELETE` BEFORE DELETE ON `salesRepresentatives` FOR EACH ROW
BEGIN
	INSERT INTO salesRepresentatives_audit VALUES (old.employeeNumber, now(), "D", NULL, 'Deletion of Record');
END$$
DELIMITER ;


-- Audit for Table - DEPARTMENTS
ALTER TABLE `dbsalesv2.5G211`.`departments` 
ADD COLUMN `end_username` VARCHAR(45) NULL AFTER `deptManagerNumber`,
ADD COLUMN `end_userreason` VARCHAR(45) NULL AFTER `end_username`;

CREATE TABLE `dbsalesv2.5G211`.`departments_audit` (
  `deptCode` INT NOT NULL,
  `audit_timestamp` DATETIME NOT NULL,
  `activity` ENUM('C', 'U', 'D') NULL,
  `old_deptName` VARCHAR(45) NULL,
  `old_deptManagerNumber` INT NULL,
  `new_deptName` VARCHAR(45) NULL,
  `new_deptManagerNumber` INT NULL,
  `end_username` VARCHAR(45) NULL,
  `end_userreason` VARCHAR(45) NULL,
  PRIMARY KEY (`deptCode`, `audit_timestamp`))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`departments_BEFORE_INSERT`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `dbsalesv2.5G211`.`departments_BEFORE_INSERT` BEFORE INSERT ON `departments` FOR EACH ROW
BEGIN
	DECLARE newdeptCode INT;
    
    SELECT MAX(deptCode) + 1 INTO newdeptCode FROM departments;
    IF (newdeptCode IS NULL) THEN
		SET newdeptCode := 00001;
	END IF;
    
    SET new.deptCode := newdeptCode;
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`departments_AFTER_INSERT`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `dbsalesv2.5G211`.`departments_AFTER_INSERT` AFTER INSERT ON `departments` FOR EACH ROW
BEGIN
	INSERT INTO departments_audit VALUES (new.deptCode, now(), "C", NULL, NULL, new.deptName, new.deptManagerNumber, new.end_username, new.end_userreason);
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`departments_AFTER_UPDATE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `dbsalesv2.5G211`.`departments_AFTER_UPDATE` AFTER UPDATE ON `departments` FOR EACH ROW BEGIN
	IF(old.deptCode <> new.deptCode) THEN
		SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "Department Code cannot be modified";
	END IF;
    INSERT INTO departments_audit VALUES (new.deptCode, now(), "U", old.deptName, old.deptManagerNumber, new.deptName, new.deptManagerNumber, new.end_username, new.end_userreason);	
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`departments_BEFORE_DELETE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `dbsalesv2.5G211`.`departments_BEFORE_DELETE` BEFORE DELETE ON `departments` FOR EACH ROW
BEGIN
	INSERT INTO departments_audit VALUES (old.deptCode, now(), "D", old.deptName, old.deptManagerNumber, NULL, NULL, NULL, 'Deletion of Record');
END$$
DELIMITER ;

-- Audit for Table - BANKS
ALTER TABLE `dbsalesv2.5G211`.`banks` 
ADD COLUMN `end_username` VARCHAR(45) NULL AFTER `branchaddress`,
ADD COLUMN `end_userreason` VARCHAR(45) NULL AFTER `end_username`;

CREATE TABLE `dbsalesv2.5G211`.`banks_audit` (
  `bank` INT NOT NULL,
  `audit_timestamp` DATETIME NOT NULL,
  `activity` ENUM('C', 'U', 'D') NULL,
  `old_bankname` VARCHAR(45) NULL,
  `old_branch` VARCHAR(45) NULL,
  `old_branchaddress` VARCHAR(45) NULL,
  `new_bankname` VARCHAR(45) NULL,
  `new_branch` VARCHAR(45) NULL,
  `new_branchaddress` VARCHAR(45) NULL,
  `end_username` VARCHAR(45) NULL,
  `end_userreason` VARCHAR(45) NULL,
  PRIMARY KEY (`bank`, `audit_timestamp`));

DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`banks_BEFORE_INSERT`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `dbsalesv2.5G211`.`banks_BEFORE_INSERT` BEFORE INSERT ON `banks` FOR EACH ROW
BEGIN
	DECLARE newBank INT;
    
    SELECT MAX(bank) + 1 INTO newBank FROM banks;
    IF (newBank IS NULL) THEN
		SET newBank := 8001;
	END IF;
    
    SET new.bank := newBank;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`banks_AFTER_INSERT`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `dbsalesv2.5G211`.`banks_AFTER_INSERT` AFTER INSERT ON `banks` FOR EACH ROW
BEGIN
	INSERT INTO banks_audit	VALUES (new.bank, now(), 'C', NULL, NULL, NULL,
									new.bankname, new.branch, new.branchaddress,
									new.end_username, new.end_userreason);
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`banks_AFTER_UPDATE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `dbsalesv2.5G211`.`banks_AFTER_UPDATE` AFTER UPDATE ON `banks` FOR EACH ROW
BEGIN
	IF (old.bank <> new.bank) THEN 
		SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "bank ID cannot be modified";
	END IF;
	INSERT INTO banks_audit	VALUES (old.bank, now(), 'U', 
									old.bankname, old.branch, old.branchaddress,
									new.bankname, new.branch, new.branchaddress,
									new.end_username, new.end_userreason);
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`banks_BEFORE_DELETE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `dbsalesv2.5G211`.`banks_BEFORE_DELETE` BEFORE DELETE ON `banks` FOR EACH ROW
BEGIN
	INSERT INTO banks_audit	VALUES (old.bank, now(), 'D', 
									old.bankname, old.branch, old.branchaddress,
									NULL, NULL, NULL,
									NULL, 'Delection of Record');
END$$
DELIMITER ;
