ALTER TABLE `dbsalesv2.5g211`.`salesrepassignments` 
DROP FOREIGN KEY `FK-88_001`;
ALTER TABLE `dbsalesv2.5g211`.`salesrepassignments` 
ADD INDEX `FK-88_001_idx` (`employeeNumber` ASC) VISIBLE,
DROP PRIMARY KEY;
;
ALTER TABLE `dbsalesv2.5g211`.`salesrepassignments` 
ADD CONSTRAINT `FK-88_001`
  FOREIGN KEY (`employeeNumber`)
  REFERENCES `dbsalesv2.5g211`.`employees` (`employeeNumber`);



-- Change sales_managers employeeNumber foreign key from Non_SalesRepresentatives to employees
ALTER TABLE `dbsalesv2.5g211`.`sales_managers` 
DROP FOREIGN KEY `FK-89_001`;
ALTER TABLE `dbsalesv2.5g211`.`sales_managers` 
ADD INDEX `FK-89_001_idx` (`employeeNumber` ASC) VISIBLE,
DROP PRIMARY KEY;
;
ALTER TABLE `dbsalesv2.5g211`.`sales_managers` 
ADD CONSTRAINT `FK-89_001`
  FOREIGN KEY (`employeeNumber`)
  REFERENCES `dbsalesv2.5g211`.`employees` (`employeeNumber`);



-- Change inventory_managers employeeNumber foreign key from Non_SalesRepresentatives to employees
ALTER TABLE `dbsalesv2.5g211`.`inventory_managers` 
DROP FOREIGN KEY `FK-92_001`;
ALTER TABLE `dbsalesv2.5g211`.`inventory_managers` 
ADD INDEX `FK-92_001_idx` (`employeeNumber` ASC) VISIBLE,
DROP PRIMARY KEY;
;
ALTER TABLE `dbsalesv2.5g211`.`inventory_managers` 
ADD CONSTRAINT `FK-92_001`
  FOREIGN KEY (`employeeNumber`)
  REFERENCES `dbsalesv2.5g211`.`employees` (`employeeNumber`);







/* Part 4C.a
At any time and because of employee movements, promotions and re-assignments, employees’ employee types can change.
1. Employees can change employee types at any time
    1.a Job titles have to change along with employee types
    1.b Job titles have to align with employee types
2. Sales representatives keep their salesRepAssignments info when employee type and job title is changed
    2.a 
*/





-- 2
-- Job Titles are controlled values from a set of job titles available in the organization. 
CREATE TABLE `dbsalesv2.5g211`.`job_titles_list` (
  `jobTitle` VARCHAR(50) NOT NULL,
  `status` ENUM('U', 'D') NULL,
  PRIMARY KEY (`jobTitle`));


DROP TRIGGER IF EXISTS `dbsalesv2.5g211`.`employees_BEFORE_INSERT`;

DELIMITER $$
USE `dbsalesv2.5g211`$$
CREATE TRIGGER `employees_BEFORE_INSERT` BEFORE INSERT ON `employees` FOR EACH ROW BEGIN
	DECLARE newEmployeeNumber INT;
    DECLARE jobTitleStatus VARCHAR(1);
    
    SELECT MAX(employeeNumber) + 1 INTO newEmployeeNumber FROM employees;
    IF (newEmployeeNumber IS NULL) THEN
		SET newEmployeeNumber := 1;
	END IF;
    
    IF NOT EXISTS (SELECT jobTitle FROM job_titles_list WHERE jobTitle = NEW.jobTitle) THEN
		SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "ERROR: Job Title does not exist. Please choose a valid one.";
    END IF;
    
    IF (NEW.employee_type IS NULL) THEN
		SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "ERROR: Please choose an employee type.";
    END IF;
    
    SELECT status INTO jobTitleStatus FROM job_titles_list WHERE jobTitle = NEW.jobTitle;
    IF (jobTitleStatus = 'D') THEN
		SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "ERROR: Job position already filled.";
    END IF;
    
    IF (is_JobAndType_consistent(NEW.employee_type, NEW.jobTitle) = FALSE) THEN
		SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "ERROR: Job title and employee type do not match.";
    END IF;
    
    SET new.employeeNumber := newEmployeeNumber;  
    
    SET NEW.end_username = CURRENT_USER;
END$$
DELIMITER ;
DROP TRIGGER IF EXISTS `dbsalesv2.5g211`.`employees_AFTER_INSERT`;


DELIMITER $$
USE `dbsalesv2.5g211`$$
CREATE TRIGGER `employees_AFTER_INSERT` AFTER INSERT ON `employees` FOR EACH ROW BEGIN
	IF (NEW.jobTitle != 'Sales Rep') THEN
		UPDATE job_titles_list SET status = 'D' WHERE jobTitle = NEW.jobTitle;
	END IF;
    
    IF (NEW.employee_type = 'S') THEN
		INSERT INTO salesrepresentatives (employeeNumber) VALUES (NEW.employeeNumber);
	ELSE
		IF (NEW.jobTitle LIKE '%Higher Ups%') THEN
			INSERT INTO non_salesrepresentatives (employeeNumber, deptCode) VALUES (NEW.employeeNumber, 403);
		ELSEIF (NEW.jobTitle LIKE '%Sales%') THEN
			INSERT INTO non_salesrepresentatives (employeeNumber, deptCode) VALUES (NEW.employeeNumber, 401);
		ELSEIF (NEW.jobTitle LIKE '%Marketing%') THEN
			INSERT INTO non_salesrepresentatives (employeeNumber, deptCode) VALUES (NEW.employeeNumber, 402);
		END IF;
    END IF;
    
	INSERT INTO employees_audit VALUES (new.employeeNumber, now(), 'C', NULL, NULL, NULL, NULL, NULL, NULL,
																		new.lastName, new.firstName, new.extension, 
																		new.email, new.jobTitle, new.employee_type,
                                                                        new.end_username, new.end_userreason); 
END$$
DELIMITER ;



DROP TRIGGER IF EXISTS `dbsalesv2.5g211`.`employees_BEFORE_UPDATE`;

DELIMITER $$
USE `dbsalesv2.5g211`$$
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
    
    SELECT status INTO jobTitleStatus FROM job_titles_list WHERE jobTitle = NEW.jobTitle;
    IF (jobTitleStatus = 'D') THEN
		SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "ERROR: Job position already filled.";
    END IF;
    
    IF (is_JobAndType_consistent(NEW.employee_type, NEW.jobTitle) = FALSE) THEN
		SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "ERROR: Job title and employee type do not match.";
    END IF; 


    -- Check if the employee type is being changed
    IF (isStringChanged(OLD.employee_type, NEW.employee_type) = TRUE) THEN
        -- Update the end date of the current assignment for the sales representative
        UPDATE salesRepAssignments
        SET endDate = CURDATE(), reason = 'Assignment ended due to change in employee type by System'
        WHERE employeeNumber = OLD.employeeNumber AND endDate IS NULL;
    END IF;


    SET NEW.end_username = CURRENT_USER;
END$$
DELIMITER ;



DROP TRIGGER IF EXISTS `dbsalesv2.5g211`.`employees_AFTER_UPDATE`;

DELIMITER $$
USE `dbsalesv2.5g211`$$
CREATE TRIGGER `employees_AFTER_UPDATE` AFTER UPDATE ON `employees` FOR EACH ROW BEGIN
	DECLARE nonSalesRepCode INT;
    
	IF (old.employeeNumber <> new.employeeNumber) THEN 
		SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "employeeNumber cannot be modified";
	END IF;
    
	IF (isStringChanged(OLD.employee_type, NEW.employee_type) = TRUE) THEN
		IF (NEW.employee_type = 'S') THEN
			DELETE FROM non_salesrepresentatives WHERE employeeNumber = OLD.employeeNumber;
			INSERT INTO salesrepresentatives (employeeNumber) VALUES (OLD.employeeNumber);
		ELSE
			DELETE FROM salesrepresentatives WHERE employeeNumber = OLD.employeeNumber;
			IF (NEW.jobTitle LIKE '%Higher Ups%') THEN
				INSERT INTO non_salesrepresentatives (employeeNumber, deptCode) VALUES (OLD.employeeNumber, 403);
			ELSEIF (NEW.jobTitle LIKE '%Sales%') THEN
				INSERT INTO non_salesrepresentatives (employeeNumber, deptCode) VALUES (OLD.employeeNumber, 401);
			ELSEIF (NEW.jobTitle LIKE '%Marketing%') THEN
				INSERT INTO non_salesrepresentatives (employeeNumber, deptCode) VALUES (OLD.employeeNumber, 402);
			END IF;
		END IF;
	END IF;
	

	IF (isStringChanged(OLD.jobTitle, NEW.jobTitle) = TRUE) THEN
		SELECT deptCode INTO nonSalesRepCode FROM non_salesrepresentatives WHERE employeeNumber = OLD.employeeNumber;
        IF (NEW.jobTitle != 'Sales Rep') THEN
			UPDATE job_titles_list SET status = 'U' WHERE jobTitle = OLD.jobTitle;
			UPDATE job_titles_list SET status = 'D' WHERE jobTitle = NEW.jobTitle;
		END IF;
		IF (NEW.jobTitle LIKE '%Sales%' AND nonSalesRepCode != 401) THEN
			UPDATE non_salesrepresentatives SET deptCode = 401 WHERE employeeNumber = OLD.employeeNumber;
		ELSEIF (NEW.jobTitle LIKE '%Marketing%' AND nonSalesRepCode != 402) THEN
			UPDATE non_salesrepresentatives SET deptCode = 402 WHERE employeeNumber = OLD.employeeNumber;
		ELSEIF (NEW.jobTitle LIKE '%Higher Ups%'AND nonSalesRepCode != 403) THEN
			UPDATE non_salesrepresentatives SET deptCode = 403 WHERE employeeNumber = OLD.employeeNumber;
		END IF;
    END IF; 

	INSERT INTO employees_audit VALUES (old.employeeNumber, now(), 'U', old.lastName, old.firstName, old.extension, 
																		old.email, old.jobTitle, old.employee_type,
																		new.lastName, new.firstName, new.extension, 
																		new.email, new.jobTitle, new.employee_type,
                                                                        new.end_username, new.end_userreason);
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS `dbsalesV2.5G211`.`employees_BEFORE_DELETE`;

DELIMITER $$
USE `dbsalesV2.5G211`$$
CREATE TRIGGER `employees_BEFORE_DELETE` BEFORE DELETE ON `employees` FOR EACH ROW BEGIN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'ERROR: Employee Records cannot be deleted.'; 
END$$
DELIMITER ;




-- 4C.f START ----------------------------------------------------------------------------------------------------------------------------------------------------------
DROP TRIGGER IF EXISTS `dbsalesv2.5g211`.`salesRepAssignments_BEFORE_INSERT`;

DELIMITER $$
USE `dbsalesv2.5g211`$$
CREATE TRIGGER `salesRepAssignments_BEFORE_INSERT` BEFORE INSERT ON `salesrepassignments` FOR EACH ROW BEGIN
	DECLARE last_end_date DATE;
    SET new.startDate := now();

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

    -- Set assigned_by to 'System' and add a reason
    SET NEW.reason = 'New assignment provided before the current assignment expired by System';
END$$
DELIMITER ;
-- 4C.f END ----------------------------------------------------------------------------------------------------------------------------------------------------------

-- 4C.c START -----------------------------------------------------------------------------------------------------------------------------------------------
CREATE TABLE `dbsalesV2.5G211`.`resigned_employees` (
  `employeeNumber` INT NOT NULL,
  `end_username` VARCHAR(45) NULL,
  `end_userreason` VARCHAR(45) NULL,
  PRIMARY KEY (`employeeNumber`),
  CONSTRAINT `FK1001`
    FOREIGN KEY (`employeeNumber`)
    REFERENCES `dbsalesV2.5G211`.`employees` (`employeeNumber`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION);

USE `dbsalesV2.5G211`;
DROP procedure IF EXISTS `resign_employee`;

DELIMITER $$
USE `dbsalesV2.5G211`$$
CREATE PROCEDURE `resign_employee` (IN v_employeeNumber INT)
BEGIN
    INSERT INTO resigned_employees VALUES (v_employeeNumber, CURRENT_USER, "NEW Record");
END$$

DELIMITER ;
-- 4C.c END -----------------------------------------------------------------------------------------------------------------------------------------------



USE `dbsalesv2.5g211`;
DROP function IF EXISTS `is_JobAndType_consistent`;

DELIMITER $$
USE `dbsalesv2.5g211`$$
CREATE FUNCTION `is_JobAndType_consistent` (v_employee_type VARCHAR(1), v_jobTitle VARCHAR(50))
	RETURNS BOOLEAN
    NO SQL
    DETERMINISTIC
BEGIN
	IF (((v_employee_type = 'S') <> (v_jobTitle = 'Sales Rep')) OR
		(v_jobTitle LIKE '%Sales Manager%' AND v_employee_type != 'N') OR
        (v_jobTitle LIKE '%Inventory Manager%' AND v_employee_type != 'N')) THEN
		RETURN FALSE;
	ELSE 
		RETURN TRUE; 
    END IF;
END$$

DELIMITER ;
----------------------------------------------------------------------------

-- 4C.C

-- Part 4C letter d

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
    
    -- Assigns n to how many customers there are
	SELECT COUNT(employeeNumber) INTO n
    FROM salesRepAssignments;
    
	-- While statement to iterate through each customerNumber and update their creditLimit
	WHILE i < n DO 
		-- Gets each customerNumber in the table per iteration
		SELECT 		employeeNumber, endDate INTO currEmployeeNumber, endDate 
        FROM 		salesRepAssignments 
        ORDER BY 	employeeNumber ASC LIMIT 1 OFFSET i; 
        
        -- Updates endDate
        IF (endDate = NOW()) THEN
			UPDATE 		salesRepAssignments 
			SET 		endDate = DATE_ADD(NOW(), INTERVAL 1 WEEK)
			WHERE 		employeeNumber = currEmployeeNumber;
        END IF;
        
		-- Get previous quota 
        SELECT COALESCE(creditLimit, 0) INTO previousQuota
        FROM customers
        WHERE salesRepEmployeeNumber = currEmployeeNumber;
        
		-- Facilitated sales of previous assignment
        SELECT COALESCE (SUM(amountpaid), 0) INTO facilitatedSales
        FROM 		payment_orders po
        JOIN 		orders o ON po.orderNumber = o.orderNumber
        WHERE 		o.customerNumber IN (
            SELECT 	customerNumber
            FROM 	customers
            WHERE 	salesRepEmployeeNumber = currEmployeeNumber
        );
        
        -- Recomputed new quota
		SET newQuota = previousQuota - facilitatedSales;
        
         -- Update quota
        UPDATE customers
        SET creditLimit = newQuota
        WHERE salesRepEmployeeNumber = currEmployeeNumber;

        -- Sales manager recorded that facilitated the reassignment should be “System”
        UPDATE 		salesRepAssignments
        SET 		salesManagerNumber = salesManagerNumber
        WHERE 		employeeNumber = currEmployeeNumber;
		
        -- Iteration increment
        SET 		i = i + 1;
	END WHILE;
END$$
DELIMITER ;




