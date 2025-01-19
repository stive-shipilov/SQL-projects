DECLARE @parametr FLOAT; 
SET @parametr = 50

DECLARE @customer_par INT;
SET @customer_par = 4

DECLARE @goods_par INT;
SET @goods_par = 4

-- Пункт 1: Выбор товаров, у которых произведение QtyInStock и Volume больше заданного параметра
SELECT Good
FROM Goods
WHERE QtyInStock * Volume > @parametr

-- Пункт 2: Выбор городов, где количество клиентов меньше 5
SELECT City
FROM Customers
GROUP BY City
HAVING COUNT(Customer) < 5

-- Пункт 3: Выбор информации по документации (Data, DocNum, Good_id, Qty, Price) для конкретного клиента
SELECT info.[Data], info.DocNum, docs.Good_id, docs.Qty, docs.Price
FROM Docs_data as docs
JOIN Docs as info
ON docs.DocNum = info.DocNum
WHERE info.Cust_ID = @customer_par

-- Пункт 4: Выбор уникальных товаров, купленных в октябре 2024 года
SELECT DISTINCT god.Good
FROM Docs_data as docs
JOIN Docs as info
ON docs.DocNum = info.DocNum
JOIN Goods as god 
ON god.Good_id = docs.Good_id
WHERE CAST(info.Data as Date) BETWEEN '01.10.24' AND '31.10.24'

-- Пункт 5: Выбор города клиентов, купивших определённый товар
SELECT cust.City
FROM Docs_data as docs
JOIN Docs as info
ON docs.DocNum = info.DocNum
JOIN Customers as cust 
ON info.Cust_ID = cust.Cust_id
WHERE docs.Good_id = @goods_par
GROUP BY cust.City

-- Пункт 6: Покупатель, купивший самый дорогой товар за октябрь 2024 года
SELECT TOP 1 with ties cust.Customer AS [Покупатель купивший самый дорогой товар]
FROM Docs_data as docs
JOIN Docs as info
ON docs.DocNum = info.DocNum
JOIN Customers as cust 
ON info.Cust_ID = cust.Cust_id
WHERE CAST(info.Data as Date) BETWEEN '01.10.24' AND '31.10.24'
ORDER BY docs.Price DESC

-- Пункт 7: Суммарный проданный объём товаров за октябрь 2024 года
SELECT SUM(god.Volume * docs.Qty) AS [Суммарный проданный объём]
FROM Docs_data as docs
JOIN Docs as info
ON docs.DocNum = info.DocNum
JOIN Goods as god 
ON god.Good_id = docs.Good_id
WHERE CAST(info.Data as Date) BETWEEN '01.10.24' AND '31.10.24'

-- Пункт 8: Город с самым большим суммарным оборотом за октябрь 2024 года
SELECT TOP 1 with ties City, SUM(docs.Price * docs.Qty) AS [Суммарный оборот]
FROM Docs_data as docs
JOIN Docs as info
ON docs.DocNum = info.DocNum
JOIN Customers as cust 
ON info.Cust_ID = cust.Cust_id
GROUP BY cust.City
ORDER BY SUM(docs.Price * docs.Qty) DESC

-- Пункт 9: Документы, где сумма всех товаров не равна Total в документе
SELECT docs.DocNum, info.Total, SUM(docs.Price * docs.Qty)
FROM Docs_data as docs
JOIN Docs as info
ON docs.DocNum = info.DocNum
JOIN Customers as cust 
ON info.Cust_ID = cust.Cust_id
JOIN Goods as god 
ON god.Good_id = docs.Good_id
GROUP BY docs.DocNum, info.Total
HAVING info.Total <> SUM(docs.Price * docs.Qty)
