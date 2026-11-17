-- 1. Churn rate by contract type
SELECT Contract,
       COUNT(*) AS customers,
       ROUND(100.0 * SUM(ChurnFlag) / COUNT(*), 1) AS churn_pct
FROM customers
GROUP BY Contract
ORDER BY churn_pct DESC;

-- 2. Churn rate by tenure bucket
SELECT CASE WHEN tenure <= 12 THEN '0-12 mo'
            WHEN tenure <= 24 THEN '13-24 mo'
            WHEN tenure <= 48 THEN '25-48 mo'
            ELSE '49-72 mo' END AS tenure_bucket,
       COUNT(*) AS customers,
       ROUND(100.0 * SUM(ChurnFlag) / COUNT(*), 1) AS churn_pct
FROM customers
GROUP BY tenure_bucket
ORDER BY MIN(tenure);

-- 3. Monthly revenue lost by segment, ranked (CTE + window function)
WITH segment AS (
    SELECT Contract,
           InternetService,
           COUNT(*) AS customers,
           SUM(CASE WHEN ChurnFlag = 1 THEN 1 ELSE 0 END) AS churned,
           ROUND(SUM(CASE WHEN ChurnFlag = 1 THEN MonthlyCharges ELSE 0 END), 0) AS revenue_lost
    FROM customers
    GROUP BY Contract, InternetService
)
SELECT *,
       RANK() OVER (ORDER BY revenue_lost DESC) AS loss_rank
FROM segment
ORDER BY loss_rank;

-- 4. High-risk segment: new, month-to-month, fiber customers
SELECT COUNT(*) AS customers,
       ROUND(100.0 * AVG(ChurnFlag), 1) AS churn_pct,
       ROUND(SUM(MonthlyCharges), 0) AS monthly_revenue
FROM customers
WHERE Contract = 'Month-to-month'
  AND InternetService = 'Fiber optic'
  AND tenure <= 12;