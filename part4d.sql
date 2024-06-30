DROP EVENT dbm211_creditLimitManagement;

DELIMITER $$
CREATE EVENT dbm211_creditLimitManagement
ON SCHEDULE EVERY 50 SECOND
STARTS NOW()
DO
BEGIN
	DECLARE i 					INT DEFAULT 0;
	DECLARE n 					INT DEFAULT 0;
    DECLARE total 				DOUBLE DEFAULT 0;
    DECLARE currCustomerNumber 	INT DEFAULT 0;
    
    -- Assigns n to how many customers there are
	SELECT COUNT(customerNumber) INTO n
    FROM customers;
    
	-- While statement to iterate through each customerNumber and update their creditLimit
	WHILE i < n DO 
		-- Gets each customerNumber in the table per iteration
		SELECT 		customerNumber INTO currCustomerNumber 
        FROM 		customers 
        ORDER BY 	customerNumber ASC LIMIT 1 OFFSET i; 
        
        -- Calculates the total amount of orders for the current month and year
		SELECT 		SUM(quantityOrdered * priceEach) INTO total
	    FROM 		orders o JOIN orderdetails od ON o.orderNumber = od.orderNumber
		WHERE 		o.customerNumber = currCustomerNumber
        AND 		YEAR(o.orderDate) = YEAR(NOW()) 
        AND 		MONTH(o.orderDate) = MONTH(NOW());
        
        -- Updates creditLimit
        IF (total > 0) THEN
			UPDATE 		customers 
			SET 		creditLimit = ROUND(total, 2) 
			WHERE 		customerNumber = currCustomerNumber;
        END IF;
		
        -- Iteration increment
        SET 		i = i + 1;
	END WHILE;
END$$
DELIMITER ;