-- 1. Where are items stored?
/* Observations:
wa: motorcycles and planes
wb: classic cars
wc: vintage cars
wd: ships, trains, trucks and buses
- There are no productLine stocks split in more than one warehouse.
*/

SELECT 
    warehouseCode,
    productLine,
    SUM(quantityinstock) AS total_stock
FROM products
GROUP BY warehouseCode, productLine
order by warehouseCode
;

/* I could've assumed different packaging sizes depending on the scale of the product, but I decided to simplify the analysis since I'm using this activity to showcase my SQL skills. So, I considered all items have the same packaging size.
That being said, the following query shows the warehouse's capacities.
*/

SELECT 
    products.warehouseCode,
    SUM(quantityinstock) AS total_stock,
    (SUM(quantityinstock)/(warehousePctCap*0.01)) AS warehouseTotalCap,
     warehousePctCap AS `%_warehouseUsedCap`,
    (SUM(quantityinstock)/(warehousePctCap*0.01))-SUM(quantityinstock) AS warehouseFreeCap
FROM products
	LEFT JOIN warehouses ON products.warehouseCode = warehouses.warehouseCode
GROUP BY warehouseCode
order by warehouseCode
;

-- WHAT IF SCENARIOS:
/* - SCENARIO 1: 
- We close one warehouse and redistribute its inventory to the rest of the warehouses without reducing stock.
- We would check if it is possible to close warehouse d (the smallest one) and redistribute its stock by productLine. Trains will go to 'wa', Ships to 'wb' and Trucks and Buses to 'wc'.
- This way we are ensuring that each productLine will remain stored in only one warehouse.
*/

SELECT 
    products.warehouseCode,
    SUM(quantityinstock) + CASE	
		WHEN products.warehouseCode = 'a' THEN 16696 -- We are adding to 'wa' the trains stock from 'wd'
		WHEN products.warehouseCode = 'b' THEN 26833 -- We are adding to 'wb' the ships stock from 'wd'
		WHEN products.warehouseCode = 'c' THEN 35851 -- We are adding to 'wc' the trucks stock from 'wd'
		WHEN products.warehouseCode = 'd' THEN -79380 -- Subtraction of 'wd' stock
        ELSE 0
       END AS scenario1_total_stock,
    (SUM(quantityinstock)/(warehousePctCap*0.01)) AS warehouseTotalCap,
	((SUM(quantityinstock) + CASE
		WHEN products.warehouseCode = 'a' THEN 16696
		WHEN products.warehouseCode = 'b' THEN 26833
		WHEN products.warehouseCode = 'c' THEN 35851
		WHEN products.warehouseCode = 'd' THEN -79380
        ELSE 0
		END) / (SUM(quantityinstock)/(warehousePctCap*0.01))) * 100 AS `%_warehouseUsedCap`
FROM products
	LEFT JOIN warehouses ON products.warehouseCode = warehouses.warehouseCode
GROUP BY warehouseCode
order by warehouseCode
;

-- SCENARIO 1
/* Findings:
- wa is now taking three productLines and is using 81,1% of its storage capacity.
- wb is now taking two productLines and is using 75,2% of its storage capacity.
- wc is now taking two productLines and is using 64,3% of its storage capacity.
- All three warehouses have free space in case they need to store overproduction.
*/
/* Conclusion:
- Closing wd without reducing stock levels at all is possible.
*/

-- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------

/* - SCENARIO 2:
- In this scenario we are gonna give different packaging sizes to products depending on their scale and check if there's a need of reducing stock levels in order to close one warehouse and redistribute its inventory.
*/
/* - Sizes relations:
	S = S
    M = 2S
    L = 4S
*/
/* - Categorization
	Motorcycles: 
		M -> 1/10
			 1/12
             1/18
		S -> 1/24
			 1/32
             1/50
	Planes & Ships:
		L -> 1/18
			 1/24
		M -> 1/72
        S -> 1/700
	Cars:
		L -> 1/10
			 1/12
		M -> 1/18
			 1/24
		S -> 1/32
			 1/50
	Trains:
		L -> 1/18
			 1/32
		M -> 1/50
	Trucks & Buses:
		L -> 1/12
			 1/18
			 1/24
		M -> 1/32
        S -> 1/50
*/

-- Now we are going to check the sizes distribution per warehouse, and will use size 'S' as our measure unit.

SELECT
	warehouseCode,    
    ProductLine,
    total_stock,
    packaging_size,
    CASE
		WHEN packaging_size = 'M' THEN (total_stock * 2)
        WHEN packaging_size = 'L' THEN (total_stock * 4)
        ELSE total_stock
        END AS stock_in_S_units
FROM(
	SELECT 
		warehouseCode,
		productLine,
		SUM(quantityinstock) AS total_stock,
		CASE 
			WHEN productScale IN ('1:10', '1:12', '1:18') AND productLine = 'Motorcycles' THEN 'M'
			WHEN productScale IN ('1:24', '1:32', '1:50') AND productLine = 'Motorcycles' THEN 'S'
			WHEN productScale IN ('1:18', '1:24') AND productLine IN ('Planes', 'Ships') THEN 'L'
			WHEN productScale IN ('1:72') AND productLine IN ('Planes', 'Ships') THEN 'M'
			WHEN productScale IN ('1:700') AND productLine IN ('Planes', 'Ships') THEN 'S'
			WHEN productScale IN ('1:10', '1:12') AND productLine IN ('Classic Cars', 'Vintage Cars') THEN 'L'
			WHEN productScale IN ('1:18', '1:24') AND productLine IN ('Classic Cars', 'Vintage Cars') THEN 'M'
			WHEN productScale IN ('1:32', '1:50') AND productLine IN ('Classic Cars', 'Vintage Cars') THEN 'S'
			WHEN productScale IN ('1:18', '1:32') AND productLine = 'Trains' THEN 'L'
			WHEN productScale IN ('1:50') AND productLine = 'Trains' THEN 'M'
			WHEN productScale IN ('1:12', '1:18', '1:24') AND productLine = 'Trucks and Buses' THEN 'L'
			WHEN productScale IN ('1:32') AND productLine = 'Trucks and Buses' THEN 'M'
			WHEN productScale IN ('1:50') AND productLine = 'Trucks and Buses' THEN 'S'
			ELSE 'Other'
			END AS packaging_size
	FROM products
	GROUP BY warehouseCode, productLine, packaging_size
    ) AS subquery
ORDER BY warehouseCode, productLine
;

-- The following query is the same as the one above but it sums the stocks to have a measuring point

SELECT
    subquery.warehouseCode,    
    SUM(total_stock) AS total_stock,
    SUM( CASE
            WHEN packaging_size = 'M' THEN (total_stock * 2)
            WHEN packaging_size = 'L' THEN (total_stock * 4)
            ELSE total_stock
        END)
        AS stock_in_S_units,
	warehousePctCap AS `%_warehouseUsedCap`
FROM (
    SELECT 
        warehouseCode,
        productLine,
        SUM(quantityinstock) AS total_stock,
        CASE 
            WHEN productScale IN ('1:10', '1:12', '1:18') AND productLine = 'Motorcycles' THEN 'M'
            WHEN productScale IN ('1:24', '1:32', '1:50') AND productLine = 'Motorcycles' THEN 'S'
            WHEN productScale IN ('1:18', '1:24') AND productLine IN ('Planes', 'Ships') THEN 'L'
            WHEN productScale IN ('1:72') AND productLine IN ('Planes', 'Ships') THEN 'M'
            WHEN productScale IN ('1:700') AND productLine IN ('Planes', 'Ships') THEN 'S'
            WHEN productScale IN ('1:10', '1:12') AND productLine IN ('Classic Cars', 'Vintage Cars') THEN 'L'
            WHEN productScale IN ('1:18', '1:24') AND productLine IN ('Classic Cars', 'Vintage Cars') THEN 'M'
            WHEN productScale IN ('1:32', '1:50') AND productLine IN ('Classic Cars', 'Vintage Cars') THEN 'S'
            WHEN productScale IN ('1:18', '1:32') AND productLine = 'Trains' THEN 'L'
            WHEN productScale IN ('1:50') AND productLine = 'Trains' THEN 'M'
            WHEN productScale IN ('1:12', '1:18', '1:24') AND productLine = 'Trucks and Buses' THEN 'L'
            WHEN productScale IN ('1:32') AND productLine = 'Trucks and Buses' THEN 'M'
            WHEN productScale IN ('1:50') AND productLine = 'Trucks and Buses' THEN 'S'
            ELSE 'Other'
        END AS packaging_size
    FROM products
    GROUP BY warehouseCode, productLine, packaging_size
) AS subquery
	LEFT JOIN warehouses ON subquery.warehouseCode = warehouses.warehouseCode
GROUP BY warehouseCode
ORDER BY warehouseCode
;

-- Now we're querying to get the warehouses' total capacities in S units.

SELECT 
	warehouseCode,
    total_stock,
    stock_in_S_units,
    warehousePctCap AS `%_warehouseUsedCap`,
    (stock_in_S_units / (warehousePctCap*0.01)) AS warehouseTotalCap_In_S_units,
	(stock_in_S_units / (warehousePctCap*0.01)) - stock_in_S_units AS warehouseFreeCap_In_S_units
FROM(
	SELECT
		subquery.warehouseCode,    
		SUM(total_stock) AS total_stock,
		SUM( CASE
				WHEN packaging_size = 'M' THEN (total_stock * 2)
				WHEN packaging_size = 'L' THEN (total_stock * 4)
				ELSE total_stock
			END)
			AS stock_in_S_units,
		warehousePctCap
	FROM (
		SELECT 
			warehouseCode,
			productLine,
			SUM(quantityinstock) AS total_stock,
			CASE 
				WHEN productScale IN ('1:10', '1:12', '1:18') AND productLine = 'Motorcycles' THEN 'M'
				WHEN productScale IN ('1:24', '1:32', '1:50') AND productLine = 'Motorcycles' THEN 'S'
				WHEN productScale IN ('1:18', '1:24') AND productLine IN ('Planes', 'Ships') THEN 'L'
				WHEN productScale IN ('1:72') AND productLine IN ('Planes', 'Ships') THEN 'M'
				WHEN productScale IN ('1:700') AND productLine IN ('Planes', 'Ships') THEN 'S'
				WHEN productScale IN ('1:10', '1:12') AND productLine IN ('Classic Cars', 'Vintage Cars') THEN 'L'
				WHEN productScale IN ('1:18', '1:24') AND productLine IN ('Classic Cars', 'Vintage Cars') THEN 'M'
				WHEN productScale IN ('1:32', '1:50') AND productLine IN ('Classic Cars', 'Vintage Cars') THEN 'S'
				WHEN productScale IN ('1:18', '1:32') AND productLine = 'Trains' THEN 'L'
				WHEN productScale IN ('1:50') AND productLine = 'Trains' THEN 'M'
				WHEN productScale IN ('1:12', '1:18', '1:24') AND productLine = 'Trucks and Buses' THEN 'L'
				WHEN productScale IN ('1:32') AND productLine = 'Trucks and Buses' THEN 'M'
				WHEN productScale IN ('1:50') AND productLine = 'Trucks and Buses' THEN 'S'
				ELSE 'Other'
			END AS packaging_size
		FROM products
		GROUP BY warehouseCode, productLine, packaging_size
	) AS subquery
		LEFT JOIN warehouses ON subquery.warehouseCode = warehouses.warehouseCode
	GROUP BY warehouseCode
) AS subquery_2
ORDER BY warehouseCode
;

-- The following query sums the stocks in S units per productLine. This will let us check if it is possible to redistribute a whole productLine stock without splitting it in multiple warehouses.

SELECT
    subquery.productLine,    
    SUM(total_stock) AS total_stock,
    SUM( CASE
            WHEN packaging_size = 'M' THEN (total_stock * 2)
            WHEN packaging_size = 'L' THEN (total_stock * 4)
            ELSE total_stock
        END)
        AS stock_in_S_units
FROM (
    SELECT 
        warehouseCode,
        productLine,
        SUM(quantityinstock) AS total_stock,
        CASE 
            WHEN productScale IN ('1:10', '1:12', '1:18') AND productLine = 'Motorcycles' THEN 'M'
            WHEN productScale IN ('1:24', '1:32', '1:50') AND productLine = 'Motorcycles' THEN 'S'
            WHEN productScale IN ('1:18', '1:24') AND productLine IN ('Planes', 'Ships') THEN 'L'
            WHEN productScale IN ('1:72') AND productLine IN ('Planes', 'Ships') THEN 'M'
            WHEN productScale IN ('1:700') AND productLine IN ('Planes', 'Ships') THEN 'S'
            WHEN productScale IN ('1:10', '1:12') AND productLine IN ('Classic Cars', 'Vintage Cars') THEN 'L'
            WHEN productScale IN ('1:18', '1:24') AND productLine IN ('Classic Cars', 'Vintage Cars') THEN 'M'
            WHEN productScale IN ('1:32', '1:50') AND productLine IN ('Classic Cars', 'Vintage Cars') THEN 'S'
            WHEN productScale IN ('1:18', '1:32') AND productLine = 'Trains' THEN 'L'
            WHEN productScale IN ('1:50') AND productLine = 'Trains' THEN 'M'
            WHEN productScale IN ('1:12', '1:18', '1:24') AND productLine = 'Trucks and Buses' THEN 'L'
            WHEN productScale IN ('1:32') AND productLine = 'Trucks and Buses' THEN 'M'
            WHEN productScale IN ('1:50') AND productLine = 'Trucks and Buses' THEN 'S'
            ELSE 'Other'
        END AS packaging_size
    FROM products
    GROUP BY warehouseCode, productLine, packaging_size
) AS subquery
	LEFT JOIN warehouses ON subquery.warehouseCode = warehouses.warehouseCode
GROUP BY productLine
;

-- WE will redistribute 'wd' inventory in the other warehouses.
-- Ships will go to 'wa'
-- Trains will go to 'wc'
-- Trucks and Buses will go to 'wb'

SELECT 
	warehouseCode,
    stock_in_S_units + CASE
		WHEN warehouseCode = 'a' THEN 45718
        WHEN warehouseCode = 'b' THEN 122782
        WHEN warehouseCode = 'c' THEN 63494
        WHEN warehouseCode = 'a' THEN -231994
	END AS scenario2_warehousePctCap,
    warehouseTotalCap_In_S_units,
    (stock_in_S_units + CASE
		WHEN warehouseCode = 'a' THEN 45718
        WHEN warehouseCode = 'b' THEN 122782
        WHEN warehouseCode = 'c' THEN 63494
        WHEN warehouseCode = 'a' THEN -231994
	END) / warehouseTotalCap_In_S_units * 100 AS `scenario2_%_warehouseFreeCap`
FROM(
	SELECT 
		warehouseCode,
		total_stock,
		stock_in_S_units,
		warehousePctCap AS `%_warehouseUsedCap`,
		(stock_in_S_units / (warehousePctCap*0.01)) AS warehouseTotalCap_In_S_units,
		(stock_in_S_units / (warehousePctCap*0.01)) - stock_in_S_units AS warehouseFreeCap_In_S_units
	FROM(
		SELECT
			subquery.warehouseCode,    
			SUM(total_stock) AS total_stock,
			SUM( CASE
					WHEN packaging_size = 'M' THEN (total_stock * 2)
					WHEN packaging_size = 'L' THEN (total_stock * 4)
					ELSE total_stock
				END)
				AS stock_in_S_units,
			warehousePctCap
		FROM (
			SELECT 
				warehouseCode,
				productLine,
				SUM(quantityinstock) AS total_stock,
				CASE 
					WHEN productScale IN ('1:10', '1:12', '1:18') AND productLine = 'Motorcycles' THEN 'M'
					WHEN productScale IN ('1:24', '1:32', '1:50') AND productLine = 'Motorcycles' THEN 'S'
					WHEN productScale IN ('1:18', '1:24') AND productLine IN ('Planes', 'Ships') THEN 'L'
					WHEN productScale IN ('1:72') AND productLine IN ('Planes', 'Ships') THEN 'M'
					WHEN productScale IN ('1:700') AND productLine IN ('Planes', 'Ships') THEN 'S'
					WHEN productScale IN ('1:10', '1:12') AND productLine IN ('Classic Cars', 'Vintage Cars') THEN 'L'
					WHEN productScale IN ('1:18', '1:24') AND productLine IN ('Classic Cars', 'Vintage Cars') THEN 'M'
					WHEN productScale IN ('1:32', '1:50') AND productLine IN ('Classic Cars', 'Vintage Cars') THEN 'S'
					WHEN productScale IN ('1:18', '1:32') AND productLine = 'Trains' THEN 'L'
					WHEN productScale IN ('1:50') AND productLine = 'Trains' THEN 'M'
					WHEN productScale IN ('1:12', '1:18', '1:24') AND productLine = 'Trucks and Buses' THEN 'L'
					WHEN productScale IN ('1:32') AND productLine = 'Trucks and Buses' THEN 'M'
					WHEN productScale IN ('1:50') AND productLine = 'Trucks and Buses' THEN 'S'
					ELSE 'Other'
				END AS packaging_size
			FROM products
			GROUP BY warehouseCode, productLine, packaging_size
		) AS subquery
			LEFT JOIN warehouses ON subquery.warehouseCode = warehouses.warehouseCode
		GROUP BY warehouseCode
	) AS subquery_2
) AS subquery_3
ORDER BY warehouseCode
;

/* Findings:
- wa is now taking three productLines and is using 85% of its storage capacity.
- wb is now taking two productLines and is using 82,6% of its storage capacity.
- wc is now taking two productLines and is using 63,1% of its storage capacity.
- All three warehouses have free space in case they need to store overproduction.
- There's no need to reduce stock level for the redistribution
*/
/* Conclusion:
- Closing wd without reducing stock levels at all is possible.
*/
	


-- 2. What's the sales number for each item? Quantity In Stock vs Quantity Ordered
/* Observations: 
- S18_3233 hasn't been sold in 2.5 years period.
- There is no correlation between MSRP and number of sales
- Most sold item: S18_3232 - 1808 items sold
- Least sold item: S18_ 4933 - 767 items sold
- There's a big gap in sales between #1 and #2 (1808 vs. 1111) 
- The majority of the products (around 80%) have sales representing less than 50% of the stock they have.
*/
SELECT 
    products.productCode,
    warehouseCode,
    productLine,
    productName,
    quantityInStock,
    SUM(orderdetails.quantityOrdered) AS quantityOrdered,
    (SUM(orderdetails.quantityOrdered) / quantityInStock) * 100 AS `% of inventory ordered`,
    MSRP
FROM products
	LEFT JOIN 
	orderdetails ON products.productCode = orderdetails.productCode
GROUP BY productCode
ORDER BY `% of inventory ordered`
;

-- 3. Delivery time study
/*  Observations:
- There are no cases of orders delivered in 24hs
- Fastest deliveries (from OrderDay to Delivered): 6 days
*/
SELECT 	
	customers.customerNumber,
    city,
    country,
    datediff(shippedDate, orderDate) AS DaysToShip,
    datediff(requiredDate, shippedDate) AS DeliveryDays,
    datediff(shippedDate, orderDate) + datediff(requiredDate, shippedDate) AS fromOrdered_toDelivered
FROM customers
	LEFT JOIN 
	orders ON customers.customerNumber = orders.customerNumber
ORDER BY fromOrdered_toDelivered
;

-- 4. Are some items sold more often than others?
/* Observations:
- There's again a big gap between the most ordered item (S18_3232) and the following one, almost the double of times.
- Besides S18_3232, the rest of products are ordered a similar amount of times.
*/

SELECT 
    productCode, 
    COUNT(productCode) AS timesOrdered
FROM
    orders
	LEFT JOIN
    orderdetails ON orders.orderNumber = orderdetails.orderNumber
GROUP BY productCode
ORDER BY timesOrdered
;

-- 5. What if we reduce the stock for items selling less than 50% of their stock?

SELECT 
    products.productCode,
    warehouseCode,
    productLine,
    productName,
    quantityInStock,
    SUM(orderdetails.quantityOrdered) AS quantityOrdered,
    (SUM(orderdetails.quantityOrdered) / quantityInStock) * 100 AS `% of inventory ordered`,
    MSRP
FROM products
	LEFT JOIN 
	orderdetails ON products.productCode = orderdetails.productCode
GROUP BY productCode
ORDER BY `% of inventory ordered`
;