-- Task 1: Для каждого тарифа за каждый месяц вычислить количество и суммарную стоимость проданных абонементов
SELECT Tariffs.TariffID, Tariffs.Tariff, MONTH(Subscriptions.ValidityMonth) AS [Месяц],
YEAR(Subscriptions.ValidityMonth) AS [ГОД], COUNT(*) AS [Количество тарифов], 
SUM(Tariffs.CostPerMonth) AS [Суммарная стоимость]
FROM Subscriptions
JOIN Tariffs ON Tariffs.TariffID = Subscriptions.TariffID
GROUP BY Subscriptions.ValidityMonth, Tariffs.TariffID, Tariffs.Tariff

-- Task 2: Для каждой парковки за каждый месяц и час посчитать среднее количество припаркованных автомобилей
SELECT ParkTable.ParkingNo, ParkTable.Год, ParkTable.Месяц, ParkTable.Час, Parking.Num, AVG(ParkTable.[Кол-ов автомобилей])
FROM (
    SELECT ParkingData.ParkingNo, Year(ParkingData.DateTime_of_scan) AS [Год],
    MONTH(ParkingData.DateTime_of_scan) AS [Месяц], 
    DATEPART(HOUR, ParkingData.DateTime_of_scan) as [Час], COUNT(ParkingData.RegNo) AS [Кол-ов автомобилей]
    FROM ParkingData
    GROUP BY ParkingData.ParkingNo, ParkingData.DateTime_of_scan
) AS ParkTable
JOIN Parking ON ParkTable.ParkingNo = Parking.ParkingNo
GROUP BY ParkTable.ParkingNo, ParkTable.Год, ParkTable.Месяц, ParkTable.Час, Parking.Num

-- Task 3: Для каждой парковки посчитать количество уникальных автомобилей, которые парковались
SELECT Parking.ParkingNo, COUNT(DISTINCT ParkingData.RegNo) AS [Количество автомобилей]
FROM Parking
LEFT JOIN ParkingData ON Parking.ParkingNo = ParkingData.ParkingNo
GROUP BY Parking.ParkingNo

-- Task 4: Вывести информацию о клиентах и суммарной стоимости счетов за ноябрь 2024
SELECT Clients.ClientID, Clients.ClientsPersNum, SUM(Docs.Total)
FROM Clients
LEFT JOIN Docs ON Clients.ClientID = Docs.ClientID
WHERE CAST(Docs.Date_of_doc AS DATE) BETWEEN '01.11.2024' AND '30.11.2024' 
GROUP BY Clients.ClientID, Clients.ClientsPersNum

-- Task 5: Тарифы, которые не покупали с сентября 2024
SELECT TariffData.TariffID , Tariffs.Tariff
FROM TariffData
JOIN Tariffs ON Tariffs.TariffID = TariffData.TariffID
WHERE TariffData.TariffID NOT IN (
    SELECT DISTINCT TariffData.TariffID
    FROM TariffData
    JOIN Subscriptions ON TariffData.TariffID = Subscriptions.TariffID
    JOIN Docs ON Subscriptions.DocID = Docs.DocID
    WHERE CAST(Docs.Date_of_doc AS DATE) >  '01.09.2024'
)

-- Task 6: Клиенты и автомобили, которые купили абонемент до сентября 2024, но не после
WITH FirstTable AS 
(
    SELECT Subscriptions.CarID, Docs.ClientID
    FROM Subscriptions
    JOIN Docs ON Subscriptions.DocID = Docs.DocID
    LEFT JOIN 
        (
        SELECT Docs.ClientID, Subscriptions.CarID
        FROM Subscriptions
        JOIN Docs ON Subscriptions.DocID = Docs.DocID
        WHERE CAST(Subscriptions.ValidityMonth AS DATE) >  '30.09.2024'
        GROUP BY Docs.ClientID, Subscriptions.CarID
        ) as list
    ON Subscriptions.CarID = list.CarID AND Docs.ClientID = list.ClientID
    WHERE list.ClientID IS NULL
    GROUP BY Subscriptions.CarID, Docs.ClientID
),
SecondTable AS 
(
    SELECT Docs.ClientID, Subscriptions.CarID
    FROM Subscriptions
    JOIN Docs ON Subscriptions.DocID = Docs.DocID
    WHERE MONTH(Subscriptions.ValidityMonth) = 9 
        AND YEAR(Subscriptions.ValidityMonth) = 2024
    GROUP BY Docs.ClientID, Subscriptions.CarID
)

SELECT Docs.ClientID, Subscriptions.CarID
FROM Subscriptions
JOIN Docs ON Subscriptions.DocID = Docs.DocID
LEFT JOIN FirstTable
ON Subscriptions.CarID = FirstTable.CarID AND Docs.ClientID = FirstTable.ClientID
LEFT JOIN SecondTable
ON Subscriptions.CarID = SecondTable.CarID AND Docs.ClientID = SecondTable.ClientID
WHERE (FirstTable.CarID IS NOT NULL) AND (SecondTable.CarID IS NOT NULL)
GROUP BY Docs.ClientID, Subscriptions.CarID

SELECT Docs.ClientID, Subscriptions.CarID, Subscriptions.ValidityMonth
FROM Subscriptions
JOIN Docs ON Subscriptions.DocID = Docs.DocID

-- Task 7: Для каждой зоны посчитать доступные места и загруженность по абонементам
WITH CountAccess AS (
    SELECT Areas.AreaID, Areas.Area, SUM(Parking.Num) AS TotalPlaces
    FROM Areas
    JOIN Parking ON Areas.AreaID = Parking.AreaID
    GROUP BY Areas.AreaID, Areas.Area
),
AreasSubscriptions AS (
    SELECT TariffData.AreaID, COUNT(DISTINCT Subscriptions.CarID) AS CarsSubscriptions
    FROM Subscriptions
    JOIN TariffData ON Subscriptions.TariffID = TariffData.TariffID
    WHERE Subscriptions.ValidityMonth = '2024-11-01'
    GROUP BY TariffData.AreaID
)

SELECT CountAccess.AreaID, CountAccess.Area, CountAccess.TotalPlaces,
    COALESCE(AreasSubscriptions.CarsSubscriptions, 0) AS CarsSubscriptions,
    ROUND(COALESCE(AreasSubscriptions.CarsSubscriptions, 0) * 1.0 / CountAccess.TotalPlaces, 2) AS AreaLoad
FROM CountAccess
LEFT JOIN AreasSubscriptions 
ON AreasSubscriptions.AreaID = CountAccess.AreaID
ORDER BY
    AreaLoad DESC;

-- Task 8: Вывести автомобили, которые купили абонемент, но не были зафиксированы парконном
WITH NotFoundCars AS (
    SELECT DISTINCT Subscriptions.CarID, Cars.RegNo, 'Абонемент есть, но не зафиксирован' AS Comment
    FROM Subscriptions
    LEFT JOIN Cars ON Subscriptions.CarID = Cars.CarID
    WHERE NOT EXISTS
        (
        SELECT *
        FROM ParkingData
        LEFT JOIN Parking ON ParkingData.ParkingNo = Parking.ParkingNo
        LEFT JOIN TariffData ON TariffData.AreaID = Parking.AreaID
        WHERE Subscriptions.TariffID = TariffData.TariffID 
            AND MONTH(Subscriptions.ValidityMonth) = MONTH(ParkingData.DateTime_of_scan)
            AND Cars.RegNo = ParkingData.RegNo 
        )
),
WithoutSub AS (
    SELECT DISTINCT c.CarID, ParkingData.RegNo, 'Зафиксирован, но абонемента нет' AS Comment
    FROM ParkingData
    LEFT JOIN Parking ON ParkingData.ParkingNo = Parking.ParkingNo
    LEFT JOIN TariffData ON TariffData.AreaID = Parking.AreaID
    LEFT JOIN Cars AS c ON c.RegNo = ParkingData.RegNo 
    WHERE NOT EXISTS
        (
        SELECT Subscriptions.CarID, Cars.RegNo 
        FROM Subscriptions
        LEFT JOIN Cars ON Subscriptions.CarID = Cars.CarID
        WHERE Cars.RegNo = ParkingData.RegNo 
            AND MONTH(Subscriptions.ValidityMonth) = MONTH(ParkingData.DateTime_of_scan)
            AND TariffData.TariffID = Subscriptions.TariffID
        )
)

SELECT *
FROM 
    NotFoundCars
UNION ALL
SELECT *
FROM 
    WithoutSub;

-- Task 9: Для заданной даты и автомобиля вывести парковку и дату
DECLARE @Date DATE
SET @Date = '01.10.2024'

SELECT Cars.RegNo, Parking.ParkingNo, @Date AS [Дата]
FROM ParkingData
JOIN Parking ON Parking.ParkingNo = ParkingData.ParkingNo
JOIN Cars ON Cars.RegNo = ParkingData.RegNo
WHERE NOT EXISTS (
    SELECT * 
    FROM Subscriptions
    JOIN TariffData ON TariffData.TariffID = Subscriptions.TariffID
    WHERE Subscriptions.CarID = Cars.CarID 
        AND Parking.AreaID = TariffData.AreaID
        AND MONTH(Subscriptions.ValidityMonth) = MONTH(ParkingData.DateTime_of_scan)
) AND CAST(ParkingData.DateTime_of_scan AS DATE) = @Date

-- Task 10: Суммарная стоимость абонемента и почасовая стоимость парковки
WITH CostPerHour AS (
    SELECT DayParkLog.RegNo, DayParkLog.[Month], DayParkLog.[Year], SUM(DayParkLog.CostPerHour * DayParkLog.[Кол-во секунд стоянки]) * 3600 AS [Стоимость суммарная]
    FROM
    (
        SELECT ParkLog.RegNo, ParkLog.[Date], MONTH(ParkLog.[Date]) AS [Month], YEAR(ParkLog.[Date]) AS [Year], ParkLog.ParkingNo, Areas.CostPerHour,
        IIF(COUNT(*) = 1, 0, DATEDIFF(second, MIN(ParkLog.[DateTime_of_scan]), MAX(ParkLog.[DateTime_of_scan]))) AS [Кол-во секунд стоянки]
        FROM
        (
            SELECT ParkingData.RegNo, ParkingData.DateTime_of_scan, ParkingData.ParkingNo,
                CAST(ParkingData.DateTime_of_scan AS Date) AS [Date]
            FROM ParkingData
            GROUP BY ParkingData.RegNo, ParkingData.DateTime_of_scan, ParkingData.ParkingNo
        ) AS ParkLog
        JOIN Parking ON Parking.ParkingNo = ParkLog.ParkingNo
        JOIN Areas ON Areas.AreaID = Parking.AreaID
        GROUP BY ParkLog.RegNo, ParkLog.[Date], ParkLog.ParkingNo, Areas.CostPerHour
    ) AS DayParkLog
    GROUP BY DayParkLog.RegNo, DayParkLog.[Month], DayParkLog.[Year]
),

CostAbonem AS (
    SELECT Cars.RegNo, YEAR(Subscriptions.ValidityMonth) AS [Year], MONTH(Subscriptions.ValidityMonth) AS [Month], SUM(Subscriptions.Cost) AS [Суммарная стоимость]
    FROM Subscriptions
    JOIN Cars ON Cars.CarID = Subscriptions.CarID
    GROUP BY Cars.RegNo, Subscriptions.ValidityMonth
)

SELECT Cars.CarID, CostPerHour.RegNo, CostAbonem.[Month], CostPerHour.[Year], CostAbonem.[Суммарная стоимость], CostPerHour.[Стоимость суммарная] AS [Почасовая]
FROM CostPerHour
JOIN CostAbonem ON  CostPerHour.RegNo = CostAbonem.RegNo 
    AND CostPerHour.[Month] = CostAbonem.[Month] AND CostPerHour.[Year] = CostAbonem.[Year]
JOIN Cars ON Cars.RegNo = CostAbonem.RegNo

-- Task 11: Проверка и добавление автомобиля по номеру
DECLARE @RegNo NVARCHAR(20) = 'A010BC777'; 

IF EXISTS (
    SELECT *
    FROM Cars
    WHERE RegNo = @RegNo
)
BEGIN
    SELECT 'Ок' AS Message;
END
ELSE
BEGIN
    INSERT INTO Cars (RegNo)
    VALUES (@RegNo);

    SELECT 'Автомобиль с номером ' + @RegNo + ' добавлен' AS Message;
END;

-- Task 12: Проверка, был ли куплен абонемент на автомобиль
DECLARE @ClientID INT = 1;       
DECLARE @CarID INT = 1;   
DECLARE @ValidityMonth DATE = '2024-09-01';
IF EXISTS (
    SELECT *
    FROM Subscriptions
    JOIN Docs ON Docs.DocID = Subscriptions.DocID
    WHERE Subscriptions.CarID = @CarID AND Docs.ClientID = @ClientID
        AND Subscriptions.ValidityMonth = @ValidityMonth
)
BEGIN
    SELECT 'Уже покупал' AS Message;
END
ELSE
BEGIN
    SELECT 'Не покупал' AS Message;
END;

-- Task 13: Добавление новой строки для абонемента
DECLARE @TariffID INT = 3; 
DECLARE @CostPerMonth DECIMAL(10, 2);

SELECT @CostPerMonth = CostPerMonth
FROM Tariffs
WHERE TariffID = @TariffID;

DECLARE @DocID INT;

INSERT INTO Docs (Date_of_doc, ClientID, Total)
VALUES (GETDATE(), @ClientID, @CostPerMonth);

SET @DocID = SCOPE_IDENTITY();

INSERT INTO Subscriptions (DocID, CarID, TariffID, ValidityMonth, Cost)
VALUES (@DocID, @CarID, @TariffID, @ValidityMonth, @CostPerMonth);

-- Task 14: Обновление суммы в документах
UPDATE Docs
SET Total = (
    SELECT SUM(Subscriptions.Cost)
    FROM Subscriptions
    WHERE Subscriptions.DocID = @DocID
)
WHERE Docs.DocID = @DocID
