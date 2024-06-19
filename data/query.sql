SELECT * 
FROM customers AS c 

LEFT JOIN transactions AS t 
ON c.idCustomer = t.idCustomer

LEFT JOIN transactions_product AS tp 
ON t.idTransaction = tp.idTransaction