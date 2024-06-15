-- ORDERS TABLE
-- BEFORE INSERT
-- LEGEND: 
-- 1001: Logic Error
-- 1002: Column Error
-- 1003: Specs Error
DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`orders_BEFORE_INSERT`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
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
END$$
DELIMITER ;


-- BEFORE UPDATE
DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`orders_BEFORE_UPDATE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
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
        IF NEW.comments IS NULL OR NEW.comments = '' THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'ERROR 1003: Comment is null. A comment is required when cancelling an order.';
        END IF;
    END IF; 
END$$
DELIMITER ;

-- BEFORE DELETE
DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`orders_BEFORE_DELETE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `orders_BEFORE_DELETE` BEFORE DELETE ON `orders` FOR EACH ROW BEGIN
	-- Prevent deletion of orders by raising an error
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'ERROR 100x: Orders cannot be deleted. Please cancel the order instead.'; 
END$$
DELIMITER ;


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-- ORDERDETAILS TABLE
ALTER TABLE `dbsalesv2.5G211`.`orderdetails` 
DROP FOREIGN KEY `FK0008`;
ALTER TABLE `dbsalesv2.5G211`.`orderdetails` 
ADD INDEX `FK0008_idx` (`productCode` ASC) VISIBLE,
DROP INDEX `FK0008_idx` ;
;
ALTER TABLE `dbsalesv2.5G211`.`orderdetails` 
ADD CONSTRAINT `FK0008`
  FOREIGN KEY (`productCode`)
  REFERENCES `dbsalesv2.5G211`.`products` (`productCode`);

-- BEFORE INSERT
DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`orderdetails_BEFORE_INSERT`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
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
END$$
DELIMITER ;

-- AFTER INSERT
DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`orderdetails_AFTER_INSERT`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `orderdetails_AFTER_INSERT` AFTER INSERT ON `orderdetails` FOR EACH ROW BEGIN
    -- Update Inventory
    UPDATE current_products 
    SET quantityInStock = quantityInStock - NEW.quantityOrdered 
    WHERE productCode = NEW.productCode;
    
    -- Create Audit Record
    INSERT INTO orderdetails_audit VALUES (NEW.orderNumber, NEW.productCode, NOW(), 'C',
										   NULL, NULL, NULL, NULL,
										   NEW.quantityOrdered, NEW.priceEach, NEW.orderLineNumber, NEW.referenceNo,
                                           NEW.end_username, NEW.end_userreason);
END$$
DELIMITER ;

-- BEFORE UPDATE
DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`orderdetails_BEFORE_UPDATE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `orderdetails_BEFORE_UPDATE` BEFORE UPDATE ON `orderdetails` FOR EACH ROW BEGIN
    -- No updates on LineNumbers
    SET NEW.orderLineNumber := OLD.orderLineNumber;
    
    -- Restrict changes to Identifiers
    IF (isIntChanged(OLD.orderNumber, NEW.orderNumber) = TRUE) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "ERROR 100x: Order Number cannot be updated";
    END IF;

    IF (isStringChanged(OLD.productCode, NEW.productCode) = TRUE) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "ERROR 100x: Product Code cannot be updated";
    END IF; 
    
    -- Determine difference of updated quantity
    IF (checkProjectedQuantity(NEW.productCode, NEW.quantityOrdered, OLD.quantityOrdered) < 0) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "ERROR 100x: Ordered quantity will cause below zero inventory quantity";
    END IF;   
    
    -- Check for Price Range
    IF (validPrice(NEW.productCode, NEW.priceEach) = 0) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "ERROR 100x: Price indicated is beyond price Range allowed";
    END IF; 

    -- ReferenceNo can only be updated if status is Shipped
	IF (checkOrderStatus(OLD.orderNumber) <> "Shipped" AND isIntChanged(OLD.referenceNo, NEW.referenceNo) = TRUE) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ERROR 100x: Reference No can only be updated if status is Shipped.';
    END IF;
    
    -- QuantityOrdered and PriceEach can only be updated if status is In Process
    IF (checkOrderStatus(OLD.orderNumber) <> "In Process" AND (isIntChanged(OLD.quantityOrdered, NEW.quantityOrdered) = TRUE OR 
															   isDoubleChanged(OLD.priceEach, NEW.priceEach) = TRUE)) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ERROR 100x: QuantityOrdered and PriceEach can only be updated if status is In Process.';
    END IF;
END$$
DELIMITER ;

-- AFTER UPDATE
DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`orderdetails_AFTER_UPDATE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `orderdetails_AFTER_UPDATE` AFTER UPDATE ON `orderdetails` FOR EACH ROW BEGIN
   -- Update Inventory
    UPDATE current_products SET quantityInStock = checkProjectedQuantity(NEW.productCode, NEW.quantityOrdered, OLD.quantityOrdered)
    WHERE productCode = NEW.productCode;

    -- For Testing
    -- SET message := CONCAT(quantity_toDeduct, "[]", quantity_toAdd, "[]", OLD.quantityOrdered);
    -- SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = message;

	-- Create Audit Record
    INSERT INTO orderdetails_audit VALUES (NEW.orderNumber, NEW.productCode, NOW(), 'U',
										   OLD.quantityOrdered, OLD.priceEach, OLD.orderLineNumber, OLD.referenceNo,
										   NEW.quantityOrdered, NEW.priceEach, NEW.orderLineNumber, NEW.referenceNo,
                                           NEW.end_username, NEW.end_userreason);
END$$
DELIMITER ;


-- BEFORE DELETE
DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`orderdetails_BEFORE_DELETE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `orderdetails_BEFORE_DELETE` BEFORE DELETE ON `orderdetails` FOR EACH ROW BEGIN
    IF (checkOrderStatus(OLD.orderNumber) <> "In Process") THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "ERROR 100x: Shipped Orders can't be deleted.";
    END IF;

	-- Create Audit Record
    INSERT INTO orderdetails_audit VALUES (OLD.orderNumber, OLD.productCode, NOW(), 'D',
										   OLD.quantityOrdered, OLD.priceEach, OLD.orderLineNumber, OLD.referenceNo,
										   NULL, NULL, NULL, NULL,
                                           OLD.end_username, OLD.end_userreason);  
END$$
DELIMITER ;


-- AFTER DELETE
DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`orderdetails_AFTER_DELETE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `orderdetails_AFTER_DELETE` AFTER DELETE ON `orderdetails` FOR EACH ROW BEGIN
	-- Update inventory: add back the ordered quantities
    UPDATE current_products 
    SET quantityInStock = quantityInStock + OLD.quantityOrdered 
    WHERE productCode = OLD.productCode;
    
	IF NOT EXISTS (SELECT orderNumber FROM orderdetails WHERE orderNumber = OLD.orderNumber) THEN
        UPDATE orders SET status = "Cancelled", 
						  end_username = "System", 
                          comments = "No more ordered products",
                          end_userreason = "No more ordered products"
		WHERE orderNumber = OLD.orderNumber;
    END IF; 
END$$
DELIMITER ;

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- CURRENT_PRODUCTS
-- BEFORE UPDATE
DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`current_products_BEFORE_UPDATE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `dbsalesv2.5G211`.`current_products_BEFORE_UPDATE` BEFORE UPDATE ON `current_products` FOR EACH ROW
BEGIN
	IF (isStringChanged(OLD.product_type, NEW.product_type) = TRUE) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "ERROR 100x: Product categories cannot be modified.";
    END IF;   
END$$
DELIMITER ;


-- CURRENT_PRODUCTS
-- BEFORE UPDATE
DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`current_products_BEFORE_UPDATE`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `current_products_BEFORE_UPDATE` BEFORE UPDATE ON `current_products` FOR EACH ROW BEGIN
	IF (isStringChanged(OLD.product_type, NEW.product_type) = TRUE) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "ERROR 100x: Product categories cannot be modified.";
    END IF;
    
    IF (NEW.quantityInStock = 0) THEN
		CALL discontinueProduct(OLD.productCode, "No more stocks", NULL);
    END IF;
END$$
DELIMITER ;

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- PRODUCTS
-- BEFORE INSERT
DROP TRIGGER IF EXISTS `dbsalesv2.5G211`.`products_BEFORE_INSERT`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE TRIGGER `dbsalesv2.5G211`.`products_BEFORE_INSERT` BEFORE INSERT ON `products` FOR EACH ROW
BEGIN
	IF (NEW.product_type IS NULL) THEN
        
    END IF;

	IF (NEW. IS NULL) THEN
        
    END IF;
END$$
DELIMITER ;

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-- FUNCTIONS
-- APPENDCOMMENTS
USE `dbsalesv2.5G211`;
DROP function IF EXISTS `appendComments`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE FUNCTION `appendComments` (v_OLD_comments TEXT, v_NEW_comments TEXT)
RETURNS TEXT
	NO SQL
BEGIN
	DECLARE concat_string TEXT;
	SET concat_string := CONCAT(v_OLD_comments, " // ");
	SET concat_string := CONCAT(concat_string, v_NEW_comments);
	SET v_NEW_comments := concat_string;
RETURN concat_string;
END$$

DELIMITER ;

-- CHECKORDERSTATUS
USE `dbsalesv2.5G211`;
DROP function IF EXISTS `checkOrderStatus`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE FUNCTION `checkOrderStatus`(v_orderNumber INT) 
RETURNS VARCHAR (15)
    READS SQL DATA
BEGIN
    DECLARE order_status VARCHAR(15);
    SELECT status INTO order_status
    FROM orders
    WHERE orderNumber = v_orderNumber;
RETURN order_status;
END$$

DELIMITER ;


-- ISDATETIMECHANGED
USE `dbsalesv2.5G211`;
DROP function IF EXISTS `isDatetimeChanged`;

USE `dbsalesv2.5G211`;
DROP function IF EXISTS `dbsalesv2.5G211`.`isDatetimeChanged`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE FUNCTION `isDatetimeChanged`(v_OLD_column DATETIME, v_NEW_column DATETIME) 
RETURNS tinyint(1)
    NO SQL
    DETERMINISTIC
BEGIN
	IF (v_OLD_column <> v_NEW_column OR (v_OLD_column IS NULL AND v_NEW_column IS NOT NULL) 
											 OR (v_OLD_column IS NOT NULL AND v_NEW_column IS NULL)) THEN
		RETURN TRUE;
    END IF; 
RETURN FALSE;
END$$

DELIMITER ;

-- ISDOUBLECHANGED
USE `dbsalesv2.5G211`;
DROP function IF EXISTS `isDoubleChanged`;

USE `dbsalesv2.5G211`;
DROP function IF EXISTS `dbsalesv2.5G211`.`isDoubleChanged`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE FUNCTION `isDoubleChanged`(v_OLD_column DOUBLE, v_NEW_column DOUBLE) RETURNS tinyint(1)
    NO SQL
    DETERMINISTIC
BEGIN
	IF (v_OLD_column <> v_NEW_column OR (v_OLD_column IS NULL AND v_NEW_column IS NOT NULL) 
											 OR (v_OLD_column IS NOT NULL AND v_NEW_column IS NULL)) THEN
		RETURN TRUE;
    END IF; 
RETURN FALSE;
END$$

DELIMITER ;


-- ISINTCHANGED
USE `dbsalesv2.5G211`;
DROP function IF EXISTS `isIntChanged`;

USE `dbsalesv2.5G211`;
DROP function IF EXISTS `dbsalesv2.5G211`.`isIntChanged`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE FUNCTION `isIntChanged`(v_OLD_column INT, v_NEW_column INT) RETURNS tinyint(1)
    NO SQL
    DETERMINISTIC
BEGIN
	IF (v_OLD_column <> v_NEW_column OR (v_OLD_column IS NULL AND v_NEW_column IS NOT NULL) 
											 OR (v_OLD_column IS NOT NULL AND v_NEW_column IS NULL)) THEN
		RETURN TRUE;
    END IF;
RETURN FALSE; 
END$$

DELIMITER ;

-- ISSTATUSUPDATEVALID
USE `dbsalesv2.5G211`;
DROP function IF EXISTS `isStatusUpdateValid`;

USE `dbsalesv2.5G211`;
DROP function IF EXISTS `dbsalesv2.5G211`.`isStatusUpdateValid`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE FUNCTION `isStatusUpdateValid`(v_OLD_status VARCHAR(15), v_NEW_status VARCHAR (15)) RETURNS tinyint(1)
    NO SQL
BEGIN
	IF (v_OLD_status = "In Process" AND !(v_NEW_status = "Shipped" OR v_NEW_status = "Cancelled")) THEN
		RETURN FALSE;
	ELSEIF (v_OLD_status = "Shipped" AND !(v_NEW_status = "Disputed" OR v_NEW_status = "Completed" OR v_NEW_status = "Cancelled")) THEN
		RETURN FALSE;
	ELSEIF (v_OLD_status = "Disputed" AND !(v_NEW_status = "Resolved" OR v_NEW_status = "Cancelled")) THEN
		RETURN FALSE;
	ELSEIF (v_OLD_status = "Resolved" AND !(v_NEW_status = "Completed" OR v_NEW_status = "Cancelled")) THEN
		RETURN FALSE;
	END IF; 
RETURN TRUE;
END$$

DELIMITER ;


-- ISSTRINGCHANGED
USE `dbsalesv2.5G211`;
DROP function IF EXISTS `isStringChanged`;

USE `dbsalesv2.5G211`;
DROP function IF EXISTS `dbsalesv2.5G211`.`isStringChanged`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE FUNCTION `isStringChanged`(v_OLD_identifier VARCHAR(15), v_NEW_identifier VARCHAR(15)) RETURNS tinyint(1)
    NO SQL
    DETERMINISTIC
BEGIN
	IF (v_OLD_identifier <> v_NEW_identifier OR (v_OLD_identifier IS NULL AND v_NEW_identifier IS NOT NULL) 
											 OR (v_OLD_identifier IS NOT NULL AND v_NEW_identifier IS NULL)) THEN
		RETURN TRUE;
    END IF; 
RETURN FALSE;
END$$

DELIMITER ;
-- ISTARGETDELIVERYVALID
USE `dbsalesv2.5G211`;
DROP function IF EXISTS `isTargetDeliveryValid`;

USE `dbsalesv2.5G211`;
DROP function IF EXISTS `dbsalesv2.5G211`.`isTargetDeliveryValid`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE FUNCTION `isTargetDeliveryValid`(v_requiredDate DATETIME, v_orderDate DATETIME) RETURNS tinyint(1)
    NO SQL
BEGIN
	IF (DATEDIFF(v_requiredDate, v_orderDate) < 3) THEN
		RETURN 0;
    END IF; 
RETURN 1;
END$$

DELIMITER ;

-- VALIDPRICE
USE `dbsalesv2.5G211`;
DROP function IF EXISTS `validPrice`;

USE `dbsalesv2.5G211`;
DROP function IF EXISTS `dbsalesv2.5G211`.`validPrice`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE FUNCTION `validPrice`(v_productCode VARCHAR(15), v_providedPrice DOUBLE) RETURNS tinyint(1)
    READS SQL DATA
    DETERMINISTIC
BEGIN
    
    DECLARE min_price 			DOUBLE;
    DECLARE max_price 			DOUBLE;
/*
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
*/
	SET max_price := getPriceRange(v_productCode, "max");
    SET min_price := getPriceRange(v_productCode, "min");
    
	IF (max_price IS NULL) OR (min_price IS NULL) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "ERROR 9004: Price of the product cannot be determined";
    END IF;
    
	IF (v_providedPrice > max_price) OR (v_providedPrice < min_price) THEN
		RETURN 0;
	END IF;
	RETURN 1;
END$$

DELIMITER ;



-- CHECKPROJECTEDQUANTITY
USE `dbsalesv2.5G211`;
DROP function IF EXISTS `checkProjectedQuantity`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE FUNCTION `checkProjectedQuantity` (v_productCode VARCHAR(15), v_NEWquantityOrdered INT, v_OLDquantityOrdered INT)
RETURNS INTEGER
	READS SQL DATA
    DETERMINISTIC
BEGIN
	DECLARE quantity_difference INT;
    DECLARE quantity_toDeduct INT;
    DECLARE quantity_toAdd INT;
    DECLARE projected_Quantity INT;
    
    
	SET quantity_difference := v_NEWquantityOrdered - v_OLDquantityOrdered;
    
	IF (quantity_difference > 0) THEN
		SET quantity_toDeduct := quantity_difference;
		SET quantity_toAdd    := 0;
	ELSEIF (quantity_difference < 0) THEN
		SET quantity_toDeduct := 0;
		SET quantity_toAdd    := -quantity_difference;
	ELSE
		SET quantity_toDeduct := 0;
		SET quantity_toAdd    := 0;
	END IF;
    
    -- Check if updated Quantity will cause a below zero inventory
    SELECT (quantityInStock + quantity_toAdd - quantity_toDeduct) INTO projected_Quantity
    FROM current_products WHERE productCode = v_productCode;
    
    -- For Testing
    -- SET message := CONCAT(quantity_toDeduct, "[]", quantity_toAdd, "[]", projected_Quantity, "[]", OLD.quantityOrdered);
    -- SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = message;
    
	RETURN projected_Quantity;
END$$

DELIMITER ;


-- GETPRICERANGE
USE `dbsalesv2.5G211`;
DROP function IF EXISTS `getPriceRange`;

USE `dbsalesv2.5G211`;
DROP function IF EXISTS `dbsalesv2.5G211`.`getPriceRange`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
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
		RETURN min_price;
    ELSEIF (v_maxOrMin = "max") THEN
		RETURN max_price;
    END IF;
RETURN 0;
END$$

DELIMITER ;

-- GETMSRP
DELIMITER $$

CREATE FUNCTION getMSRP(v_productCode VARCHAR(15)) 
RETURNS DECIMAL(9,2)
DETERMINISTIC
BEGIN
    DECLARE msrp DECIMAL(9,2);
    DECLARE v_productType CHAR(1);

    -- Check if the product is in the wholesale table
    SELECT product_type INTO v_productType FROM current_products WHERE productCode = v_productCode;
    
    IF (v_productType = 'W') THEN
        SELECT MSRP INTO msrp
        FROM product_wholesale
        WHERE productCode = productCode;
	ELSE
        -- Default MSRP from the products table if not a wholesale product
        SELECT MSRP INTO msrp
        FROM products
        WHERE productCode = productCode;
    END IF;

    RETURN msrp;
END$$

DELIMITER ;

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- STORED PROCEDUERS
-- ADD_PRODUCT
USE `dbsalesv2.5G211`;
DROP procedure IF EXISTS `add_product`;

USE `dbsalesv2.5G211`;
DROP procedure IF EXISTS `dbsalesv2.5G211`.`add_product`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE PROCEDURE `add_product`(	IN v_productCode			VARCHAR (15),
                                IN v_productName			VARCHAR (70),
                                IN v_productScale			VARCHAR (10),
                                IN v_productVendor			VARCHAR (50),
                                IN v_productDescription		TEXT,
                                IN v_buyPrice				DOUBLE,
                                IN v_productType			ENUM('R','W'),
                                IN v_quantityInStock		SMALLINT,
                                IN v_MSRP					DECIMAL(9,2),
                                IN v_productLine			VARCHAR (50)
								)
BEGIN
	INSERT INTO products VALUES (v_productCode, v_productName, v_productScale, v_productVendor, v_productDescription, v_buyPrice, 'C', CURRENT_USER, "NEW Record");
    INSERT INTO current_products VALUES (v_productCode, v_productType, v_quantityInStock, CURRENT_USER, "NEW Record");
    IF (v_productType = 'R') THEN
		INSERT INTO product_retail VALUES (v_productCode, CURRENT_USER, "NEW Record");
		INSERT INTO product_pricing VALUES (v_productCode, DATE(NOW()), DATE(DATE_ADD(NOW(), INTERVAL 7 DAY)), v_MSRP, CURRENT_USER, "NEW Record");
    ELSE
		INSERT INTO product_wholesale VALUES (v_productCode, v_MSRP, CURRENT_USER, "NEW Record");
    END IF;
    INSERT INTO product_productlines VALUES (v_productCode, v_productLine, CURRENT_USER, "NEW Record"); 
END$$

DELIMITER ;

-- UPDATE_PRODUCT
USE `dbsalesv2.5G211`;
DROP procedure IF EXISTS `update_product`;

USE `dbsalesv2.5G211`;
DROP procedure IF EXISTS `dbsalesv2.5G211`.`update_product`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE PROCEDURE `update_product`(	IN v_productCode			VARCHAR (15),
									IN v_productName			VARCHAR (70),
									IN v_productScale			VARCHAR (10),
									IN v_productVendor			VARCHAR (50),
									IN v_productDescription		TEXT,
									IN v_buyPrice				DOUBLE,
									IN v_productType			ENUM('R','W'),
									IN v_quantityInStock		SMALLINT,
									IN v_MSRP					DECIMAL(9,2),
									IN v_productLine			VARCHAR (50)
								)
BEGIN
	UPDATE products SET productName = v_productName, 
                        productScale = v_productScale, 
                        productVendor = v_productVendor, 
                        productDescription = v_productDescription, 
                        buyPrice = v_buyPrice
	WHERE productCode = v_productCode;
    
    UPDATE current_products SET productType = v_productType, 
                                quantityInStock = v_quantityInStock
	WHERE productCode = v_productCode;
    
    
    IF (v_productType = 'R') THEN
		UPDATE product_pricing SET startdate = DATE(NOW()), 
                                   enddate = DATE(DATE_ADD(NOW(), INTERVAL 7 DAY)),
								   MSRP = v_MSRP
	   WHERE productCode = v_productCode;
    ELSE
		UPDATE product_pricing SET MSRP = v_MSRP
		WHERE productCode = v_productCode;
    END IF;
    
    UPDATE product_productlines SET productLine = v_productLine
    WHERE productCode = v_productCode;
END$$

DELIMITER ;


-- DISCONTINUEPRODUCT
USE `dbsalesv2.5G211`;
DROP procedure IF EXISTS `discontinueProduct`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE PROCEDURE `discontinueProduct` (v_productCode VARCHAR(15), v_reason VARCHAR (45), v_inventory_manager INT)
BEGIN
	DECLARE currProductType CHAR(1);
    
	UPDATE products SET product_category = 'D'
	WHERE productCode = v_productCode;
    INSERT INTO discontinued_products VALUES (v_productCode, v_reason, v_inventory_manager, CURRENT_USER, "NEW Record");
    
    SELECT product_type INTO currProductType FROM current_products WHERE productCode = v_productCode;
    
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

-- RECONTINUEPRODUCT
USE `dbsalesv2.5G211`;
DROP procedure IF EXISTS `recontinueProduct`;

USE `dbsalesv2.5G211`;
DROP procedure IF EXISTS `dbsalesv2.5G211`.`recontinueProduct`;

DELIMITER $$
USE `dbsalesv2.5G211`$$
CREATE PROCEDURE `recontinueProduct`(v_productCode VARCHAR(15), v_quantityInStock SMALLINT)
BEGIN
	DECLARE currProductType CHAR(1);
	DECLARE currMSRP DECIMAL(9,2);
	DECLARE currQuantityInStock SMALLINT;
    
	UPDATE products SET product_category = 'C'
	WHERE productCode = v_productCode;
    
    DELETE FROM discontinued_products WHERE productCode = v_productCode;
    
    SELECT OLD_product_type, OLD_quantityInStock INTO currProductType, currQuantityInStock 
    FROM current_products_audit WHERE productCode = v_productCode ORDER BY audit_timestamp LIMIT 1;
    

    IF (currProductType = 'R') THEN
		SELECT OLD_MSRP INTO currMSRP FROM product_pricing_audit WHERE productCode = v_productCode ORDER BY audit_timestamp LIMIT 1;
		IF (v_quantityInStock IS NULL) THEN
			INSERT INTO current_products VALUES (v_productCode, currProductType, currQuantityInStock, CURRENT_USER, "NEW Record");
		ELSE 
			INSERT INTO current_products VALUES (v_productCode, currProductType, v_quantityInStock, CURRENT_USER, "NEW Record");
		END IF;
		INSERT INTO product_retail VALUES (v_productCode, CURRENT_USER, "NEW Record");
		INSERT INTO product_pricing VALUES (v_productCode, DATE(NOW()), DATE_ADD(NOW(), INTERVAL 7 DAY), currMSRP, CURRENT_USER, "NEW Record");
	ELSE 
		SELECT OLD_MSRP INTO currMSRP FROM product_wholesale_audit WHERE productCode = v_productCode ORDER BY audit_timestamp LIMIT 1;
		IF (v_quantityInStock IS NULL) THEN
			INSERT INTO current_products VALUES (v_productCode, currProductType, currQuantityInStock, CURRENT_USER, "NEW Record");
		ELSE 
			INSERT INTO current_products VALUES (v_productCode, currProductType, v_quantityInStock, CURRENT_USER, "NEW Record");
		END IF;
        INSERT INTO product_wholesale VALUES (v_productCode, currMSRP, CURRENT_USER, "NEW Record");
    END IF;
END$$

DELIMITER ;
