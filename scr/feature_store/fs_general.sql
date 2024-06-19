WITH tb_rfv AS (
    
    SELECT

        idCustomer,
        
        CAST(julianday('now') - max(julianday(dtTransaction)) AS INTEGER) + 1 AS recencyDays,
        
        COUNT(DISTINCT DATE(dtTransaction)) AS frequencyDays,
        
        sum(CASE 
                WHEN pointsTransaction > 0 THEN pointsTransaction 
            END) AS valuePoints

    FROM transactions

    WHERE dtTransaction < '2024-06-18'
    AND dtTransaction >= DATE('2024-06-18', '-21 days')

    GROUP BY idCustomer

),

tb_age AS (

    SELECT 
        t1.idCustomer,

        CAST(julianday('now') - min(julianday(t2.dtTransaction)) AS INTEGER) + 1 AS baseAgeDays

    FROM tb_rfv AS t1

    LEFT JOIN transactions AS t2
    ON t1.idCustomer = t2.idCustomer

    GROUP BY t2.idCustomer
)

SELECT t1.*,
    t2.baseAgeDays,
    t3.flEmail

FROM tb_rfv AS t1

LEFT JOIN tb_age AS t2
ON t1.idCustomer = t2.idCustomer

LEFT JOIN customers AS t3
ON t1.idCustomer = t3.idCustomer