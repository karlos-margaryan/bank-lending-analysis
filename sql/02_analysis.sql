-- Loan data analysis (BankDB, SQL Server)
-- 3,000 synthetic loans, Jan 2025 - Oct 2026

USE BankDB;
GO

-- Q1: Lending overview (number of loans, total amount, weighted average rate)
SELECT COUNT(*)                                 AS LoansCount,
       SUM(Amount)                              AS TotalAmount,
       SUM(Amount * InterestRate) / SUM(Amount) AS WeightedAvgRate
FROM fact_loans;

-- Q2: Loans by type
SELECT LoanType,
       COUNT(*)    AS LoansCount,
       SUM(Amount) AS TotalAmount
FROM fact_loans
GROUP BY LoanType
ORDER BY TotalAmount DESC;

-- Q3: Loans by region
SELECT dim_branches.Region,
       COUNT(*)               AS LoansCount,
       SUM(fact_loans.Amount) AS TotalAmount
FROM fact_loans
JOIN dim_branches ON fact_loans.BranchID = dim_branches.BranchID
GROUP BY dim_branches.Region
ORDER BY TotalAmount DESC;

-- Q4: Loans by status
SELECT Status,
       COUNT(*)    AS LoansCount,
       SUM(Amount) AS TotalAmount
FROM fact_loans
GROUP BY Status
ORDER BY TotalAmount DESC;

-- Q5: Overdue rate by region (overdue amount, % of loans issued)
SELECT dim_branches.Region,
       SUM(fact_loans.Amount) AS TotalAmount,
       SUM(CASE WHEN fact_loans.Status = 'Overdue' THEN fact_loans.Amount ELSE 0 END) AS OverdueAmount,
       SUM(CASE WHEN fact_loans.Status = 'Overdue' THEN fact_loans.Amount ELSE 0 END) * 100.0
           / SUM(fact_loans.Amount) AS OverduePct
FROM fact_loans
JOIN dim_branches ON fact_loans.BranchID = dim_branches.BranchID
GROUP BY dim_branches.Region
ORDER BY OverduePct DESC;

-- Q6: Monthly trend
SELECT FORMAT(LoanDate, 'yyyy-MM') AS YearMonth,
       COUNT(*)    AS LoansCount,
       SUM(Amount) AS TotalAmount
FROM fact_loans
GROUP BY FORMAT(LoanDate, 'yyyy-MM')
ORDER BY YearMonth;

-- Q7: Top 3 branches by amount
SELECT TOP 3 dim_branches.BranchName,
       SUM(fact_loans.Amount) AS TotalAmount
FROM fact_loans
JOIN dim_branches ON fact_loans.BranchID = dim_branches.BranchID
GROUP BY dim_branches.BranchName
ORDER BY TotalAmount DESC;

-- Q8: Overdue rate by age group (overdue amount, % of loans issued)
SELECT dim_customers.AgeGroup,
       SUM(fact_loans.Amount) AS TotalAmount,
       SUM(CASE WHEN fact_loans.Status = 'Overdue' THEN fact_loans.Amount ELSE 0 END) AS OverdueAmount,
       SUM(CASE WHEN fact_loans.Status = 'Overdue' THEN fact_loans.Amount ELSE 0 END) * 100.0
           / SUM(fact_loans.Amount) AS OverduePct
FROM fact_loans
JOIN dim_customers ON fact_loans.CustomerID = dim_customers.CustomerID
GROUP BY dim_customers.AgeGroup
ORDER BY OverduePct DESC;