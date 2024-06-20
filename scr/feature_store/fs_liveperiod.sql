-- Define a CTE named tb_hour to extract the hour of each transaction and relevant transaction details
WITH tb_hour AS (

    SELECT
        idCustomer,
        pointsTransaction,
        CAST(STRFTIME('%H', DATETIME(dtTransaction)) AS INTEGER) AS hour

    FROM transactions

    -- Only consider transactions before the given date and within the last 21 days
    WHERE dtTransaction < '{date}'
    AND dtTransaction >= DATE('{date}', '-21 days')

),

-- Define a CTE named tb_share to calculate the metrics for transactions and points by different time periods of the day
tb_share AS (

    SELECT 
        idCustomer,

         -- Calculate the sum of points for different time periods of the day
        SUM(CASE WHEN hour >= 8 AND hour < 12 THEN ABS(pointsTransaction) ELSE 0 END) AS morningPoints,
        SUM(CASE WHEN hour >= 12 AND hour < 18 THEN ABS(pointsTransaction) ELSE 0 END) AS afternoonPoints,
        SUM(CASE WHEN hour >= 18 AND hour < 23 THEN ABS(pointsTransaction) ELSE 0 END) AS nightPoints,

        -- Calculate the percentage of points for different time periods of the day
        1.0 * SUM(CASE WHEN hour >= 8 AND hour < 12 THEN ABS(pointsTransaction) ELSE 0 END) / SUM(ABS(pointsTransaction)) AS morningPointsPct,
        1.0 * SUM(CASE WHEN hour >= 12 AND hour < 18 THEN ABS(pointsTransaction) ELSE 0 END) / SUM(ABS(pointsTransaction)) AS afternoonPointsPct,
        1.0 * SUM(CASE WHEN hour >= 18 AND hour < 23 THEN ABS(pointsTransaction) ELSE 0 END) / SUM(ABS(pointsTransaction)) AS nightPointsPct,

        -- Calculate the number of transactions for different time periods of the day
        SUM(CASE WHEN hour >= 8 AND hour < 12 THEN 1 ELSE 0 END) AS morningTransactionsQtd,
        SUM(CASE WHEN hour >= 12 AND hour < 18 THEN 1 ELSE 0 END) AS afternoonTransactionsQtd,
        SUM(CASE WHEN hour >= 18 AND hour < 23 THEN 1 ELSE 0 END) AS nightTransactionsQtd,

        -- Calculate the percentage of transactions for different time periods of the day
        1.0 * SUM(CASE WHEN hour >= 8 AND hour < 12 THEN 1 ELSE 0 END) / SUM(1) AS morningTransactionsPct,
        1.0 * SUM(CASE WHEN hour >= 12 AND hour < 18 THEN 1 ELSE 0 END) / SUM(1) AS afternoonTransactionsPct,
        1.0 * SUM(CASE WHEN hour >= 18 AND hour < 23 THEN 1 ELSE 0 END) / SUM(1) AS nightTransactionsPct

    FROM tb_hour

    GROUP BY idCustomer

)

-- Select the final results
SELECT 
    '{date}' as dtRef,
    *

FROM tb_share