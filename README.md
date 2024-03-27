## Mint-Classics-Analysis
This is my analysis process for the Coursera project 'Analyze Data in a Model Car Database with MySQL Workbench'.

## Project Scenario
The Mint Classics Company (MC) is a completely made-up company that sells model cars, and is looking at closing one of their storage facilities. 
To support a data-based business decision, they are looking for suggestions and recommendations for reorganizing or reducing inventory, while still maintaining timely service to their customers. 
This project delves into an exploratory data analysis (EDA) of the MC database, examining various facets of inventory management, sales correlations, and warehouse utilization.
The challenge is to conduct an exploratory data analysis to investigate if there are any patterns or themes that may influence the reduction or reorganization of inventory in the Mint Classics storage facilities. 

**Key Takeaway:** I’m a real analyst helping a fake business solve a fake problem to demonstrate my ability to use SQL to you!

### Project Objectives

1. Explore products currently in inventory.

2. Determine important factors that may influence inventory reorganization/reduction.

3. Provide analytic insights and data-driven recommendations.

## Data Description
The data from this project comes from Coursera, and it is prepared to be used in MySQL Workbench.
The project utilizes a schema with the following EER (Extended Entity-Relationship) diagram that models the structure of the Mint Classics database.

![image](https://github.com/mateo-santos/Mint-Classics-Analysis/assets/161756142/e5049e70-a145-4231-8283-e29f9a388717)

The database itself was uploaded from a database script (with a very long code). I downloaded the script and imported it into MySQL Workbench to set up this whole database.

## Data Exploration
My first step in the analysis was to familiarize myself with the database and business process, so I spent time learning the structure of the different tables, understanding their relations and memorizing where was the data stored. 
Once I understood the business process and the schema, I asked myself questions that oriented and helped me to clarify the path and come to conclusions. You can check my questions with the queries that answer them in the 'MySQL Queries' file. After answering those questions I came up with different scenarios to check the possibility of closing one warehouse.

I will also write the questions and scenarios here with the observations, findings and conclusions that came from them.

### Questions
1. Where are items stored?
  **Findings:**
  - Warehouse A (wa): Motorcycles and Planes
  - Warehouse B (wb): Classic Cars
  - Warehouse C (wc:) Vintage Cars
  - Warehouse D (wd): Ships, Trains, Trucks and Buses
  - There are no productLine stocks split in more than one warehouse.

![image](https://github.com/mateo-santos/Mint-Classics-Analysis/assets/161756142/8f98ef0b-c71d-4894-aade-09d557520b85)

2. What's the sales number for each item? Quantity In Stock vs Quantity Ordered
  Observations: 
  - 1985 Toyota Supra (S18_3233) hasn't been sold in 2.5 years period.
  - There is no correlation between MSRP and number of sales. 
  - Most sold item: 1992 Ferrari 360 Spider Red (S18_3232) - 1808 items sold
  - Least sold item: 1957 Ford Thunderbird (S18_ 4933) - 767 items sold
  - There's a big gap in sales between #1 and #2 (1808 vs. 1111).
  - The majority of the products (around 80%) have sales representing less than 50% of the stock they have.

![image](https://github.com/mateo-santos/Mint-Classics-Analysis/assets/161756142/58cb16fe-87bb-434e-9161-43c266069e2e)

3. How long are they taking to deliver? Is it possible guarantee the deliver in 24 hours?
  Observations:
  - There are no cases of orders delivered in 24hs.
  - Fastest deliveries (from OrderDay to Delivered): 6 days.
   
![image](https://github.com/mateo-santos/Mint-Classics-Analysis/assets/161756142/ef1e3f5f-62bf-4d54-a8c9-e9f0d647eb5e)

4. Are some items sold more often than others?
Observations:
- There's again a big gap between the most ordered item (S18_3232) and the following one, almost the double of times (53 times oredered against 28).
- Besides S18_3232, the rest of products are ordered a similar amount of times.

![image](https://github.com/mateo-santos/Mint-Classics-Analysis/assets/161756142/de6e2a18-09b7-4068-8bcc-0013f6bfc015)

### Scenario 1
**Assumption:**
- For this scenario I considered that all items have the same packaging size. Then we studied the warehouses' capacities (total capacity, used capacity and free capacity), obtaining the following table.

![image](https://github.com/mateo-santos/Mint-Classics-Analysis/assets/161756142/9e420cd3-b60e-4955-82e2-8b582eb6b0bd)

Once we know the different capacities we propose the following scenario.
- We close one warehouse and redistribute its inventory to the rest of the warehouses without reducing stock.
- We would check if it is possible to close 'wd' (the smallest one) and redistribute its stock by productLine. Trains will go to 'wa', Ships to 'wb' and Trucks and Buses to 'wc'.
- This way we are ensuring that each productLine will remain stored in only one warehouse.

The following table shows the capacities for the scenario 1 after wd's inventory redistribution 

![image](https://github.com/mateo-santos/Mint-Classics-Analysis/assets/161756142/bd9febc1-f279-45ed-a1fe-0abf7d39a66c)

**Findings:**
- wa is now taking three productLines and is using 81,1% of its storage capacity.
- wb is now taking two productLines and is using 75,2% of its storage capacity.
- wc is now taking two productLines and is using 64,3% of its storage capacity.
- All three warehouses have free space in case they need to store overproduction.

**Conclusion:**
- Closing wd without reducing stock levels at all is possible.

### Scenario 2
- In this scenario we are gonna give different packaging sizes to products depending on their scale and check if there's a need of reducing stock levels in order to close one warehouse and redistribute its inventory.

**Sizes relations:**
	S = S

  M = 2S
  
  L = 4S

**Sizes Categorization:**

_Motorcycles:_

  M -> 1/10
  
       1/12

       1/18
         
  S -> 1/24
  
			 1/32
      
       1/50
         
_Planes & Ships:_
 
  L -> 1/18
  
       1/24
      
  M -> 1/72
  
  S -> 1/700
    
_Cars:_
 
  L -> 1/10
  
			 1/12
      
  M -> 1/18
  
			 1/24
      
  S -> 1/32
  
			 1/50
      
_Trains:_
 
  L -> 1/18
  
			 1/32
      
  M -> 1/50
  
_Trucks & Buses:_
 
  L -> 1/12

       1/18
    
       1/24
    
  M -> 1/32

  S -> 1/50
    
- With the sizes relation and categorization we obtain the warehouses capacities measured in units size S, to see in the following table:

![image](https://github.com/mateo-santos/Mint-Classics-Analysis/assets/161756142/201df284-0915-4464-a3cb-a4215f9b4275)

![image](https://github.com/mateo-santos/Mint-Classics-Analysis/assets/161756142/772b6433-8093-4d21-8223-32cf39f89045)

- We checked the stock levels measured in units size S by product line, to see if it is possible to redistribute them without splitting their stock in multiple warehouses.

![image](https://github.com/mateo-santos/Mint-Classics-Analysis/assets/161756142/07f2899c-a490-4704-b31c-184b6f983a70)

- Finally, we got the warehouses' capacities after the inventory redistribution:

![image](https://github.com/mateo-santos/Mint-Classics-Analysis/assets/161756142/5ce803a0-18e6-4f79-b59a-ff170fd8c2cf)

**Findings:**
- wa is now taking three productLines and is using 85% of its storage capacity.
- wb is now taking two productLines and is using 82,6% of its storage capacity.
- wc is now taking two productLines and is using 63,1% of its storage capacity.
- All three warehouses have free space in case they need to store overproduction.
- There's no need to reduce stock level for the redistribution

**Conclusion:**
- Closing wd without reducing stock levels at all is possible.

## Recommendations after analysis
- Discontinue the 1985 Toyota Supra. This is the only product with no sales in the 2.5 years period. There's still a current stock of 7733 cars, I would suggest to make a big deal to get rid of them, freeing more warehouse space and increasing revenue.

- Items that have been ordered together many times could be stored in the same warehouse.

## Comments
- There's an interesting study regarding revenue and profit for each product that could be made.








