-- Define a CTE named tb_product_transactions to aggregate transaction details with product information
WITH tb_product_transactions AS (

    SELECT
        t1.*,  
        t2.NameProduct,  
        t2.QuantityProduct 

    FROM transactions AS t1

    LEFT JOIN transactions_product AS t2
    ON t1.idTransaction = t2.idTransaction

    WHERE dtTransaction < '{date}'  
    AND dtTransaction >= DATE('{date}', '-21 days')

),

-- Define a CTE named tb_share to calculate metrics per customer
tb_share AS (

    SELECT 
        idCustomer,

        -- Calculate the number of each product type purchased
        SUM(CASE WHEN NameProduct = 'ChatMessage' THEN QuantityProduct ELSE 0 END) AS numb_ChatMessage,
        SUM(CASE WHEN NameProduct = 'Lista de presença' THEN QuantityProduct ELSE 0 END) AS numb_PresenceList,
        SUM(CASE WHEN NameProduct = 'Troca de Pontos StreamElements' THEN QuantityProduct ELSE 0 END) AS numb_StreamElementsPointsChange,
        SUM(CASE WHEN NameProduct = 'Resgatar Ponei' THEN QuantityProduct ELSE 0 END) AS numb_RedeemedPoneis,
        SUM(CASE WHEN NameProduct = 'Presença Streak' THEN QuantityProduct ELSE 0 END) AS numb_StreakPresence,
        SUM(CASE WHEN NameProduct = 'Airflow Lover' THEN QuantityProduct ELSE 0 END) AS numb_AirflowLover,
        SUM(CASE WHEN NameProduct = 'R Lover' THEN QuantityProduct ELSE 0 END ) AS numb_RLover,

        -- Calculate the points for each product type
        SUM(CASE WHEN NameProduct = 'ChatMessage' THEN pointsTransaction ELSE 0 END) AS points_ChatMessage,
        SUM(CASE WHEN NameProduct = 'Lista de presença' THEN pointsTransaction ELSE 0 END) AS points_PresenceList,
        SUM(CASE WHEN NameProduct = 'Troca de Pontos StreamElements' THEN pointsTransaction ELSE 0 END) AS points_StreamElementsPointsChange,
        SUM(CASE WHEN NameProduct = 'Resgatar Ponei' THEN pointsTransaction ELSE 0 END) AS points_RedeemedPoneis,
        SUM(CASE WHEN NameProduct = 'Presença Streak' THEN pointsTransaction ELSE 0 END) AS points_StreakPresence,
        SUM(CASE WHEN NameProduct = 'Airflow Lover' THEN pointsTransaction ELSE 0 END) AS points_AirflowLover,
        SUM(CASE WHEN NameProduct = 'R Lover' THEN pointsTransaction ELSE 0 END ) AS points_RLover,

        -- Calculate the percentage of each product type purchased
        1.0 * SUM(CASE WHEN NameProduct = 'ChatMessage' THEN QuantityProduct ELSE 0 END) / SUM(QuantityProduct) AS pct_ChatMessage,
        1.0 * SUM(CASE WHEN NameProduct = 'Lista de presença' THEN QuantityProduct ELSE 0 END) / SUM(QuantityProduct) AS pct_PresenceList,
        1.0 * SUM(CASE WHEN NameProduct = 'Troca de Pontos StreamElements' THEN QuantityProduct ELSE 0 END) / SUM(QuantityProduct) AS pct_StreamElementsPointsChange,
        1.0 * SUM(CASE WHEN NameProduct = 'Resgatar Ponei' THEN QuantityProduct ELSE 0 END) / SUM(QuantityProduct) AS pct_RedeemedPoneis,
        1.0 * SUM(CASE WHEN NameProduct = 'Presença Streak' THEN QuantityProduct ELSE 0 END) / SUM(QuantityProduct) AS pct_StreakPresence,
        1.0 * SUM(CASE WHEN NameProduct = 'Airflow Lover' THEN QuantityProduct ELSE 0 END) / SUM(QuantityProduct) AS pct_AirflowLover,
        1.0 * SUM(CASE WHEN NameProduct = 'R Lover' THEN QuantityProduct ELSE 0 END) / SUM(QuantityProduct) AS pct_RLover,

        -- Calculate the average number of ChatMessages per live
        1.0 * SUM(CASE WHEN NameProduct = 'ChatMessage' THEN QuantityProduct ELSE 0 END) / COUNT(DISTINCT DATE(dtTransaction)) AS avg_ChatMessage

    FROM tb_product_transactions

    GROUP BY idCustomer 

),

-- Define a CTE named tb_group to calculate the total quantity and points for each product per customer
tb_group AS (

    SELECT
        idCustomer, 
        NameProduct, 
        sum(QuantityProduct) AS qtd,
        sum(pointsTransaction) AS points

    FROM tb_product_transactions

    GROUP BY idCustomer, NameProduct

),

-- Define a CTE named tb_rn_max to calculate the most purchased product
tb_rn_max AS (

    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY idCustomer ORDER BY qtd DESC, points DESC) AS rnQtd

    FROM tb_group  

    ORDER BY idCustomer

),

-- Define a CTE named tb_product_max to filter for the most bought product per customer
tb_product_max AS (

    SELECT *

    FROM tb_rn_max

    WHERE rnQtd = 1

),

-- Define a CTE named tb_rn_min to calculate the least purchased product
tb_rn_min AS (

    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY idCustomer ORDER BY qtd ASC, points ASC) AS rnQtd

    FROM tb_group

    ORDER BY idCustomer

),

-- Define a CTE named tb_product_min to filter for the least bought product per customer
tb_product_min AS (

    SELECT *

    FROM tb_rn_min

    WHERE rnQtd = 1

)

-- Select the final results
SELECT 
    '{date}' AS dtRef,
    t1.*,
    t2.NameProduct AS topProduct,
    t3.NameProduct AS bottomProduct

FROM tb_share AS t1

LEFT JOIN tb_product_max AS t2
ON t1.idCustomer = t2.idCustomer

LEFT JOIN tb_product_min AS t3
ON t1.idCustomer = t3.idCustomer
