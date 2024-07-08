DELIMITER $$
CREATE EVENT dbm211_creditLimitManagement
ON SCHEDULE EVERY 1 MONTH
STARTS '2024-07-01 00:00:00'
DO
BEGIN
	DECLARE i 					INT DEFAULT 0;
	DECLARE n 					INT DEFAULT 0;
    DECLARE total 				DOUBLE DEFAULT 0;
    DECLARE additionalTotal 	DOUBLE DEFAULT 0;
    DECLARE currCustomerNumber 	INT DEFAULT 0;
    DECLARE totalOrders 	    INT DEFAULT 0;
    
    -- Assigns n to how many customers there are
	SELECT COUNT(customerNumber) INTO n
    FROM customers;
    
	-- While statement to iterate through each customerNumber and update their creditLimit
	WHILE i < n DO 
		-- Gets each customerNumber in the table per iteration
		SELECT 		customerNumber INTO currCustomerNumber 
        FROM 		customers 
        ORDER BY 	customerNumber ASC LIMIT 1 OFFSET i; 

        -- Gets how many orders the customer has 
		SELECT 		COUNT(o.orderNumber) INTO totalOrders
	    FROM 		customers c JOIN orders o ON o.customerNumber = c.customerNumber
		WHERE 		o.customerNumber = currCustomerNumber
        AND 		YEAR(o.orderDate) = YEAR(NOW()) 
        AND 		MONTH(o.orderDate) = MONTH(NOW());
        
        -- Calculates the total amount of orders for the current month and year
        IF (totalOrders > 15) THEN
            SELECT SUM(total) * 2 INTO total
            FROM (
                SELECT (quantityOrdered * priceEach) AS total
                FROM orders o
                JOIN orderdetails od ON o.orderNumber = od.orderNumber
                WHERE o.customerNumber = currCustomerNumber
                AND YEAR(o.orderDate) = YEAR(NOW())
                AND MONTH(o.orderDate) = MONTH(NOW())
                ORDER BY o.orderNumber ASC
                LIMIT 15
            ) AS subquery;
        ELSE 
            SELECT 		SUM(quantityOrdered * priceEach) * 2 INTO total
            FROM 		orders o JOIN orderdetails od ON o.orderNumber = od.orderNumber
            WHERE 		o.customerNumber = currCustomerNumber
            AND 		YEAR(o.orderDate) = YEAR(NOW()) 
            AND 		MONTH(o.orderDate) = MONTH(NOW());
        END IF;


        
        -- Updates creditLimit

        IF (totalOrders > 15) THEN
            SELECT SUM(total) INTO additionalTotal
            FROM (
                SELECT (quantityOrdered * priceEach) AS total
                FROM orders o
                JOIN orderdetails od ON o.orderNumber = od.orderNumber
                WHERE o.customerNumber = currCustomerNumber
                AND YEAR(o.orderDate) = YEAR(NOW())
                AND MONTH(o.orderDate) = MONTH(NOW())
                ORDER BY o.orderNumber ASC
                LIMIT 100 OFFSET 15
            ) AS subquery;

			UPDATE 		customers 
			SET 		creditLimit = ROUND((total + additionalTotal), -2) 
			WHERE 		customerNumber = currCustomerNumber;
        ELSE 
            IF (total > 0) THEN
                UPDATE 		customers 
                SET 		creditLimit = ROUND(total, -2) 
                WHERE 		customerNumber = currCustomerNumber;
            END IF;
        END IF;
		
        -- Iteration increment
        SET 		i = i + 1;
	END WHILE;
END$$
DELIMITER ;








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
    JOIN (  SELECT o.customerNumber, ROUND(SUM(od.quantityOrdered * od.priceEach) * 2,2) AS newCreditLimit
            FROM orders o 	JOIN orderdetails od ON o.orderNumber = od.orderNumber
            GROUP BY o.customerNumber 
         ) AS n ON c.customerNumber = n.customerNumber
    SET c.creditLimit = n.newCreditLimit;

    UPDATE customers c
    JOIN (  SELECT 	o.customerNumber, COUNT(DISTINCT(od.productCode)), MONTH(o.orderDate) AS MONTH, YEAR(o.orderDate) AS YEAR,
					ROUND(MAX(od.quantityOrdered * od.priceEach),2) AS highestOrderAmount
            FROM 	customers c JOIN orders o ON c.customerNumber
                                JOIN orderdetails od ON o.orderNumber = od.orderNumber
            WHERE 	MONTH(o.orderDate) = previousMonth
            AND 	YEAR(o.orderDate) = previousYear
            GROUP BY o.customerNumber
            HAVING COUNT(DISTINCT(od.productCode)) > 15
        ) AS n ON c.customerNumber = n.customerNumber
    SET c.creditLimit = c.creditLimit + n.highestOrderAmount;
END$$
DELIMITER ;
