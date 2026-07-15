CREATE TABLE accounts (
    account varchar(50) PRIMARY KEY,
    sector VARCHAR(50),
    year_established INT,
	revenue DECIMAL(12,2),
	employees INT,
	office_location VARCHAR(50),
	subsidiary_of VARCHAR(50)
);

CREATE TABLE products (
    product VARCHAR(50) PRIMARY KEY,
	series VARCHAR(10), 
	sales_price DECIMAL(12,2)
);

CREATE TABLE sales_teams (
    sales_agent VARCHAR(50) PRIMARY KEY,
	manager VARCHAR(50),
	regional_office VARCHAR(50)
);

CREATE TABLE sales_pipeline (
    opportunity_id VARCHAR(50) PRIMARY KEY,
	sales_agent VARCHAR(50),
	product VARCHAR(50),
	account VARCHAR(50),
	deal_stage VARCHAR(50),
	engage_date DATE,
	close_date DATE,
    close_value DECIMAL(12,2),
	FOREIGN KEY(sales_agent) 
	REFERENCES sales_teams(sales_agent),
	FOREIGN KEY(product) 
	REFERENCES products(product),
	FOREIGN KEY(account) 
	REFERENCES accounts(account)
);


=========================================================
 PRODUCT & CUSTOMER ANALYTICS DASHBOARD (POSTGRESQL)
=========================================================

---------------------------------------------------------
-- 1. BASE DATA CHECK
---------------------------------------------------------

select * from accounts;
select * from products;
select * from sales_pipeline;
select * from sales_teams;

---------------------------------------------------------
-- 2. TOTAL REVENUE KPIS
---------------------------------------------------------

-- total revenue in the company
select sum(revenue) as total_revenue from accounts;

-- revenue by account (top customers)
select account, sum(revenue) as total_revenue from accounts
group by account
order by total_revenue desc;

-- total orders
select count(distinct opportunity_id) from sales_pipeline;

-- avg order value 
select round(avg(close_value), 2) from sales_pipeline;

-- avg deal stage date 
select round(avg(close_date - engage_date), 0) from sales_pipeline;

-- total accounts/customers
select count(distinct accounts) from accounts;

-- total sectors of accounts
select count(distinct sector) from accounts;

-- total products 
select count(distinct product) from products;


---------------------------------------------------------
-- 3. CUSTOMER ANALYSIS
---------------------------------------------------------

-- Top 10 accounts by revenue
select account, sum(revenue) as total_revenue from accounts
group by account
order by total_revenue desc
limit 10 ;

-- number of deals per customer
select account, count(opportunity_id) as total_orders from sales_pipeline
group by account
order by total_orders desc;

-- average deal size per customer
select account, round(avg(close_value), 2) as avg_deal_value from sales_pipeline
group by account
order by avg_deal_value desc;

-- total Won deal_stage
select count(deal_stage) from sales_pipeline
where deal_stage = 'Won';

-- total Lost deal stage
select count(deal_stage) from sales_pipeline
where deal_stage = 'Lost';

-- total Engaging deal stage
select count(deal_stage) from sales_pipeline
where deal_stage = 'Engaging';

-- total Prospecting deal stage 
select count(deal_stage) from sales_pipeline
where deal_stage = 'Prospecting';


---------------------------------------------------------
-- 4. CUSTOMER SEGMENTATION (VIP MODEL)
---------------------------------------------------------

-- segment customers into 4 groups based on revenue
with segmented_accounts as (
    select
        account,
        revenue,
        case ntile(4) over (order by revenue)
            when 1 then 'Low'
            when 2 then 'Medium'
            when 3 then 'High'
            when 4 then 'VIP'
        end as segment
    from accounts
)

select *
from segmented_accounts;

-- vip customers only
with segmented_accounts as (
    select
        account,
        revenue,
        case ntile(4) over (order by revenue)
            when 1 then 'low'
            when 2 then 'medium'
            when 3 then 'high'
            when 4 then 'vip'
        end as segment
    from accounts
)

select *
from segmented_accounts
where segment = 'vip';



---------------------------------------------------------
-- 5. PRODUCT ANALYSIS
---------------------------------------------------------

-- product demand
select product, count(opportunity_id) as total_units from sales_pipeline
group by product
order by total_units desc;

-- most sold product
select product, count(opportunity_id) as total_units from sales_pipeline
group by product
order by total_units desc
limit 1;

-- least sold product
select product, count(opportunity_id) as total_units from sales_pipeline
group by product
order by total_units asc
limit 1;

-- revenue by product
select product, sum(close_value) as total_revenue from sales_pipeline
group by product 
order by total_revenue desc;

-- highest revenue by product
select product, sum(close_value) as total_revenue from sales_pipeline
group by product 
order by total_revenue desc
limit 1;

-- lowest revenue by product 
select product, sum(close_value) as total_revenue from sales_pipeline
group by product 
order by total_revenue asc
limit 1;


---------------------------------------------------------
-- 6. REVENUE BY REGION / OFFICE
---------------------------------------------------------

-- revenue by office location
select office_location, sum(revenue) as total_revenue from accounts
group by office_location
order by total_revenue desc;

-- revenue by sector
select sector, sum(revenue) as total_revenue from accounts
group by sector
order by total_revenue desc;

-- revenue by regional office
select regional_office, sum(close_value) as total_revenue from sales_teams st
join sales_pipeline sp on sp.sales_agent = st.sales_agent
group by regional_office
order by total_revenue desc;

---------------------------------------------------------
-- 7. SALES TEAM PERFORMANCE
---------------------------------------------------------
-- revenue contribution by manager 
select manager, sum(close_value) as total_revenue from sales_teams st
join sales_pipeline sp on sp.sales_agent = st.sales_agent
group by manager
order by total_revenue desc;


---------------------------------------------------------
-- 8. TIME BASED ANALYSIS
---------------------------------------------------------

-- monthly sales trend
select to_char(close_date, 'mm') as month, sum(close_value) as monthly_revenue from sales_pipeline
group by month
order by month;

---------------------------------------------------------
-- 9. ADVANCED ANALYTICS (COMPARISON MODELS)
---------------------------------------------------------

-- state performance vs overall average
with state_sales as (
    select office_location, round(avg(close_value), 2) as avg_price from accounts a
    join sales_pipeline sp on a.account = sp.account
    group by office_location
)

select * from state_sales
where avg_price > (select avg(close_value) from sales_pipeline);

-- customer performance vs company average
with customer_sales as (
    select account, round(avg(revenue), 2) as avg_revenue from accounts
    group by account
)

select * from customer_sales
where avg_revenue > (select avg(revenue) from accounts);

---------------------------------------------------------
-- 10. RANKING ANALYSIS
---------------------------------------------------------
-- rank location by revenue
with rank_states as (
    select office_location, sum(revenue) as total_revenue from accounts
    group by office_location
)

select *, rank() over (order by total_revenue desc) as rank
from rank_states;

---------------------------------------------------------
-- END OF ANALYSIS
---------------------------------------------------------
