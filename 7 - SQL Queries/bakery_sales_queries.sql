-- Bakery Sales: SQL Queries

-- (1) Identify the items with the highest and lowest (non-zero) unit price?
SELECT bs.article, bs.unit_price
FROM assignment01.bakery_sales AS bs
WHERE bs.unit_price = (SELECT MAX(unit_price) FROM assignment01.bakery_sales AS bs)
   OR bs.unit_price = (SELECT MIN(unit_price) FROM assignment01.bakery_sales AS bs WHERE unit_price <> 0)
ORDER BY bs.unit_price DESC;

-- (2) Write a SQL query to report the second most sold item from the bakery table.
-- If there is no second most sold item, the query should report NULL.
WITH rank_table AS (
SELECT bs.article,
       SUM(bs.quantity) AS total_quantity,
       rank() over (ORDER BY SUM(bs.quantity) DESC) AS quantity_rank
FROM assignment01.bakery_sales AS bs
GROUP BY bs.article)

SELECT COALESCE(
 (SELECT rank_table.article
 FROM rank_table
 WHERE rank_table.quantity_rank = 150),NULL) AS article;

-- (3) Write a SQL query to report the top 3 most sold items for every month in 2022 including their monthly sales.
WITH monthly AS (
SELECT bs.article,
       SUM(bs.quantity) AS total,
       DATE_PART('month', bs.sale_date) AS month,
       RANK() OVER (PARTITION BY DATE_PART('month', bs.sale_date) ORDER BY SUM(bs.quantity) DESC) AS quantity_rank
FROM assignment01.bakery_sales AS bs
WHERE DATE_PART('year', bs.sale_date) = 2022
GROUP BY bs.article, DATE_PART('month', bs.sale_date)
ORDER BY month)

SELECT monthly.article, monthly.month, monthly.total, monthly.quantity_rank
FROM monthly
WHERE monthly.quantity_rank <= 3;

-- (4) Write a SQL query to report all the tickets with 5 or more articles
-- in August 2022 including the number of articles in each ticket.
SELECT ticket_number,
       COUNT(article) AS num_articles
FROM assignment01.bakery_sales AS bs
WHERE EXTRACT(YEAR FROM sale_datetime) = 2022
 AND EXTRACT(MONTH FROM sale_datetime) = 8
GROUP BY ticket_number
HAVING COUNT(article) >= 5;

-- (5) Write a SQL query to calculate the average sales per day in August 2022?
-- Average Sales per Day in August 2022
SELECT EXTRACT(YEAR FROM bs.sale_date) AS year,
        EXTRACT(MONTH FROM bs.sale_date) AS month,
        EXTRACT(DAY FROM bs.sale_date) AS day,
        SUM(bs.quantity * bs.unit_price) AS daily_sales
 FROM assignment01.bakery_sales AS bs
 WHERE EXTRACT(YEAR FROM bs.sale_date) = '2022' AND EXTRACT(MONTH FROM bs.sale_date) = '08'
 GROUP BY year, month, day;

-- Average Daily Sales for August 2022
WITH aug_daily_sales AS (
 SELECT EXTRACT(YEAR FROM bs.sale_date) AS year,
        EXTRACT(MONTH FROM bs.sale_date) AS month,
        EXTRACT(DAY FROM bs.sale_date) AS day,
        SUM(bs.quantity * bs.unit_price) AS daily_sales
 FROM assignment01.bakery_sales AS bs
 WHERE EXTRACT(YEAR FROM bs.sale_date) = '2022' AND EXTRACT(MONTH FROM bs.sale_date) = '08'
 GROUP BY year, month, day
)

SELECT aug_ds.year,
       aug_ds.month,
       ROUND(AVG(daily_sales), 2) AS avg_daily_sales
FROM aug_daily_sales aug_ds
GROUP BY aug_ds.year, aug_ds.month;

-- (6) Write a SQL query to identify the day of the week with more sales?
SELECT CASE EXTRACT(DOW FROM bs.sale_datetime)
        WHEN 0 THEN 'Sunday'
        WHEN 1 THEN 'Monday'
        WHEN 2 THEN 'Tuesday'
        WHEN 3 THEN 'Wednesday'
        WHEN 4 THEN 'Thursday'
        WHEN 5 THEN 'Friday'
        WHEN 6 THEN 'Saturday'
        END AS day_of_week,
    SUM(bs.quantity * bs.unit_price) AS total_sales
FROM assignment01.bakery_sales AS bs
GROUP BY EXTRACT(DOW FROM bs.sale_datetime)
ORDER BY total_sales DESC
LIMIT 1;

-- (7) What time of the day is the traditional Baguette more popular?
SELECT bs.article,
       DATE_PART('hour', bs.sale_datetime) AS hour,
       SUM(bs.quantity * bs.unit_price) AS total_sales
FROM assignment01.bakery_sales AS bs
WHERE bs.article LIKE 'TRADITIONAL BAGUETTE'
GROUP BY hour, bs.article
ORDER BY total_sales DESC
LIMIT 1;

-- (8) Write a SQL query to find the articles with the lowest sales in each month?
-- Version 1 - Lowest Revenue of All Time by Month
WITH monthly_revenue AS (
 SELECT bs.article,
 EXTRACT(MONTH FROM bs.sale_date) AS sale_month,
 SUM(bs.quantity * bs.unit_price) AS revenue
 FROM ASsignment01.bakery_sales AS bs
 GROUP BY bs.article, sale_month
),
min_monthly_revenue AS (
 SELECT sale_month, MIN(revenue) AS min_revenue
 FROM monthly_revenue
 GROUP BY sale_month
)
SELECT mr.article, mr.sale_month, mr.revenue
FROM monthly_revenue AS mr
JOIN min_monthly_revenue AS mmr
 ON mr.sale_month = mmr.sale_month AND mr.revenue = mmr.min_revenue
ORDER BY mr.sale_month;

-- Version 2 - Lowest Revenue by Month and Year (22 Responses)
WITH monthly_revenue AS (
 SELECT bs.article,
 EXTRACT(year FROM bs.sale_date) AS sale_year,
 EXTRACT(MONTH FROM bs.sale_date) AS sale_month,
 SUM(bs.quantity * bs.unit_price) AS revenue,
 DENSE_RANK() OVER (PARTITION BY EXTRACT(year FROM bs.sale_date), EXTRACT(MONTH FROM bs.sale_date) ORDER BY SUM(bs.quantity * bs.unit_price)) AS row_num
 FROM ASsignment01.bakery_sales AS bs
 GROUP BY bs.article, sale_year, sale_month
)
SELECT article, sale_year, sale_month, revenue
FROM monthly_revenue
WHERE row_num = 1
ORDER BY sale_year, sale_month;

-- (9) Write a query to calculate the percentage of sales for each item
-- between 2022-01-01 and 2022-01-31
SELECT article,
       ROUND((SUM(quantity * unit_price) / (SELECT SUM(quantity * unit_price)
FROM assignment01.bakery_sales
WHERE sale_date BETWEEN '2022-01-01' AND '2022-01-31')) * 100, 2) AS sales_percentage
FROM assignment01.bakery_sales
WHERE sale_date BETWEEN '2022-01-01' AND '2022-01-31'
GROUP BY 1
ORDER BY article;

-- (10) The order rate is computed by dividing the volume of a specific article
-- divided by the total amount of items ordered in a specific date.
-- Calculate the order rate for the Banette for every month during 2022.
WITH bt AS (
SELECT bs.article,
       SUM(bs.quantity * bs.unit_price) AS b_total,
       DATE_PART('month', bs.sale_date) AS month
FROM assignment01.bakery_sales AS bs
WHERE DATE_PART('year', bs.sale_date) = 2022
AND bs.article = 'BANETTE'
GROUP BY bs.article, month),

mt AS (SELECT SUM(bs.quantity * bs.unit_price) AS month_total,
 DATE_PART('month',bs.sale_date) AS month
FROM assignment01.bakery_sales AS bs
WHERE DATE_PART('year',bs.sale_date) = 2022
GROUP BY month)

SELECT bt.article,
       bt.month,
       ROUND(bt.b_total::decimal/mt.month_total::decimal,2) AS order_rate
FROM bt, mt
WHERE mt.month = bt.month;

