----------------------------------------------------------
-- IBM HR Analytics Employee Attrition & Performance
----------------------------------------------------------


-- Create Dabase
CREATE DATABASE IBM_hr_analytics;

-- Drop existing tables if they exist
DROP TABLE IF EXISTS hr_raw;
DROP TABLE IF EXISTS employees;
DROP TABLE IF EXISTS employment_details;
DROP TABLE IF EXISTS performance;
DROP TABLE IF EXISTS attrition_status;


-- Create table to store raw HR dataset with comprehensive employee details before normalization
CREATE TABLE hr_raw (
    age INT,
    attrition BOOLEAN,
    business_travel TEXT,
    daily_rate INT,
    department TEXT,
    distance_from_home INT,
    education INT,
    education_field TEXT,
    employee_count INT,
    employee_number INT,
    environment_satisfaction INT,
    gender TEXT,
    hourly_rate INT,
    job_involvement INT,
    job_level INT,
    job_role TEXT,
    job_satisfaction INT,
    marital_status TEXT,
    monthly_income NUMERIC,
    monthly_rate INT,
    num_companies_worked INT,
    over18 TEXT,
    overtime BOOLEAN,
    percent_salary_hike INT,
    performance_rating INT,
    relationship_satisfaction INT,
    standard_hours INT,
    stock_option_level INT,
    total_working_years INT,
    training_times_last_year INT,
    work_life_balance INT,
    years_at_company INT,
    years_in_current_role INT,
    years_since_last_promotion INT,
    years_with_curr_manager INT
);


-- Create employees table
CREATE TABLE employees (
	employee_id SERIAL PRIMARY KEY,
	employee_number INT UNIQUE NOT NULL,
	age INT NOT NULL,
	gender TEXT,
	education INT,
	education_field TEXT
);


-- Create employment_details table
CREATE TABLE employment_details (
	employee_id INT NOT NULL REFERENCES employees(employee_id),
	department TEXT,
	job_role TEXT,
	job_level INT,
	business_travel TEXT,
    monthly_income NUMERIC,
    percent_salary_hike INT,
    years_at_company INT,
    years_since_last_promotion INT,
    years_with_curr_manager INT,
    distance_from_home INT
);


-- Create performance table
CREATE TABLE performance (
    employee_id INT NOT NULL REFERENCES employees(employee_id),
    performance_rating INT,
    job_satisfaction INT,
    environment_satisfaction INT,
    work_life_balance INT,
    training_times_last_year INT,
    overtime BOOLEAN
);


-- Create attrition_status table
CREATE TABLE attrition_status (
    employee_id INT NOT NULL REFERENCES employees(employee_id),
    attrition BOOLEAN,
    stock_option_level INT,
    num_companies_worked INT,
    total_working_years INT
);


-- Insert data into employees table
INSERT INTO employees (employee_number, age, gender, education, education_field)
SELECT DISTINCT
    employee_number,
    age,
    gender,
    education,
    education_field
FROM hr_raw;


-- Insert data into employment details table
INSERT INTO employment_details (
    employee_id,
    department,
    job_role,
    job_level,
    business_travel,
    monthly_income,
    percent_salary_hike,
    years_at_company,
    years_since_last_promotion,
    years_with_curr_manager,
    distance_from_home
)
SELECT
    e.employee_id,
    r.department,
    r.job_role,
    r.job_level,
    r.business_travel,
    r.monthly_income,
    r.percent_salary_hike,
    r.years_at_company,
    r.years_since_last_promotion,
    r.years_with_curr_manager,
    r.distance_from_home
FROM hr_raw r
JOIN employees e ON r.employee_number = e.employee_number;


-- Insert data into performance table
INSERT INTO performance (
    employee_id,
    performance_rating,
    job_satisfaction,
    environment_satisfaction,
    work_life_balance,
    training_times_last_year,
    overtime
)
SELECT
    e.employee_id,
    r.performance_rating,
    r.job_satisfaction,
    r.environment_satisfaction,
    r.work_life_balance,
    r.training_times_last_year,
    r.overtime
FROM hr_raw r
JOIN employees e ON r.employee_number = e.employee_number;


-- Insert data into attrition status table
INSERT INTO attrition_status (
    employee_id,
    attrition,
    stock_option_level,
    num_companies_worked,
    total_working_years
)
SELECT
    e.employee_id,
    r.attrition,
    r.stock_option_level,
    r.num_companies_worked,
    r.total_working_years
FROM hr_raw r
JOIN employees e ON r.employee_number = e.employee_number;


----------------------------------------------------------------------------
-- Data Cleaning
----------------------------------------------------------------------------

-- Check for nulls in each table
SELECT COUNT(*) FROM hr_raw WHERE education IS NULL;
SELECT COUNT(*) FROM employees WHERE gender IS NULL;


-- Check for duplicates
SELECT employee_number, COUNT(*) 
FROM employees 
GROUP BY employee_number 
HAVING COUNT(*) > 1;


-------------------------------------------------------------------------------
-- Exploratory Analysis
-------------------------------------------------------------------------------

-- Average Monthly Income by Job Level
SELECT 
  job_level,
  ROUND(AVG(monthly_income), 2) AS avg_income
FROM employment_details
GROUP BY job_level
ORDER BY job_level;


-- Attrition Rate by Department
SELECT 
  ed.department,
  ROUND(100.0 * SUM(CASE WHEN a.attrition THEN 1 ELSE 0 END) / COUNT(*), 1) AS attrition_rate_percent
FROM employment_details ed
JOIN attrition_status a ON ed.employee_id = a.employee_id
GROUP BY ed.department
ORDER BY attrition_rate_percent DESC;


-- Years at company vs Attrition Rate
SELECT
  ed.years_at_company,
  COUNT(*) AS total_employees,
  SUM(CASE WHEN a.attrition THEN 1 ELSE 0 END) AS attrited
FROM employment_details ed
JOIN attrition_status a ON ed.employee_id = a.employee_id
GROUP BY ed.years_at_company
ORDER BY ed.years_at_company;


-- Attrition Rate by overtime
SELECT 
  p.overtime,
  ROUND(100.0 * SUM(CASE WHEN a.attrition THEN 1 ELSE 0 END) / COUNT(*), 1) AS attrition_rate
FROM performance p
JOIN attrition_status a ON p.employee_id = a.employee_id
GROUP BY p.overtime;


-- Attrition Rate by gender
SELECT 
  e.gender,
  ROUND(100.0 * SUM(CASE WHEN a.attrition THEN 1 ELSE 0 END) / COUNT(*), 1) AS attrition_rate
FROM employees e
JOIN attrition_status a ON e.employee_id = a.employee_id
GROUP BY e.gender;


--  Attrition by Job Role and Satisfaction
SELECT 
  ed.job_role,
  p.job_satisfaction,
  COUNT(*) AS total_employees,
  SUM(CASE WHEN a.attrition THEN 1 ELSE 0 END) AS attrited
FROM employment_details ed
JOIN performance p ON ed.employee_id = p.employee_id
JOIN attrition_status a ON ed.employee_id = a.employee_id
GROUP BY ed.job_role, p.job_satisfaction
ORDER BY ed.job_role, p.job_satisfaction;


-- Distribution of Attrition Across Age Groups
SELECT 
  CASE 
    WHEN age < 30 THEN 'Under 30'
    WHEN age BETWEEN 30 AND 40 THEN '30-40'
    WHEN age BETWEEN 41 AND 50 THEN '41-50'
    ELSE '51+' 
  END AS age_group,
  ROUND(100.0 * SUM(CASE WHEN a.attrition THEN 1 ELSE 0 END) / COUNT(*), 1) AS attrition_rate
FROM employees e
JOIN attrition_status a ON e.employee_id = a.employee_id
GROUP BY age_group
ORDER BY age_group;


--  Work-Life Balance vs Attrition Rate
SELECT 
  p.work_life_balance,
  ROUND(100.0 * SUM(CASE WHEN a.attrition THEN 1 ELSE 0 END) / COUNT(*), 1) AS attrition_rate
FROM performance p
JOIN attrition_status a ON p.employee_id = a.employee_id
GROUP BY p.work_life_balance
ORDER BY p.work_life_balance;


-- Top 5 Roles With Highest Attrition Rate
SELECT 
  ed.job_role,
  ROUND(100.0 * SUM(CASE WHEN a.attrition THEN 1 ELSE 0 END) / COUNT(*), 1) AS attrition_rate,
  COUNT(*) AS total_employees
FROM employment_details ed
JOIN attrition_status a ON ed.employee_id = a.employee_id
GROUP BY ed.job_role
ORDER BY attrition_rate DESC
LIMIT 5;


-- Correlation Between Salary Hike and Attrition
SELECT 
  ed.percent_salary_hike,
  ROUND(100.0 * SUM(CASE WHEN a.attrition THEN 1 ELSE 0 END) / COUNT(*), 1) AS attrition_rate
FROM employment_details ed
JOIN attrition_status a ON ed.employee_id = a.employee_id
GROUP BY ed.percent_salary_hike
ORDER BY ed.percent_salary_hike;




---------------------------------------------------------------------------------------
-- End of IBM HR Analytics Employee Attrition & Performance
---------------------------------------------------------------------------------------