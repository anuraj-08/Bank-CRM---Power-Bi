use bank_crm;

-- 1. What is the distribution of account balances across different regions?

SELECT
    g.geoCategory AS Region,
    COUNT(*) AS Total_Accounts,
    ROUND(SUM(b.Balance), 2) AS Total_Balance
FROM bank_churn b
JOIN customerinfo c 
    ON b.CustomerID = c.CustomerID 
JOIN geographytype g 
    ON c.GeographyID = g.geoID
GROUP BY g.geoCategory;

-- 2. Identify the top 5 customers with the highest Estimated Salary in the last quarter of the year.

WITH quarter_year_rank AS (
    SELECT
        CustomerID,
        Surname,
        EstimatedSalary,
        QUARTER(Bank_DOJ_new) AS Quarter,
        YEAR(Bank_DOJ_new) AS Year,
        DENSE_RANK() OVER (
            PARTITION BY QUARTER(Bank_DOJ_new), YEAR(Bank_DOJ_new)
            ORDER BY EstimatedSalary DESC
        ) AS 'Rank'
    FROM customerinfo
)
SELECT *
FROM quarter_year_rank
WHERE `Rank` BETWEEN 1 AND 5
  AND Quarter = 4;

-- 3. Calculate the average number of products used by customers who have a credit card.

SELECT 
    ROUND(AVG(NumOfProducts)) AS Avg_Products_By_CreditCard_Users
FROM bank_churn
WHERE HasCrCard = 1;


-- 4. Determine the churn rate by gender for the most recent year in the dataset.

SELECT
    g.GenderCategory AS Gender,
    COUNT(CASE WHEN b.Exited = 1 THEN 1 END) AS Churned_Customers,
    COUNT(*) AS Total_Customers,
    ROUND(
        COUNT(CASE WHEN b.Exited = 1 THEN 1 END) / COUNT(*) * 100,
        2
    ) AS Churn_Rate_Percentage
FROM customerinfo c
JOIN bank_churn b 
    ON c.CustomerID = b.CustomerID
JOIN gendertype g 
    ON c.GenderID = g.GenderID
GROUP BY g.GenderCategory;

-- 5. Compare the average credit score of customers who have exited and those who remain.

SELECT
    e.ExitCategory,
    ROUND(AVG(b.CreditScore), 2) AS Avg_Credit_Score
FROM bank_churn b
JOIN exittype e 
    ON b.Exited = e.ExitID
GROUP BY e.ExitCategory;


-- 6. Which gender has a higher average estimated salary, and how does it relate to the number of active accounts?

SELECT
    g.GenderCategory AS Gender,
    ROUND(AVG(EstimatedSalary), 2) AS Avg_Estimated_Salary,
    COUNT(CASE WHEN b.IsActiveMember = 1 THEN 1 END) AS Active_Accounts
FROM bank_churn b
NATURAL JOIN customerinfo c
JOIN gendertype g 
    ON c.GenderID = g.GenderID
GROUP BY g.GenderCategory;

-- 7. Segment the customers based on their credit score and identify the segment with the highest exit rate.

WITH cust_with_cate AS (
    SELECT 
        CustomerId,
        CreditScore,
        CASE
            WHEN CreditScore BETWEEN 800 AND 850 THEN 'Excellent'
            WHEN CreditScore BETWEEN 740 AND 799 THEN 'Very Good'
            WHEN CreditScore BETWEEN 670 AND 739 THEN 'Good'
            WHEN CreditScore BETWEEN 580 AND 669 THEN 'Fair'
            WHEN CreditScore BETWEEN 300 AND 579 THEN 'Poor'
            ELSE 'Unknown'
        END AS CreditCategory
    FROM bank_churn
)

SELECT 
    c.CreditCategory,
    ROUND(100 * COUNT(CASE WHEN b.Exited = 1 THEN 1 END) / COUNT(*), 2) AS Exit_Rate,
    ROUND(100 * COUNT(CASE WHEN b.Exited = 0 THEN 1 END) / COUNT(*), 2) AS Retain_Rate,
    DENSE_RANK() OVER (
        ORDER BY COUNT(CASE WHEN b.Exited = 1 THEN 1 END) / COUNT(*) DESC
    ) AS 'Rank'
FROM bank_churn b
JOIN cust_with_cate c 
    ON b.CustomerId = c.CustomerId
GROUP BY c.CreditCategory;

-- 8. Find out which geographic region has the highest number of active customers with a tenure greater than 5 years.

SELECT
    g.geoCategory AS Region,
    COUNT(c.CustomerID) AS Active_Customers
FROM customerinfo c
NATURAL JOIN bank_churn b
JOIN geographytype g
    ON c.GeographyID = g.geoID
WHERE b.Tenure > 5
  AND b.IsActiveMember = 1
GROUP BY g.geoCategory;

-- 9. What is the impact of having a credit card on customer churn?

SELECT
    h.CardCategory,
    COUNT(CASE WHEN b.Exited = 1 THEN 1 END) AS Churned_Customers,
    COUNT(*) AS Total_Customers,
    ROUND(
        COUNT(CASE WHEN b.Exited = 1 THEN 1 END) / COUNT(*) * 100,
        2
    ) AS Churn_Rate_Percentage
FROM customerinfo c
JOIN bank_churn b 
    ON c.CustomerID = b.CustomerID
JOIN creditcardtype h 
    ON b.HasCrCard = h.CardID
GROUP BY h.CardCategory;

-- 10. For customers who have exited, what is the most common number of products they have used?

SELECT
    NumOfProducts,
    COUNT(*) AS Count
FROM bank_churn
WHERE Exited = 1
GROUP BY NumOfProducts;

-- 11. Examine the trend of customers joining over time and identify seasonal patternsuse bank_crm
SELECT
    DATE_FORMAT(Bank_DOJ_new, '%M') AS Month,
    YEAR(Bank_DOJ_new) AS Year,
    COUNT(DISTINCT CustomerID) AS Joining_Count
FROM customerinfo
GROUP BY 
    DATE_FORMAT(Bank_DOJ_new, '%M'),
    MONTH(Bank_DOJ_new),
    YEAR(Bank_DOJ_new)
ORDER BY 
    Year,
    MONTH(Bank_DOJ_new);

-- 11. Examine the trend of customers joining over time and identify seasonal patterns
SELECT
    DATE_FORMAT(Bank_DOJ_new, '%M') AS Month,
    YEAR(Bank_DOJ_new) AS Year,
    COUNT(DISTINCT CustomerID) AS Joining_Count
FROM customerinfo
GROUP BY 
    DATE_FORMAT(Bank_DOJ_new, '%M'),
    MONTH(Bank_DOJ_new),
    YEAR(Bank_DOJ_new)
ORDER BY 
    Year,
    MONTH(Bank_DOJ_new);

-- 12. Analyze the relationship between the number of products and the account balance for customers who have exited.
SELECT
    CASE 
        WHEN Balance < 50000 THEN '0 - 49,999' 
        WHEN Balance BETWEEN 50000 AND 100000 THEN '50,000 - 100,000'
        WHEN Balance BETWEEN 100000 AND 150000 THEN '100,000 - 150,000'
        WHEN Balance BETWEEN 150000 AND 200000 THEN '150,000 - 200,000'
        ELSE '> 200,000'
    END AS Balance_Range,
    NumOfProducts,
    COUNT(CustomerID) AS Customer_Count
FROM bank_churn
WHERE Exited = 1
GROUP BY Balance_Range, NumOfProducts
ORDER BY Balance_Range, NumOfProducts;

-- 13. Identify any potential outliers in terms of balance among customers who have remained with the bank. 
select 
	balance, 
    exited, 
    customerid 
from bank_churn
where exited = 1 ;

-- 15. Gender-wise average income in each geography and ranking by income
SELECT
    g.geoCategory AS Country,
    gn.GenderCategory AS Gender,
    ROUND(AVG(c.EstimatedSalary)) AS Avg_Income,
    RANK() OVER(
        PARTITION BY g.geoCategory
        ORDER BY AVG(c.EstimatedSalary) DESC
    ) AS 'Rank'
FROM customerinfo c
JOIN geographytype g 
    ON c.GeographyID = g.GeoID
JOIN gendertype gn 
    ON c.GenderID = gn.GenderID
GROUP BY 
    g.geoCategory,
    gn.GenderCategory;


-- 16. Average tenure of exited customers by age bracket
WITH age_bracket_cte AS (
    SELECT
        CASE
            WHEN age BETWEEN 18 AND 30 THEN '18-30'
            WHEN age BETWEEN 31 AND 50 THEN '31-50'
            WHEN age > 50 THEN '50+'
        END AS age_bracket,
        customerid
    FROM customerinfo
)
SELECT
    age_bracket,
    ROUND(AVG(Tenure), 1) AS avg_tenure
FROM age_bracket_cte ac
JOIN bank_churn b
    ON ac.customerid = b.customerid
WHERE b.exited = 1
GROUP BY age_bracket;

-- 17. Salary vs Balance comparison for exited vs retained customers
-- For Exited Customers
SELECT 
    b.Balance,
    c.EstimatedSalary
FROM bank_churn b
JOIN customerinfo c 
    ON b.CustomerID = c.CustomerID
WHERE b.Exited = 1;

-- For Retained Customers
SELECT 
    b.Balance,
    c.EstimatedSalary
FROM bank_churn b
JOIN customerinfo c 
    ON b.CustomerID = c.CustomerID
WHERE b.Exited = 0;

-- 18. Check correlation between Estimated Salary and Credit Score
SELECT
    b.CustomerID,
    c.EstimatedSalary AS Salary,
    b.CreditScore
FROM customerinfo c
JOIN bank_churn b 
    ON c.CustomerID = b.CustomerID;

-- 19. Rank credit score buckets based on churn count

WITH cust_with_cate AS (
    SELECT 
        CASE
            WHEN CreditScore BETWEEN 800 AND 850 THEN 'Excellent'
            WHEN CreditScore BETWEEN 740 AND 799 THEN 'Very Good'
            WHEN CreditScore BETWEEN 670 AND 739 THEN 'Good'
            WHEN CreditScore BETWEEN 580 AND 669 THEN 'Fair'
            WHEN CreditScore BETWEEN 300 AND 579 THEN 'Poor'
            ELSE 'Unknown'
        END AS CreditCategory,
        Exited
    FROM bank_churn
)

SELECT  
    CreditCategory,
    COUNT(CASE WHEN Exited = 1 THEN 1 END) AS Churned_Count,
    COUNT(*) AS Total_Customers,
    ROUND(COUNT(CASE WHEN Exited = 1 THEN 1 END) / COUNT(*) * 100, 2) AS Churn_Rate,
    RANK() OVER (ORDER BY COUNT(CASE WHEN Exited = 1 THEN 1 END) DESC) AS 'Rank'
FROM cust_with_cate
GROUP BY CreditCategory;

-- 20.	According to the age buckets find the number of customers who have a credit card. Also retrieve those buckets that have lesser than average number of credit cards per bucket.

-- Step 1: Count customers with credit cards in each age bracket
WITH Age_Card_Count AS (
    SELECT
        CASE
            WHEN c.Age BETWEEN 18 AND 30 THEN '18-30'
            WHEN c.Age BETWEEN 31 AND 50 THEN '31-50'
            WHEN c.Age > 50 THEN '50+'
        END AS Age_Bracket,
        COUNT(*) AS Customer_Count_With_CC
    FROM bank_churn b
    JOIN customerinfo c 
        ON b.CustomerID = c.CustomerID
    WHERE b.HasCrCard = 1
    GROUP BY Age_Bracket
)

SELECT * 
FROM Age_Card_Count;

SELECT * 
FROM Age_Card_Count
WHERE Customer_Count_With_CC < (SELECT AVG(Customer_Count_With_CC) FROM Age_Card_Count);

-- 21. Rank the locations based on churned customers and average balance

SELECT
    geoCategory AS Location,
    COUNT(CASE WHEN exited = 1 THEN 1 END) AS Churned_Customers,
    RANK() OVER (ORDER BY COUNT(CASE WHEN exited = 1 THEN 1 END) DESC) AS Rank_By_Churn,
    ROUND(AVG(balance), 2) AS Avg_Balance,
    RANK() OVER (ORDER BY AVG(balance) DESC) AS Rank_By_Avg_Balance
FROM bank_churn b
JOIN customerinfo c 
    ON b.customerid = c.customerid
JOIN geographytype g 
    ON c.geographyid = g.geoid
GROUP BY geoCategory;

-- 22.	As we can see that the “CustomerInfo” table has the CustomerID and Surname, now if we have to join it with a table where the primary key is also a combination of CustomerID and Surname, come up with a column where the format is “CustomerID_Surname”.
SELECT 
    CONCAT(CustomerID, "_", Surname) AS combo_id
FROM customerinfo;


-- 23.	Without using “Join”, can we get the “ExitCategory” from ExitCustomers table to Bank_Churn table? If yes do this using SQL.
select 
	*, 
    (select exitcategory from exittype where exitid = o.exited) exit_category 
from bank_churn o ;

-- 24.	Were there any missing values in the data, using which tool did you replace them and what are the ways to handle them?
-- Checking for missing (NULL) values in 'customerinfo' table
SELECT 
    COUNT(CASE WHEN CustomerId IS NULL THEN 1 END) AS CustomerId_null,
    COUNT(CASE WHEN Surname IS NULL THEN 1 END) AS Surname_null,
    COUNT(CASE WHEN Age IS NULL THEN 1 END) AS Age_null,
    COUNT(CASE WHEN GenderID IS NULL THEN 1 END) AS GenderID_null,
    COUNT(CASE WHEN GeographyID IS NULL THEN 1 END) AS GeographyID_null,
    COUNT(CASE WHEN EstimatedSalary IS NULL THEN 1 END) AS EstimatedSalary_null,
    COUNT(CASE WHEN Bank_DOJ_new IS NULL THEN 1 END) AS Bank_DOJ_new_null
FROM 
    customerinfo;

-- Checking for missing (NULL) values in 'bank_churn' table
SELECT 
    COUNT(CASE WHEN CustomerId IS NULL THEN 1 END) AS CustomerId_null,
    COUNT(CASE WHEN CreditScore IS NULL THEN 1 END) AS CreditScore_null,
    COUNT(CASE WHEN Tenure IS NULL THEN 1 END) AS Tenure_null,
    COUNT(CASE WHEN Balance IS NULL THEN 1 END) AS Balance_null,
    COUNT(CASE WHEN NumOfProducts IS NULL THEN 1 END) AS NumOfProducts_null,
    COUNT(CASE WHEN HasCrCard IS NULL THEN 1 END) AS HasCrCard_null,
    COUNT(CASE WHEN IsActiveMember IS NULL THEN 1 END) AS IsActiveMember_null,
    COUNT(CASE WHEN Exited IS NULL THEN 1 END) AS Exited_null
FROM 
    bank_churn;

-- 25.	Write the query to get the customer IDs, their last name, and whether they are active or not for the customers whose surname ends with “on”.
SELECT 
    c.CustomerId,
    c.Surname,
    a.activeCategory AS Active_Status
FROM customerinfo c
JOIN bank_churn b 
    ON c.CustomerId = b.CustomerId
JOIN activecusttype a 
    ON b.IsActiveMember = a.activeID
WHERE c.Surname LIKE '%on';

--

SELECT DISTINCT IsActiveMember, Exited
FROM bank_churn;

SELECT COUNT(*)
FROM bank_churn
WHERE IsActiveMember = 1 AND Exited = 1;



-- --------------------------------- SUBJECTIVE QUESTIONS ------------------------------------------------------------

-- 1. Customer Behavior Analysis: Compare spending habits of long-term vs new customers

WITH cust_type AS (
    SELECT
        b.CustomerId,
        b.Balance,
        b.NumOfProducts,
        b.CreditScore,
        b.IsActiveMember,
        b.Exited,
        c.Bank_DOJ_new,
        c.age,
        CASE
            WHEN c.Bank_DOJ_new > DATE_SUB((SELECT MAX(Bank_DOJ_new) FROM customerinfo), INTERVAL 1 YEAR)
                THEN 'New'
            ELSE 'Old'
        END AS customer_type
    FROM bank_churn b
    JOIN customerinfo c 
        ON b.CustomerId = c.CustomerId
)

SELECT
    customer_type,
    COUNT(*) AS total_customers,
    ROUND(AVG(CASE WHEN Balance != 0 THEN Balance END), 2) AS avg_balance,
    ROUND(AVG(NumOfProducts), 0) AS avg_num_of_products,
    ROUND(AVG(CreditScore), 2) AS avg_credit_score,
    ROUND(100 * COUNT(CASE WHEN IsActiveMember = 1 THEN 1 END) / COUNT(*), 2) AS active_percentage,
    ROUND(100 * COUNT(CASE WHEN Exited = 1 THEN 1 END) / COUNT(*), 2) AS churn_rate,
    COUNT(CASE WHEN Balance = 0 THEN 1 END) AS count_with_no_balance,
    ROUND(100 * COUNT(CASE WHEN Balance = 0 THEN 1 END) / COUNT(*), 2) AS pct_with_no_balance,
    ROUND(AVG(age), 2) AS avg_age
FROM cust_type
GROUP BY customer_type;


-- 2.	Product Affinity Study: Which bank products or services are most commonly used together, and how might this influence cross-selling strategies?
WITH ProductUsage AS (
    SELECT
        CustomerID,
        NumOfProducts,
        CASE
            WHEN NumOfProducts >= 4 THEN 'SavingsAccount, CreditCard, Loan, InvestmentAccount'
            WHEN NumOfProducts = 3 THEN 'SavingsAccount, CreditCard, Loan'
            WHEN NumOfProducts = 2 THEN 'SavingsAccount, CreditCard'
            WHEN NumOfProducts = 1 THEN 'SavingsAccount'
        END AS ProductCombination
    FROM bank_churn
),
CombinationAnalysis AS (
    SELECT
        ProductCombination,
        COUNT(CustomerID) AS CustomerCount
    FROM ProductUsage
    GROUP BY ProductCombination
)
SELECT
    CustomerCount,
    ProductCombination,
    ROUND(CustomerCount * 100.0 / (SELECT COUNT(*) FROM bank_churn), 2) AS PercentageOfCustomers
FROM CombinationAnalysis;


-- 3.Geographic Market Trends: How do economic indicators in different geographic regions correlate with the number of active accounts and customer churn rates?

WITH cte AS (
    SELECT 
        b.CustomerId,
        b.CreditScore,
        CASE
            WHEN b.CreditScore BETWEEN 800 AND 850 THEN 'Excellent'
            WHEN b.CreditScore BETWEEN 740 AND 799 THEN 'Very Good'
            WHEN b.CreditScore BETWEEN 670 AND 739 THEN 'Good'
            WHEN b.CreditScore BETWEEN 580 AND 669 THEN 'Fair'
            WHEN b.CreditScore BETWEEN 300 AND 579 THEN 'Poor'
            ELSE 'Unknown'
        END AS CreditCategory,
        g.geoCategory AS region,
        b.Exited,
        b.IsActiveMember
    FROM bank_churn b
    JOIN customerinfo c 
        ON b.CustomerId = c.CustomerId
    JOIN geographytype g 
        ON c.GeographyID = g.geoID
)

SELECT
    region,
    CreditCategory,
    ROUND(100 * COUNT(CASE WHEN IsActiveMember = 1 THEN 1 END) / COUNT(*), 2) AS active_percentage,
    ROUND(100 * COUNT(CASE WHEN Exited = 1 THEN 1 END) / COUNT(*), 2) AS churn_rate
FROM cte
GROUP BY region, CreditCategory
ORDER BY region, CreditCategory;


-- 4.	Risk Management Assessment: Based on customer profiles, which demographic segments appear to pose the highest financial risk to the bank, and why?
-- STEP 1: Create a view to simplify customer category analysis
CREATE VIEW cust_category AS 
SELECT
    b.CustomerId,
    b.Balance,
    b.IsActiveMember,
    b.Exited,
    age,
    genderID,
    geographyID
FROM bank_churn b
JOIN customerinfo c 
    ON b.CustomerId = c.CustomerId;

-- STEP 2: Gender-wise Risk Analysis
SELECT
    g.genderCategory AS Gender,
    COUNT(*) AS total_customer,
    ROUND(100 * COUNT(CASE WHEN IsActiveMember = 0 THEN 1 END) / COUNT(*), 2) AS inactive_percentage,
    ROUND(100 * COUNT(CASE WHEN Exited = 1 THEN 1 END) / COUNT(*), 2) AS churn_rate,
    COUNT(CASE WHEN Balance = 0 THEN 1 END) AS cust_count_with_no_investment,
    ROUND(100 * COUNT(CASE WHEN Balance = 0 THEN 1 END) / COUNT(*), 2) AS per_of_cust_with_no_investment
FROM cust_category c 
JOIN gendertype g 
    ON c.genderID = g.genderID
GROUP BY g.genderCategory;

-- Age-wise Customer Risk Analysis
SELECT
    CASE
        WHEN age BETWEEN 18 AND 30 THEN '18-30'
        WHEN age BETWEEN 31 AND 50 THEN '31-50'
        WHEN age > 50 THEN '50+'
        ELSE 'Unknown'
    END AS age_group,
    COUNT(*) AS total_customer,
    ROUND(100 * COUNT(CASE WHEN IsActiveMember = 0 THEN 1 END) / COUNT(*), 2) AS inactive_percentage,
    ROUND(100 * COUNT(CASE WHEN Exited = 1 THEN 1 END) / COUNT(*), 2) AS churn_rate,
    COUNT(CASE WHEN Balance = 0 THEN 1 END) AS cust_count_with_no_investment,
    ROUND(100 * COUNT(CASE WHEN Balance = 0 THEN 1 END) / COUNT(*), 2) AS per_of_cust_with_no_investment
FROM cust_category
GROUP BY age_group;

-- 5.	Customer Tenure Value Forecast: How would you use the available data to model and predict the lifetime (tenure) value in the bank of different customer segments?

SELECT
    customerinfo.CustomerID,
    Age,
    EstimatedSalary,
    CreditScore,
    Tenure,
    Balance,
    NumOfProducts,
    cardCategory AS CreditCardCategory,
    ActiveCategory,
    ExitCategory,
    TIMESTAMPDIFF(YEAR, customerinfo.Bank_DOJ_new, CURDATE()) AS CurrentTenureYears
FROM customerinfo
JOIN geographytype g
    ON customerinfo.GeographyID = g.GeoID
JOIN bank_churn 
    ON customerinfo.CustomerID = bank_churn.CustomerID
LEFT JOIN creditcardtype c
    ON bank_churn.hascrcard = c.cardID
LEFT JOIN activecusttype A
    ON bank_churn.isActivemember= A.ActiveID
LEFT JOIN exittype e
    ON bank_churn.Exited = e.ExitID;


-- 7.	Customer Exit Reasons Exploration: Can you identify common characteristics or trends among customers who have exited that could explain their reasons for leaving?

-- A) Tenure vs Churn
WITH cte AS (
    SELECT
        b.CustomerId,
        b.tenure,
        b.Exited
    FROM bank_churn b
    JOIN customerinfo c 
        ON b.CustomerId = c.CustomerId
)
SELECT
    tenure,
    COUNT(*) AS total_customers,
    COUNT(CASE WHEN Exited = 1 THEN 1 END) AS exited_customers,
    ROUND(100.0 * COUNT(CASE WHEN Exited = 1 THEN 1 END) / COUNT(*), 2) AS churn_rate_percent
FROM cte
GROUP BY tenure
ORDER BY churn_rate_percent DESC, tenure;

-- B) Number of Products vs Churn
WITH cte AS (
    SELECT
        b.CustomerId,
        b.NumOfProducts,
        b.Exited
    FROM bank_churn b
    JOIN customerinfo c 
        ON b.CustomerId = c.CustomerId
)
SELECT
    NumOfProducts,
    COUNT(*) AS total_customers,
    COUNT(CASE WHEN Exited = 1 THEN 1 END) AS exited_customers,
    ROUND(100.0 * COUNT(CASE WHEN Exited = 1 THEN 1 END) / COUNT(*),2) AS churn_rate_percent
FROM cte
GROUP BY NumOfProducts
ORDER BY churn_rate_percent DESC;

-- C) Credit Card Ownership vs Churn
WITH cte AS (
    SELECT
        b.CustomerId,
        b.HasCrCard,
        b.Exited
    FROM bank_churn b
    JOIN customerinfo c 
        ON b.CustomerId = c.CustomerId
)
SELECT
    HasCrCard,
    COUNT(*) AS total_customers,
    COUNT(CASE WHEN Exited = 1 THEN 1 END) AS exited_customers,
    ROUND(100.0 * COUNT(CASE WHEN Exited = 1 THEN 1 END) / COUNT(*),2) AS churn_rate_percent
FROM cte
GROUP BY HasCrCard
ORDER BY churn_rate_percent DESC;

-- D) Credit Score Group vs Churn
WITH cte AS (
    SELECT
        b.CustomerId,
        b.CreditScore,
        b.Exited
    FROM bank_churn b
    JOIN customerinfo c 
        ON b.CustomerId = c.CustomerId
),
score_grouped AS (
    SELECT
        CASE
            WHEN CreditScore < 580 THEN 'Poor (<580)'
            WHEN CreditScore BETWEEN 580 AND 669 THEN 'Fair (580-669)'
            WHEN CreditScore BETWEEN 670 AND 739 THEN 'Good (670-739)'
            WHEN CreditScore BETWEEN 740 AND 799 THEN 'Very Good (740-799)'
            WHEN CreditScore >= 800 THEN 'Excellent (800+)'
        END AS credit_score_group,
        Exited
    FROM cte
)
SELECT
    credit_score_group,
    COUNT(*) AS total_customers,
    COUNT(CASE WHEN Exited = 1 THEN 1 END) AS exited_customers,
    ROUND(100.0 * COUNT(CASE WHEN Exited = 1 THEN 1 END) / COUNT(*),2) AS churn_rate_percent
FROM score_grouped
GROUP BY credit_score_group
ORDER BY churn_rate_percent DESC;


-- 
SELECT
    b.CustomerId,
    c.Age,
    CASE 
        WHEN c.Age <=25 THEN 'Young'
        WHEN c.Age BETWEEN 26 AND 35 THEN 'Adult'
        WHEN c.Age BETWEEN 36 AND 50 THEN 'Middle Age'
        WHEN c.Age > 50 THEN 'Senior'
    END AS age_group,

    b.tenure,
    CASE
        WHEN b.tenure < 3 THEN 'New'
        WHEN b.tenure BETWEEN 3 AND 5 THEN 'Frequent'
        WHEN b.tenure >= 6 THEN 'Loyal'
    END AS tenure_group,

    CASE 
        WHEN b.HasCrCard = 1 THEN 'Has Credit Card'
        ELSE 'No Credit Card'
    END AS credit_card_status,

    CASE 
        WHEN b.CreditScore < 580 THEN 'Poor'
        WHEN b.CreditScore BETWEEN 580 AND 669 THEN 'Fair'
        WHEN b.CreditScore BETWEEN 670 AND 739 THEN 'Good'
        WHEN b.CreditScore BETWEEN 740 AND 799 THEN 'Very Good'
        WHEN b.CreditScore >= 800 THEN 'Excellent'
    END AS credit_score_group

FROM bank_churn b
JOIN customerinfo c 
    ON b.CustomerId = c.CustomerId;


-- 11.	What is the current churn rate per year and overall as well in the bank? Can you suggest some insights to the bank about which kind of customers are more likely to churn and what different strategies can be used to decrease the churn rate?

-- Yearly + Overall churn rate
WITH exit_data AS (
    SELECT
        b.CustomerId,
        YEAR(Bank_DOJ_new) + Tenure AS Exit_Year,
        b.Exited
    FROM bank_churn b
    JOIN customerinfo c
        ON b.CustomerId = c.CustomerId
)
-- Year-wise
SELECT
    Exit_Year ,
    COUNT(CASE WHEN Exited = 1 THEN 1 END) * 100.0 / COUNT(*) AS Churn_Rate_Percentage,
    COUNT(CASE WHEN Exited = 1 THEN 1 END) AS Churned_Customers,
    COUNT(*) AS Total_Customers
FROM exit_data
GROUP BY Exit_Year

UNION ALL

-- Overall
SELECT
    'Overall' AS Year,
    COUNT(CASE WHEN Exited = 1 THEN 1 END) * 100.0 / COUNT(*) AS Churn_Rate_Percentage,
    COUNT(CASE WHEN Exited = 1 THEN 1 END) AS Churned_Customers,
    COUNT(*) AS Total_Customers
FROM exit_data
ORDER BY
    CASE WHEN Exit_Year = 'Overall' THEN 1 ELSE 0 END,
    Exit_Year;


-- to check what is the year where churn started
select
  b.customerid,
year(Bank_DOJ_new) as exit_year,
tenure
from bank_churn b 
join customerinfo c
on b.customerid = c.customerid
where exited = 1 
order by exit_year desc,tenure;

-- 14.	In the “Bank_Churn” table how can you modify the name of the “HasCrCard” column to “Has_creditcard”?

ALTER TABLE bank_churn
RENAME COLUMN  HasCrCard TO Has_creditcard;

select * from bank_churn;