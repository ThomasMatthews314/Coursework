# Thomas Matthews and Cole Guerin
# ALY6030 Final Project

USE final;

### Creating the tables

CREATE TABLE dim_drug (
		drug_ndc		INT,
        drug_name		VARCHAR(100));
        
CREATE TABLE dim_member (
		member_id		INT,
        member_first_name		VARCHAR(100),
        member_last_name		VARCHAR(100),
        member_birth_date		TEXT,
        member_age		INT,
        member_gender		CHAR(1));

CREATE TABLE dim_drug_form (
		drug_form_code		CHAR(2),
        drug_form_desc		VARCHAR(100));

CREATE TABLE dim_drug_brand_generic (
		drug_brand_generic_code		INT,
        drug_brand_generic_desc		VARCHAR(10));

CREATE TABLE fact_prescription (
		member_id		INT,
        drug_ndc		INT,
        drug_form_code		CHAR(2),
        drug_brand_generic_code		INT,
        fill_date		TEXT,
        copay		INT,
        insurancepaid		INT);

SHOW VARIABLES LIKE 'local_infile';
SET GLOBAL local_infile = 'ON';
SHOW VARIABLES like 'secure_file_priv';

### Loading the data

LOAD DATA LOCAL INFILE '~/Desktop/ALY6030/dim_drug.csv' 
INTO TABLE dim_drug 
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(drug_ndc, drug_name);

LOAD DATA LOCAL INFILE '~/Desktop/ALY6030/dim_member.csv' 
INTO TABLE dim_member 
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(member_id, member_first_name, member_last_name, member_birth_date, member_age, member_gender);

LOAD DATA LOCAL INFILE '~/Desktop/ALY6030/dim_drug_form.csv' 
INTO TABLE dim_drug_form 
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(drug_form_code, drug_form_desc);

LOAD DATA LOCAL INFILE '~/Desktop/ALY6030/dim_drug_brand_generic.csv' 
INTO TABLE dim_drug_brand_generic
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(drug_brand_generic_code, drug_brand_generic_desc);

LOAD DATA LOCAL INFILE '~/Desktop/ALY6030/fact_prescription.csv' 
INTO TABLE fact_prescription
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(member_id, drug_ndc, drug_form_code, drug_brand_generic_code, fill_date, copay, insurancepaid);

### Fixing Dates

UPDATE dim_member
SET member_birth_date = REPLACE(member_birth_date, '46', '1946')
WHERE member_ID = 10001;

UPDATE dim_member
SET member_birth_date = REPLACE(member_birth_date, '62', '1962')
WHERE member_ID = 10002;

UPDATE dim_member
SET member_birth_date = REPLACE(member_birth_date, '82', '1982')
WHERE member_ID = 10003;

UPDATE dim_member
SET member_birth_date = REPLACE(member_birth_date, '83', '1983')
WHERE member_ID = 10004;

UPDATE dim_member SET member_birth_date = str_to_date(member_birth_date, "%m/%d/%Y");
UPDATE fact_prescription SET fill_date = str_to_date(fill_date, "%m/%d/%Y");

### Setting Primary and Foreign Keys

ALTER TABLE dim_drug
ADD PRIMARY KEY (drug_ndc);

ALTER TABLE dim_drug_brand_generic
ADD PRIMARY KEY (drug_brand_generic_code);

ALTER TABLE dim_drug_form
ADD PRIMARY KEY (drug_form_code);

ALTER TABLE dim_member
ADD PRIMARY KEY (member_id);

ALTER TABLE fact_prescription
ADD COLUMN prescription_id INT AUTO_INCREMENT PRIMARY KEY;

ALTER TABLE fact_prescription
ADD FOREIGN KEY prescription_drug_ndc_fk (drug_ndc)
REFERENCES dim_drug (drug_ndc)
ON UPDATE SET NULL
ON DELETE CASCADE;

ALTER TABLE fact_prescription
ADD FOREIGN KEY prescription_drug_brand_generic_code_fk (drug_brand_generic_code)
REFERENCES dim_drug_brand_generic (drug_brand_generic_code)
ON UPDATE SET NULL
ON DELETE CASCADE;

ALTER TABLE fact_prescription
ADD FOREIGN KEY prescription_drug_form_code_fk (drug_form_code)
REFERENCES dim_drug_form (drug_form_code)
ON UPDATE SET NULL
ON DELETE CASCADE;

ALTER TABLE fact_prescription
ADD FOREIGN KEY prescription_member_id_fk (member_id)
REFERENCES dim_member (member_id)
ON UPDATE SET NULL
ON DELETE CASCADE;

### Part 4: Analytics and Reporting

SELECT drug_name, COUNT(*) AS num_prescriptions
FROM fact_prescription
INNER JOIN dim_drug
USING (drug_ndc)
GROUP BY drug_name;

SELECT 
	CASE WHEN member_age >= 65 THEN '65+'
    WHEN member_age < 65 THEN '< 65' END AS age,
	COUNT(*) AS num_prescriptions,
	COUNT(DISTINCT member_id) AS num_members,
    SUM(copay) AS sum_copay,
    SUM(insurancepaid) AS sum_insurancepaid
FROM fact_prescription
INNER JOIN dim_member
USING (member_id)
GROUP BY age;

drop table if exists t1;
create table t1 as
SELECT member_id, member_first_name, member_last_name, drug_name, 
fill_date AS mr_fill_date,
insurancepaid AS mr_insurancepaid,
ROW_NUMBER() over (PARTITION BY member_id ORDER BY member_id, fill_date DESC) AS num
FROM fact_prescription
INNER JOIN dim_member
USING (member_id)
INNER JOIN dim_drug
USING (drug_ndc);

SELECT member_id, member_first_name, member_last_name, 
	drug_name, mr_fill_date, mr_insurancepaid
FROM t1 WHERE num = 1 ORDER BY mr_fill_date DESC;

DROP TABLE t1;