-- Пункт 1: Реализация структуры хранения матрицы
CREATE TYPE MatrixTable AS TABLE (
    row_id INT,
    col_id INT,
    val INT
);
GO

-- Функция для проверки возможности сложения двух матриц
-- Пункт 10: Проверка, можно ли сложить две матрицы
CREATE FUNCTION AdditionalCheck (@TableNum1 INT, @TableNum2 INT)
RETURNS NVARCHAR(50) 
AS
BEGIN
    RETURN CASE WHEN 
    ((SELECT MAX(row_id) FROM МатрицыТест WHERE M_id = @TableNum1) 
    = (SELECT MAX(row_id) FROM МатрицыТест WHERE M_id = @TableNum2))
    AND
    ((SELECT MAX(col_id) FROM МатрицыТест WHERE M_id = @TableNum1) 
    = (SELECT MAX(col_id) FROM МатрицыТест WHERE M_id = @TableNum2))
    THEN 'Можно сложить' ELSE 'Нельзя сложить'
    END
END;
GO 

-- Функция для сложения двух матриц
-- Пункт 11: Результат сложения двух матриц
CREATE FUNCTION MatrixSumma (@Matrix1 MatrixTable READONLY, 
                             @Matrix2 MatrixTable READONLY)
RETURNS @ResultTable TABLE (
    row_id INT,
    col_id INT,
    val INT
)
AS
BEGIN
    INSERT INTO @ResultTable (row_id, col_id, val)
    SELECT m1.row_id, m1.col_id, (m1.val + m2.val) as val_sum
    FROM  @Matrix1 AS m1
    JOIN @Matrix2 AS m2
    ON m1.col_id = m2.col_id AND m1.row_id = m2.row_id;
    RETURN
END;
GO   

-- Матрицы для операций
DECLARE @matrix1 AS INT
SET @matrix1 = 1

DECLARE @matrix2 AS INT
SET @matrix2 = 7

DECLARE @number AS INT
SET @number = 10

DECLARE @matrix_D AS INT  
SET @matrix_D = 8

-- Матрицы для решения уравнения C + X = B
DECLARE @matrix_C_ID AS INT
SET @matrix_C_ID = 1

DECLARE @matrix_B_ID AS INT  
SET @matrix_B_ID = 2

DECLARE @AdditionCheck NVARCHAR(30);

-- Пункт 2: Показать матрицу
SELECT *
FROM МатрицыТест
WHERE M_id = @matrix1

-- Пункт 3: Возврат транспонированной матрицы
SELECT M_id,
    col_id AS new_row_id,
    row_id AS new_col_id,
    val
FROM МатрицыТест
WHERE M_id = @matrix1;

-- Пункт 4: Умножение матрицы на число
SELECT M_id, row_id, col_id, val*@number as new_val
FROM МатрицыТест
WHERE M_id = @matrix1

-- Пункт 5: Проверка, является ли матрица вектором
SELECT M_id,
    IIF(MAX(row_id) = 1 OR MAX(col_id) = 1, 'Да', 'Нет') AS IsItVector
FROM МатрицыТест
WHERE M_id = @matrix1
GROUP BY M_id;

-- Пункт 6: Проверка, является ли матрица квадратной
DECLARE @IsSquare NVARCHAR(10);

SET @IsSquare = (SELECT 
    CASE WHEN MAX(row_id) = MAX(col_id) THEN 'Да'
    ELSE 'Нет' END AS IsSquare 
FROM 
    МатрицыТест
WHERE 
    M_id = @matrix1
);

SELECT @IsSquare AS [Is Matrix Square];

-- Пункт 7: Проверка, является ли матрица симметричной
SELECT 
    IIF(COUNT(*) = 0 AND @IsSquare = 'Да', 'Да', 'Нет') AS IsItSymmmetry
FROM 
    МатрицыТест AS A
JOIN 
    МатрицыТест AS B
ON 
    A.M_id = B.M_id       
    AND A.row_id = B.col_id  
    AND A.col_id = B.row_id  
WHERE 
    A.M_id = @matrix1 AND 
    A.val <> B.val

-- Пункт 8: Элементы на пересечении нечётных строк и чётных столбцов
SELECT  M_id,
        (row_id / 2 + 1) AS new_row,
        col_id / 2 AS new_col,        
        val
FROM 
    МатрицыТест  
WHERE 
    ((col_id % 2) = 0 AND (row_id % 2) = 1) AND M_id = @matrix;

-- Пункт 9: Элементы матрицы с координатами из другой матрицы
SELECT mat.col_id, mat.row_id, mat.val
FROM МатрицыТест AS mat
JOIN МатрицыТест AS cord_x
    ON cord_x.row_id = 1 
JOIN МатрицыТест AS cord_y 
    ON cord_y.row_id = 2  
WHERE mat.M_id = @matrix AND cord_x.M_id = @matrix_D  
    AND cord_y.M_id = @matrix_D  
    AND cord_x.val = mat.row_id AND cord_y.val = mat.col_id
    AND cord_y.col_id = cord_x.col_id

DROP TYPE MatrixTable;

-- Пункт 10: Проверка возможности сложения двух матриц
SET @AdditionCheck = dbo.AdditionalCheck(@matrix1, @matrix2);

SELECT @AdditionCheck AS Result;


-- Пункт 11: Результат сложения двух матриц
DECLARE @FirstMatrix MatrixTable;
DECLARE @SecondMatrix MatrixTable;

INSERT INTO @FirstMatrix
SELECT row_id, col_id, val
FROM МатрицыТест 
WHERE M_id = @matrix1;

INSERT INTO @SecondMatrix
SELECT row_id, col_id, val
FROM МатрицыТест 
WHERE M_id = @matrix2;

IF @AdditionCheck = 'Можно сложить'
BEGIN
    SELECT * 
    FROM dbo.MatrixSumma(@FirstMatrix, @SecondMatrix);
END
ELSE
BEGIN
    SELECT 'Нельзя сложить' AS AdditionCheck;
END

-- Пункт 12: Проверка, можно ли перемножить две матрицы
SET @MplcChkFlag = dbo.MultiplicationCheck(@matrix1, @matrix2);

SELECT @MplcChkFlag AS Result;

-- Пункт 13: Результат умножения двух матриц
IF @MplcChkFlag = 'Можно перемножить'
BEGIN
    SELECT mat1.row_id, mat2.col_id, SUM(mat1.val * mat2.val) AS val
    FROM МатрицыТест AS mat1
    JOIN МатрицыТест AS mat2 
        ON mat1.col_id = mat2.row_id AND mat2.M_id = @matrix2 
    WHERE mat1.M_id = @matrix1
    GROUP BY mat1.row_id, mat2.col_id;
END
ELSE
BEGIN
    SELECT 'Нельзя перемножить' AS MultiplicationCheck;
END

-- Пункт 14: Решение уравнения AX = B для ортогональной матрицы
DECLARE @TrnspMatrix_A MatrixTable;

INSERT INTO @TrnspMatrix_A
SELECT col_id AS row_id, row_id AS col_id, val 
FROM МатрицыТест 
WHERE M_id = @matrix1;

DECLARE @OrthogonalCheck NVARCHAR(50);
SET @OrthogonalCheck = 
(
    SELECT IIF(COUNT(*) = 0, 'Да', 'Нет')
    FROM (SELECT mat1.row_id, mat2.col_id, SUM(mat1.val * mat2.val) AS val
            FROM МатрицыТест AS mat1
            JOIN @TrnspMatrix_A AS mat2
                ON mat1.col_id = mat2.row_id 
            WHERE mat1.M_id = @matrix1
            GROUP BY mat1.row_id, mat2.col_id) AS mat
    WHERE ((mat.row_id <> mat.col_id) OR mat.val <> 1) AND ((mat.row_id = mat.col_id) OR mat.val <> 0)
);

IF @MultiplicationCheck = 'Можно перемножить' AND @OrthogonalCheck = 'Да'
BEGIN
    SELECT mat1.row_id, mat2.col_id, SUM(mat1.val * mat2.val)
    FROM @TrnspMatrix_A AS mat1
    JOIN МатрицыТест AS mat2 
        ON mat1.col_id = mat2.row_id AND mat2.M_id = @matrix2 
    GROUP BY mat1.row_id, mat2.col_id;
END
ELSE
BEGIN
    SELECT 'Нельзя решить уравнение' AS AdditionCheck;
END

DROP FUNCTION dbo.MultiplicationCheck;
DROP TYPE MatrixTable;

-- Пункт 15: Решение уравнения C + X = B
DECLARE @Matrix_C MatrixTable;
DECLARE @Matrix_B MatrixTable;

INSERT INTO @Matrix_C
SELECT row_id, col_id, val * (-1) AS value 
FROM МатрицыТест 
WHERE M_id = @matrix_C_ID;

INSERT INTO @Matrix_B
SELECT row_id, col_id, val
FROM МатрицыТест 
WHERE M_id = @matrix_B_ID;

SET @AdditionCheck = dbo.AdditionalCheck(@Matrix_C_ID, @Matrix_B_ID);

IF @AdditionCheck = 'Можно сложить'
BEGIN
    SELECT * 
    FROM dbo.MatrixSumma(@Matrix_C, @Matrix_B);
END
ELSE
BEGIN
    SELECT 'Нельзя решить уравнение' AS AdditionCheck;
END

DROP FUNCTION dbo.AdditionalCheck;
DROP FUNCTION dbo.MatrixSumma;
DROP TYPE MatrixTable;

