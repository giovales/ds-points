-- Create a Common Table Expression (CTE) named tb_rfv to calculate recency, frequency, and value (points) for each viewer
WITH tb_rfv AS (
    
    -- Select the necessary columns from the transactions table
    SELECT
        idCustomer,
        
        -- Calculate the recency in days by subtracting the most recent transaction date from today's date
        CAST(julianday('now') - max(julianday(dtTransaction)) AS INTEGER) + 1 AS recencyDays,
        
        -- Count the distinct transaction dates to determine the frequency of transactions
        COUNT(DISTINCT DATE(dtTransaction)) AS frequencyDays,
        
        -- Sum the points from transactions where points were earned to calculate the value
        sum(CASE 
                WHEN pointsTransaction > 0 THEN pointsTransaction 
            END) AS valuePoints

    FROM transactions

    -- Only consider transactions before the given date and within the last 21 days
    WHERE dtTransaction < {date}
    AND dtTransaction >= DATE({date}, '-21 days')

    -- Group the results by viewer ID
    GROUP BY idCustomer

),

-- Create another CTE named tb_age to calculate how many days the viewer has been in the database (named age)
tb_age AS (

    -- Select the necessary columns from the previously created tb_rfv CTE and transactions table
    SELECT 
        t1.idCustomer,

        -- Calculate the age in days by subtracting the first transaction date from today's date
        CAST(julianday('now') - min(julianday(t2.dtTransaction)) AS INTEGER) + 1 AS baseAgeDays

    FROM tb_rfv AS t1

    -- Join the tb_rfv CTE with the transactions table on viewer ID
    LEFT JOIN transactions AS t2
    ON t1.idCustomer = t2.idCustomer

    -- Group the results by viewer ID
    GROUP BY t2.idCustomer
)

-- Select the final result set
SELECT 
    -- Add the reference date to the result set
    {date} AS dtRef,
    -- Include all columns from the tb_rfv CTE
    t1.*,
    -- Include the base age in days from the tb_age CTE
    t2.baseAgeDays,
    -- Include the email flag from the customers table
    t3.flEmail

FROM tb_rfv AS t1

-- Join the tb_rfv CTE with the tb_age CTE on viewer ID
LEFT JOIN tb_age AS t2
ON t1.idCustomer = t2.idCustomer

-- Join the tb_rfv CTE with the customers table on viewer ID
LEFT JOIN customers AS t3
ON t1.idCustomer = t3.idCustomer