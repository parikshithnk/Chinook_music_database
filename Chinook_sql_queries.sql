-- objective questions  
-- 1. Does any table have missing values or duplicates? If yes how would you handle it?
select * from customer
where company is Null or address is null or city is null 
or state is null or country is null or postal_code is  null
or phone is null or email is null or support_rep_id is null;

-- 2. Find the top-selling tracks and top artist in the USA and identify their most famous genres
with topselling_track as (select track_id, sum(unit_price * quantity) as tot_sold_amt 
from invoice_line il join invoice i on il.invoice_id = i.invoice_id
where billing_country = 'USA'
group by track_id)

select t.name as track_name, tot_sold_amt, a.name as artisit_name, g.name as genre_name
from topselling_track tst join track t on t.track_id = tst.track_id
join album al on al.album_id = t.album_id
join artist a on a.artist_id = al.artist_id
join genre g on g.genre_id = t.genre_id
order by tot_sold_amt desc;

-- 3. What is the customer demographic breakdown (age, gender, location) of Chinook's customer base?
-- Age wise ditribution of employees in chinook
select age_bracket, count(employee_id) as no_of_employees 
from (select employee_id, 
case
	when timestampdiff(year, birthdate, now()) < 50 then "Under 50"
	when timestampdiff(year, birthdate, now()) between 50 and 60 then "50-60"
    when timestampdiff(year, birthdate, now()) between 60 and 70 then "60-70"
    when timestampdiff(year, birthdate, now()) > 70 then "Above 70"
end as age_bracket
from employee) as res
group by age_bracket
order by no_of_employees desc;

-- Location wise distribution of employees in chinook
select country, state, city, count(employee_id) as no_of_employees
from employee group by country, state, city
order by no_of_employees desc;

-- location wise distribution of customers in chinook
select country, count(customer_id) as no_of_customers 
from customer group by country order by no_of_customers desc;

-- 4. Calculate the total revenue and number of invoices for each country, state, and city:
-- Country wise revenue and number of invoices
select billing_country, sum(total) as tot_revenue, count(invoice_id) as no_of_invoices  
from invoice group by billing_country
order by tot_revenue desc;

-- State wise revenue and number of invoices
select billing_state, sum(total) as tot_revenue, count(invoice_id) as no_of_invoices  
from invoice 
where billing_state != 'None'
group by billing_state
order by tot_revenue desc;

-- City wise revenue and number of invoices
select billing_city, sum(total) as tot_revenue, count(invoice_id) as no_of_invoices  
from invoice group by billing_city
order by tot_revenue desc;

-- 5. Find the top 5 customers by total revenue in each country

with table1 as (select billing_country, customer_id, sum(total) as tot_revenue,
rank() over(partition by billing_country order by sum(total) desc) as rnk
from invoice group by billing_country, customer_id
order by billing_country, tot_revenue desc)

select t1.billing_country, concat(c.first_name,' ',c.last_name) as Customer_name, tot_revenue
from table1 t1 join customer c on c.customer_id = t1.customer_id
where rnk <= 5;

-- 6. Identify the top-selling track for each customer

select customer_id, track_id, unit_price, quantity
from invoice i join invoice_line il on il.invoice_id = i.invoice_id
order by customer_id, track_id;

-- 7. Are there any patterns or trends in customer purchasing behaviour 
-- (e.g., frequency of purchases, preferred payment methods, average order value)?

-- Customer patterns by avg order value per customer
with ord_value as (select customer_id, avg(total) as avg_ord_value
from invoice
group by customer_id
order by customer_id)

-- select * from ord_value;

select 
min(avg_ord_value) as Min_avg_ord_value,
max(avg_ord_value) as max_avg_ord_value,
avg(avg_ord_value) as overall_avg_ord_value
from ord_value;

-- Customers pattern by time of orders
with prev_date as (select 
customer_id,
invoice_date,
lag(invoice_date) over(partition by customer_id order by invoice_date) as previous_date
from invoice),

mpo as (select customer_id,
avg(coalesce(timestampdiff(month,previous_date, invoice_date),0)) as months_per_one_order
from prev_date
group by customer_id)
-- select * from mpo;
select avg(months_per_one_order) as overallmonths_per_one_order_by_eachcustomer from mpo;


-- 8. What is the customer churn rate?
-- Year on year churn rate:
with yearwisedata as (select extract(year from invoice_date) as Year,
count(distinct customer_id) as num_of_customers
from invoice
group by extract(year from invoice_date))

select *, 
(lag(num_of_customers) over(order by year) - num_of_customers) / 
(lag(num_of_customers) over(order by year)) * 100 as yearwise_Churn_rate
from yearwisedata;

-- 9. Calculate the percentage of total sales contributed by 
-- each genre in the USA and identify the best-selling genres and artists.

with usasales as (select * from invoice
where billing_country = 'USA'),

usa_genre_sales as (select g.name as genre_name, sum(il.unit_price * quantity) as tot_genre_sales
from usasales u join invoice_line il on il.invoice_id = u.invoice_id
join track t on t.track_id = il.track_id
join genre g on g.genre_id = t.genre_id
group by g.name)

select genre_name, 
(tot_genre_sales / (select sum(total) from invoice)) * 100 as 'contribution_ to_tot_sales'
from usa_genre_sales;

