-- =====================================================================
-- 01_create_tables.sql
-- Creates the BankDB tables and fills them with SYNTHETIC data:
-- 8 branches, 500 customers, 3,000 loans (Jan 2025 - Oct 2026).
-- Values are generated with MD5 hashes, so every run gives the same data.
-- =====================================================================

USE BankDB;
GO

-- 0. Drop old tables (if they exist)
DROP TABLE IF EXISTS fact_loans;
DROP TABLE IF EXISTS dim_customers;
DROP TABLE IF EXISTS dim_branches;

-- 1. Branches
CREATE TABLE dim_branches (
    BranchID   INT PRIMARY KEY,
    BranchName NVARCHAR(50),
    Region     NVARCHAR(50),
    Manager    NVARCHAR(50)
);

INSERT INTO dim_branches VALUES
(1, 'Yerevan Center',  'Yerevan', 'Aram Petrosyan'),
(2, 'Yerevan Arabkir', 'Yerevan', 'Ani Grigoryan'),
(3, 'Yerevan Malatia', 'Yerevan', 'Tigran Avetisyan'),
(4, 'Gyumri',          'Shirak',  'Lilit Hakobyan'),
(5, 'Vanadzor',        'Lori',    'Davit Sargsyan'),
(6, 'Armavir',         'Armavir', 'Narek Hovhannisyan'),
(7, 'Ejmiatsin',       'Armavir', 'Mariam Karapetyan'),
(8, 'Kapan',           'Syunik',  'Gor Mkrtchyan');

-- 2. Customers (500)
CREATE TABLE dim_customers (
    CustomerID INT PRIMARY KEY,
    Gender     NVARCHAR(10),
    AgeGroup   NVARCHAR(10),
    Segment    NVARCHAR(20)
);

WITH n AS (
    SELECT TOP (500) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS i
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT INTO dim_customers
SELECT n.i,
       CASE WHEN ABS(h.h1 % 2) = 0 THEN 'Male' ELSE 'Female' END,
       CASE ABS(h.h2 % 4) WHEN 0 THEN '18-25' WHEN 1 THEN '26-35'
                          WHEN 2 THEN '36-50' ELSE '51+' END,
       CASE WHEN ABS(h.h3 % 5) = 0 THEN 'Business' ELSE 'Individual' END
FROM n
CROSS APPLY (SELECT
    CAST(HASHBYTES('MD5', CONCAT(n.i, 'g')) AS INT) AS h1,
    CAST(HASHBYTES('MD5', CONCAT(n.i, 'a')) AS INT) AS h2,
    CAST(HASHBYTES('MD5', CONCAT(n.i, 's')) AS INT) AS h3
) h;

-- 3. Loans (3,000)
CREATE TABLE fact_loans (
    LoanID       INT PRIMARY KEY,
    CustomerID   INT,
    BranchID     INT,
    LoanType     NVARCHAR(20),
    Amount       BIGINT,
    InterestRate DECIMAL(5,2),
    LoanDate     DATE,
    Status       NVARCHAR(20)
);

WITH n AS (
    SELECT TOP (3000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS i
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT INTO fact_loans
SELECT n.i,
       ABS(h.h1 % 500) + 1,
       ABS(h.h2 % 8) + 1,
       CASE WHEN t.t < 3 THEN 'Mortgage' WHEN t.t < 7 THEN 'Consumer'
            WHEN t.t < 9 THEN 'Business' ELSE 'Car' END,
       CASE WHEN t.t < 3 THEN 10000000 + ABS(h.h4 % 30000) * 1000
            WHEN t.t < 7 THEN   300000 + ABS(h.h4 % 2700)  * 1000
            WHEN t.t < 9 THEN  2000000 + ABS(h.h4 % 18000) * 1000
            ELSE               3000000 + ABS(h.h4 % 9000)  * 1000 END,
       CASE WHEN t.t < 3 THEN 10.00 WHEN t.t < 7 THEN 16.00
            WHEN t.t < 9 THEN 12.00 ELSE 13.00 END + ABS(h.h5 % 400) / 100.0,
       DATEADD(DAY, ABS(h.h6 % 669), '2025-01-01'),
       CASE WHEN ABS(h.h7 % 100) < 75 THEN 'Active'
            WHEN ABS(h.h7 % 100) < 92 THEN 'Closed' ELSE 'Overdue' END
FROM n
CROSS APPLY (SELECT
    CAST(HASHBYTES('MD5', CONCAT(n.i, 'c')) AS INT) AS h1,
    CAST(HASHBYTES('MD5', CONCAT(n.i, 'b')) AS INT) AS h2,
    CAST(HASHBYTES('MD5', CONCAT(n.i, 't')) AS INT) AS h3,
    CAST(HASHBYTES('MD5', CONCAT(n.i, 'm')) AS INT) AS h4,
    CAST(HASHBYTES('MD5', CONCAT(n.i, 'r')) AS INT) AS h5,
    CAST(HASHBYTES('MD5', CONCAT(n.i, 'd')) AS INT) AS h6,
    CAST(HASHBYTES('MD5', CONCAT(n.i, 'x')) AS INT) AS h7
) h
CROSS APPLY (SELECT ABS(h.h3 % 10) AS t) t;

-- Check row counts
SELECT 'branches' AS TableName, COUNT(*) AS Rows FROM dim_branches
UNION ALL SELECT 'customers', COUNT(*) FROM dim_customers
UNION ALL SELECT 'loans',     COUNT(*) FROM fact_loans;