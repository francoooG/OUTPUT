DROP TRIGGER IF EXISTS `dbsalesV2.5G211`.`product_pricing_BEFORE_INSERT`;

DELIMITER $$
USE `dbsalesV2.5G211`$$
CREATE TRIGGER `product_pricing_BEFORE_INSERT` BEFORE INSERT ON `product_pricing` FOR EACH ROW BEGIN
	SET new.startdate := NOW();
    SET NEW.endDate:= NOW() + INTERVAL 1 WEEK;
END$$
DELIMITER ;
DROP TRIGGER IF EXISTS `dbsalesV2.5G211`.`product_pricing_BEFORE_UPDATE`;

DELIMITER $$
USE `dbsalesV2.5G211`$$
CREATE TRIGGER `product_pricing_BEFORE_UPDATE` BEFORE UPDATE ON `product_pricing` FOR EACH ROW BEGIN
	IF (old.productCode <> new.productCode) THEN
		SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "Product ID cannot be modified";
    END IF;
    IF (old.startdate <> new.startdate) THEN
		SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "startdate cannot be modified";
    END IF;
    
    IF (DATEDIFF(NEW.endDate, OLD.startDate) > 7) THEN
		SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "Maximum of 1 week from the start date only";
    END IF;
END$$
DELIMITER ;


USE `dbsalesV2.5G211`;
DROP function IF EXISTS `getMSRP`;

USE `dbsalesV2.5G211`;
DROP function IF EXISTS `dbsalesV2.5G211`.`getMSRP`;
;

DELIMITER $$
USE `dbsalesV2.5G211`$$
CREATE FUNCTION `getMSRP`(v_productCode VARCHAR(15)) RETURNS decimal(9,2)
    DETERMINISTIC
BEGIN
	DECLARE curr_productType 	CHAR(1);
	DECLARE currMSRP	DOUBLE;
    
	SELECT product_type INTO curr_productType FROM current_products 
    WHERE productCode = v_productCode;
    
    IF (curr_productType = 'W') THEN
		SELECT MSRP INTO currMSRP
        FROM product_wholesale WHERE productCode = v_productCode;
    ELSEIF (curr_productType = 'R') THEN
		SELECT MSRP INTO currMSRP
        FROM   product_pricing 
        WHERE  productCode = v_productCode
        AND    DATE(NOW()) <= endDate AND DATE(NOW()) >= startDate;
    END IF;
    
	RETURN currMSRP; 
END$$

DELIMITER ;
;

