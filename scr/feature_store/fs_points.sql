-- Create a Common Table Expression (CTE) named tb_points to calculate points for each customer
WITH tb_points AS (
        
    -- Select the necessary columns from the transactions table
    SELECT 
        idCustomer,

        -- Calculate the total accumulated points
        sum(CASE WHEN pointsTransaction > 0 THEN pointsTransaction ELSE 0 END) AS acumulatedPoints,

        -- Calculate the accumulated points in the last 7 days
        sum(CASE
                WHEN pointsTransaction > 0 
                AND dtTransaction >= DATE('{date}', '-7 DAYS') 
                    THEN pointsTransaction
                ELSE 0
            END) AS acumulatedPointsD7,
        -- Calculate the accumulated points in the last 14 days
        sum(CASE
                WHEN pointsTransaction > 0 
                AND dtTransaction >= DATE('{date}', '-14 DAYS') 
                    THEN pointsTransaction
                ELSE 0
            END) AS acumulatedPointsD14,
        -- Calculate the accumulated points in the last 21 days
        sum(CASE
                WHEN pointsTransaction > 0 
                AND dtTransaction >= DATE('{date}', '-21 DAYS') 
                    THEN pointsTransaction
                ELSE 0
            END) AS acumulatedPointsD21,

        -- Calculate the total redeemed points
        sum(CASE WHEN pointsTransaction < 0 THEN pointsTransaction ELSE 0 END) AS redeemedPoints,

        -- Calculate the redeemed points in the last 7 days
        sum(CASE
                WHEN pointsTransaction < 0 
                AND dtTransaction >= DATE('{date}', '-7 DAYS')
                    THEN pointsTransaction
                ELSE 0
            END) AS redeemedPointsD7,
        -- Calculate the redeemed points in the last 14 days
        sum(CASE
                WHEN pointsTransaction < 0 
                AND dtTransaction >= DATE('{date}', '-14 DAYS')
                    THEN pointsTransaction
                ELSE 0
            END) AS redeemedPointsD14,
        -- Calculate the redeemed points in the last 21 days
        sum(CASE
                WHEN pointsTransaction < 0 
                AND dtTransaction >= DATE('{date}', '-21 DAYS')
                    THEN pointsTransaction
                ELSE 0
            END) AS redeemedPointsD21

    FROM transactions

    -- Only consider transactions before the given date and within the last 21 days
    WHERE dtTransaction < '{date}'
    AND dtTransaction >= DATE('{date}', '-21 days')

    -- Group the results by customer ID
    GROUP BY idCustomer

),

-- Create another CTE named tb_life to calculate the customer's life metrics
tb_life AS (
    -- Select the necessary columns from the previously created tb_points CTE and transactions table
    SELECT
        t1.idCustomer,
        -- Calculate the customer's life in days by subtracting the most recent transaction date from the given date
        CAST(max(julianday('{date}') - julianday(dtTransaction)) AS INTEGER) + 1 AS lifeDays,
        -- Calculate the customer's total points balance
        sum(t2.pointsTransaction) AS pointsBalance,
        -- Calculate the total accumulated points in the customer's lifetime
        sum(CASE
                WHEN t2.pointsTransaction > 0
                    THEN t2.pointsTransaction
                ELSE 0
            END) AS lifePointsAcumulated,
        -- Calculate the total redeemed points in the customer's lifetime
        sum(CASE
                WHEN t2.pointsTransaction < 0
                    THEN t2.pointsTransaction
                ELSE 0
            END) AS lifePointsRedeemed

    FROM tb_points AS t1

    -- Join the tb_points CTE with the transactions table on customer ID
    LEFT JOIN transactions AS t2
    ON t1.idCustomer = t2.idCustomer

    -- Only consider transactions before the given date
    WHERE t2.dtTransaction < '{date}'

    -- Group the results by customer ID
    GROUP BY t1.idCustomer

)

-- Select the final result set
SELECT 
    -- Include all columns from the tb_points CTE
    t1.*,
    -- Include the points balance from the tb_life CTE
    t2.pointsBalance,
    -- Include the lifetime accumulated points from the tb_life CTE
    t2.lifePointsAcumulated,
    -- Include the lifetime redeemed points from the tb_life CTE
    t2.lifePointsRedeemed,
    -- Calculate the points per day in the customer's lifetime
    1.0 * t2.lifePointsAcumulated / t2.lifeDays AS pointsPerDay

FROM tb_points AS t1

-- Join the tb_points CTE with the tb_life CTE on customer ID
LEFT JOIN tb_life AS t2
ON t1.idCustomer = t2.idCustomer