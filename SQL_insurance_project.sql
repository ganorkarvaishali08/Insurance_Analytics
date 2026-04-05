CREATE DATABASE Insurance_Analysis;
USE Insurance_Analysis;
CREATE TABLE brokarage (
client_name VARCHAR(255),
policy_number VARCHAR(100),
policy_status VARCHAR(50),
policy_start_date VARCHAR(50),
policy_end_date VARCHAR(50),
product_group VARCHAR(100),
Account_Exe_ID INT,
Account_Executive VARCHAR(255),
Branch VARCHAR(100),
solution_group VARCHAR(255),
income_class VARCHAR(100),
Amount DECIMAL(15,2),
income_due_date VARCHAR(50),
revenue_transaction_type VARCHAR(100),
renewal_status VARCHAR(50),
lapse_reason VARCHAR(255),
last_updated_date VARCHAR(50)
);
CREATE TABLE fees (
client_name VARCHAR(255),
Branch VARCHAR(100),
solution_group VARCHAR(255),
Account_Exe_ID INT,
Account_Executive VARCHAR(255),
income_class VARCHAR(100),
Amount DECIMAL(15,2),
income_due_date VARCHAR(50),
revenue_transaction_type VARCHAR(100)
);
CREATE TABLE opportunity (
opportunity_name VARCHAR(255),
opportunity_id VARCHAR(100),
Account_Exe_Id INT,
Account_Executive VARCHAR(255),
premium_amount DECIMAL(15,2),
revenue_amount DECIMAL(15,2),
closing_date VARCHAR(50),
stage VARCHAR(100),
Branch VARCHAR(100),
specialty VARCHAR(100),
product_group VARCHAR(100),
product_sub_group VARCHAR(100),
risk_details TEXT
);
CREATE TABLE meeting_list (
Account_Exe_ID INT,
Account_Executive VARCHAR(255),
Branch VARCHAR(100),
global_attendees VARCHAR(255),
meeting_date VARCHAR(50),
meeting_count INT
);
CREATE TABLE invoice (
invoice_number BIGINT,
invoice_date VARCHAR(50),
revenue_transaction_type VARCHAR(100),
Branch VARCHAR(100),
solution_group VARCHAR(255),
Account_Exe_ID INT,
Account_Executive VARCHAR(255),
income_class VARCHAR(100),
Client_Name VARCHAR(255),
policy_number VARCHAR(100),
Amount DECIMAL(15,2),
income_due_date VARCHAR(50)
);
CREATE TABLE budget (
Branch VARCHAR(100),
Account_Exe_ID INT,
Account_Executive VARCHAR(255),
New_Role2 VARCHAR(100),
New_Budget DECIMAL(15,2),
Cross_sell_bugdet DECIMAL(15,2),
Renewal_Budget DECIMAL(15,2)
);

-- Use the database you already created
USE insurance_analysis;

-- 1. Create table for 'Customer information.csv'
CREATE TABLE individual_detail (
    customer_id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(255),
    gender VARCHAR(20),
    age INT,
    occupation VARCHAR(255),
    marital_status VARCHAR(50),
    address_full TEXT
);

-- 2. Create table for 'policy detail.csv'
CREATE TABLE policy_detail (
    policy_id VARCHAR(50) PRIMARY KEY,
    policy_type VARCHAR(100),
    coverage_amount DECIMAL(15, 2),
    premium_amount DECIMAL(15, 2),
    policy_start_date VARCHAR(20), -- Text format to handle DD-MM-YYYY
    policy_end_date VARCHAR(20),
    payment_frequency VARCHAR(50),
    status VARCHAR(50),
    customer_id VARCHAR(50),
    FOREIGN KEY (customer_id) REFERENCES individual_detail(customer_id)
);

-- 3. Create table for 'Claims.csv'
CREATE TABLE claims (
    claim_id VARCHAR(50) PRIMARY KEY,
    date_of_claim VARCHAR(20),
    claim_amount DECIMAL(15, 2),
    claim_status VARCHAR(50),
    reason_for_claim TEXT,
    settlement_date VARCHAR(20),
    policy_id VARCHAR(50),
    FOREIGN KEY (policy_id) REFERENCES policy_detail(policy_id)
);

-- 4. Create table for 'Payment history.csv'
CREATE TABLE payment_history (
    payment_id VARCHAR(50) PRIMARY KEY,
    date_of_payment VARCHAR(20),
    amount_paid DECIMAL(15, 2),
    payment_method VARCHAR(50),
    payment_status VARCHAR(50),
    policy_id VARCHAR(50),
    FOREIGN KEY (policy_id) REFERENCES policy_detail(policy_id)
);

-- 5. Create table for 'Additional files.csv' (Agent & Risk data)
CREATE TABLE  additional_policy_info (
    agent_id VARCHAR(50),
    renewal_status VARCHAR(50),
    policy_discounts INT,
    risk_score INT,
    policy_id VARCHAR(50),
    FOREIGN KEY (policy_id) REFERENCES policy_detail(policy_id)
);
SHOW TABLES;

-- KPI 1: No of Invoice by Account Exec
SELECT Account_Executive, COUNT(invoice_number) AS No_of_Invoices
FROM invoice
GROUP BY Account_Executive
ORDER BY No_of_Invoices DESC;

-- KPI 2: Yearly Meeting Count
SELECT SUM(meeting_count) AS Total_Yearly_Meetings
FROM meeting_list;

-- KPI 3: Target vs Achieve (Combined Results)
SELECT
'Cross_Sell' AS Category,
SUM(Cross_sell_bugdet) AS Target,
(SELECT SUM(Amount) FROM brokarage WHERE income_class = 'Cross_Sell') +
(SELECT SUM(Amount) FROM fees WHERE income_class = 'Cross_Sell') AS Achieve
FROM budget
UNION
SELECT
'New' AS Category,
SUM(New_Budget) AS Target,
(SELECT SUM(Amount) FROM brokarage WHERE income_class = 'New') +
(SELECT SUM(Amount) FROM fees WHERE income_class = 'New') AS Achieve
FROM budget
UNION
SELECT
'Renewal' AS Category,
SUM(Renewal_Budget) AS Target,
(SELECT SUM(Amount) FROM brokarage WHERE income_class = 'Renewal') +
(SELECT SUM(Amount) FROM fees WHERE income_class = 'Renewal') AS Achieve
FROM budget;

-- KPI 4: Stage Funnel by Revenue
SELECT stage, SUM(revenue_amount) AS Total_Revenue
FROM opportunity
GROUP BY stage
ORDER BY Total_Revenue DESC;

-- KPI 5: No of meeting By Account Exe
SELECT Account_Executive, SUM(meeting_count) AS Total_Meetings
FROM meeting_list
GROUP BY Account_Executive
ORDER BY Total_Meetings DESC;

-- KPI 6: Top Open Opportunity
SELECT opportunity_name, Account_Executive, revenue_amount
FROM opportunity
WHERE stage NOT LIKE '%Closed%'
ORDER BY revenue_amount DESC
LIMIT 5;

-- KPI 7: Total Policy Count
SELECT COUNT(policy_number) AS Total_Policies FROM brokarage;

-- KPI 8: Total Customer Count
SELECT COUNT(DISTINCT client_name) AS Total_Customers FROM brokarage;

-- KPI 9: Open Opportunity by Revenue (Top 4)
-- Matches your "Oppty by Revenue - Top 4" chart
SELECT opportunity_name, SUM(revenue_amount) AS Revenue
FROM opportunity
WHERE stage = 'Open' OR stage = 'Qualify_Oppty'
GROUP BY opportunity_name
ORDER BY Revenue DESC
LIMIT 4;

-- KPI 10: Opportunity Product Distribution
-- Matches your "Oppty-Product distribution" donut chart
SELECT product_group, COUNT(*) AS Opportunity_Count
FROM opportunity
GROUP BY product_group
ORDER BY Opportunity_Count DESC;

-- KPI 11: New vs Renewal Invoice Achievement %
-- Calculates the "Invoice Achvmnt %" metrics for your dashboard
-- INCLUDES CROSS SELL)
SELECT 'Cross Sell' AS Category,
(COUNT(CASE WHEN income_class = 'Cross Sell' THEN invoice_number END) * 100.0 / NULLIF((SELECT COUNT(*) FROM brokarage WHERE income_class = 'Cross Sell'), 0)) AS Invoice_Achv_Pct FROM invoice
UNION ALL
SELECT 'New',
(COUNT(CASE WHEN income_class = 'New' THEN invoice_number END) * 100.0 / NULLIF((SELECT COUNT(*) FROM brokarage WHERE income_class = 'New'), 0)) FROM invoice
UNION ALL
SELECT 'Renewal',
(COUNT(CASE WHEN income_class = 'Renewal' THEN invoice_number END) * 100.0 / NULLIF((SELECT COUNT(*) FROM brokarage WHERE income_class = 'Renewal'), 0)) FROM invoice;


