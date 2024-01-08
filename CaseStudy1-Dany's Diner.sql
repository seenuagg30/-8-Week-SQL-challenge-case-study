CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
SELECT * FROM members;
SELECT * FROM menu;
SELECT * FROM sales;

/* --------------------
   Case Study Questions
   --------------------*/

--1. What is the total amount each customer spent at the restaurant?
SELECT
	s.customer_id,
	sum(mn.price) 
from sales s 
left  join menu mn 
on s.product_id = mn.product_id 
group by s.customer_id;

-- 2. How many days has each customer visited the restaurant?
SELECT 
	customer_id, 
	COUNT(DISTINCT order_date) 
from sales 
group by customer_id ;

-- 3. What was the first item from the menu purchased by each customer?
With CTE As (
	SELECT 
		customer_id, 
		product_id, 
		order_date,
		rank() over(partition by customer_id order by order_date) as rw 
	from sales)
SELECT 
	c.customer_id,
	c.product_id, 
	m.product_name 
from cte c 
left join menu m 
on c.product_id=m.product_id 
where c.rw=1 ;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT top 1 
	product_id,
	count(product_id) as product_count 
from sales 
group by product_id 
order by product_count desc;

-- 5. Which item was the most popular for each customer?
with cte as (
	select 
		s.customer_id, 
		m.product_name, 
		count(s.order_date) as total_orders, 
		rank() over(partition by s.customer_id order by count(s.order_date) desc ) as rnk 
	from sales s 
	join menu m 
	on s.product_id= m.product_id 
	group by s.customer_id, m.product_name)
select 
	customer_id, 
	product_name 
from cte 
where rnk = 1;

-- 6. Which item was purchased first by the customer after they became a member?
with cte as(
	Select 
		s.customer_id,
		s.order_date ,
		s.product_id, 
		rank() over (partition by s.customer_id order by s.order_date) as rnk 
	from sales s 
	join members m 
	on s.customer_id=m.customer_id 
	where s.order_date>=m.join_date)
select 
	c.customer_id, 
	mn.product_name 
from cte c 
join menu mn 
on c.product_id=mn.product_id 
where rnk=1

-- 7. Which item was purchased just before the customer became a member?
With cte as(
	Select 
		s.customer_id,
		s.order_date ,
		s.product_id, 
		rank() over (partition by s.customer_id order by s.order_date desc) as rnk 
	from sales s 
	join members m 
	on s.customer_id=m.customer_id 
	where s.order_date<m.join_date)
select 
	c.customer_id,
	c.product_id, 
	mn.product_name 
from cte c 
join menu mn 
on c.product_id=mn.product_id 
where rnk =1

-- 8. What is the total items and amount spent for each member before they became a member?
with cte as(
	Select 
		s.customer_id,
		s.order_date ,
		s.product_id 
	from sales s 
	join members m 
	on s.customer_id=m.customer_id 
	where s.order_date<m.join_date)
select 
	c.customer_id, 
	count(c.order_date) as total_orders , 
	sum(mn.price) as amt_spent 
from cte c 
join menu mn 
on c.product_id=mn.product_id 
group by customer_id

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
with new_table as(
	SELECT 
		s.customer_id, 
		s.order_date, 
		m.product_name, 
		m.price, 
		case when product_name = 'sushi' then 2*price else price end as newprice 
	from sales s 
	join menu m 
	on s.product_id=m.product_id)
select 
	customer_id, 
	sum(newprice)*10 
from new_table 
group by customer_id

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
with new_table as(
	SELECT 
		s.customer_id, 
		s.order_date, 
		m.product_name, 
		m.price, 
		case when product_name = 'sushi' then 2*price 
		when order_date between a.join_date and (a.join_date+ interval 6 day) then 2*price
		else price end as newprice 
	from sales s 
	join menu m 
	on s.product_id=m.product_id
	join members a
	on s.customer_id=a.customer_id
	where order_date <=2021-01-31)
select 
	customer_id, 
	sum(newprice)*10 
from new_table 
group by customer_id

--11. Join All The Things 
SELECT 
	s.customer_id,
	s.order_date, 
	mn.product_name, 
	mn.price, 
	CASE WHEN order_date < join_date then 'n'
	when order_date>= join_date then 'y'
	else 'n'
	end as member
from sales s
join menu mn 
on s.product_id=mn.product_id
left join members mm
on s.customer_id = mm.customer_id

--12.Rank All The Things 
WITH rank_table as (
	SELECT 
		s.customer_id,
		s.order_date, 
		mn.product_name, 
		mn.price, 
		CASE WHEN order_date < join_date then 'n'
		when order_date>= join_date then 'y'
		else 'n'
		end as member
	from sales s
	join menu mn 
	on s.product_id=mn.product_id
	left join members mm
	on s.customer_id = mm.customer_id)
SELECT 
	*, 
	case when member ='n' then NULL
	else  rank() over(partition by customer_id,member order by order_date)
	end as ranking
	from rank_table

