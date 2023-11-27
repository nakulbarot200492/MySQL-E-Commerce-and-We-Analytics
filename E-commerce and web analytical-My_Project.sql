use mavenfuzzyfactory;
select 
	ws.utm_content,
	count(distinct ws.website_session_id) as session,
    count(distinct ords.order_id) as orders,
    count(distinct ords.order_id)/count(distinct ws.website_session_id) as session_to_order_conv_rt
from website_sessions ws
left join
	orders ords
    on ws.website_session_id=ords.website_session_id
    
where ws.website_session_id between 1000 and 2000
group by 1
order by 2 desc;



select
	utm_source,
    utm_campaign,
    http_referer,
    count(distinct website_session_id) as sessions
from website_sessions
where created_at < '2012-04-12'
group by 1,2,3
order by 4 desc;


select 
	count(distinct ws.website_session_id) as sessions,
    count(distinct o.order_id) as orders,
    count(distinct o.order_id) /count(distinct ws.website_session_id) as session_to_order_conv_rt
from website_sessions ws
left join orders o
ON ws.website_session_id=o.website_session_id
where ws.created_at < '2012-04-12' and utm_source = 'gsearch' and utm_campaign= 'nonbrand';


select
year(created_at),
week(created_at),
min(date(created_at)) week_start,
max(date(created_at)) week_end,
count(distinct website_session_id) as sessions
from website_sessions
where website_session_id between 100000 and 115000
group by 1,2;

-- Pivoting in SQL(using count-case) 

select 
primary_product_id,
count(distinct case when items_purchased=1 then order_id else NULL end) as orders_w1_items,
count(distinct case when items_purchased=2 then order_id else NULL end) as orders_w2_items,
count(distinct order_id) as total_orders
from orders
where order_id between 31000 and 32000
group by 1;


select
-- year(created_at) as year,
-- week(created_at) as week,
min(date(created_at))as week_stared,
count(distinct website_session_id) as session_count
from website_sessions
where created_at < '2012-05-10'
and utm_source = 'gsearch'
and utm_campaign = 'nonbrand'
group by 
year(created_at),
week(created_at);


select
	ws.device_type,
    count(distinct ws.website_session_id) as session_count,
    count(distinct o.order_id) as order_count,
    count(distinct o.order_id)/count(distinct ws.website_session_id) as session_to_order_conv_rt
from website_sessions ws
LEFT JOIN orders o
ON ws.website_session_id=o.website_session_id
where ws.created_at < '2012-05-11'
and utm_source = 'gsearch'
and utm_campaign = 'nonbrand'
group by 1;


select
		min(date(created_at)) as week_start_date,
        count(case when device_type = 'desktop' then device_type else NULL end) as dtop_session,
        count(case when device_type = 'mobile' then device_type else NULL end) as mob_session
from website_sessions
where created_at >'2012-04-15'
and created_at < '2012-06-09'
and utm_source = 'gsearch' and utm_campaign = 'nonbrand'
group by 
year(created_at),
week(created_at);


-- Analyzing website Performance

select
	pageview_url,
    count(distinct website_pageview_id) as pvs
from website_pageviews
where website_pageview_id < 1000 -- arbitrary
group by 1
order by 2 desc;    

create temporary table first_pageview
select 
	website_session_id,
    MIN(website_pageview_id) as min_pv_id
from website_pageviews
where website_pageview_id < 1000
group by 1;

select 
website_pageviews.pageview_url as landing_page, -- aka "entry page" 
count( distinct first_pageview.website_session_id) as session_hitting_this_lender
from first_pageview
left join website_pageviews
ON first_pageview.min_pv_id = website_pageviews.website_pageview_id
group by 1;



-- Finding Top website pages ( Till 09-6-2012)

select
	pageview_url,
    count(distinct website_pageview_id) as pvs
from website_pageviews
where created_at < '2012-06-09'
group by 1
order by 2 desc; 


-- Top entry pages (till 2012-06-12) for first page view each session
-- Step 1: Find the first page view for each session.
-- Step 2: Find the url the customer saw on that first page view.

create temporary table first_pv_per_session
select 
	website_session_id,
    min(website_pageview_id) as first_pageview
from website_pageviews
where created_at < '2012-06-12'
group by 1;


select 
	website_pageviews.pageview_url as landing_page_url,
    count(distinct first_pv_per_session.website_session_id ) as session_hitting_page
from first_pv_per_session
	left join website_pageviews
		ON  first_pv_per_session.first_pageview = website_pageviews.website_pageview_id
        group by 1;
        
        
-- BUSINESS CONTEXT:we want to see landing page performance for a certain time period.
-- Step 1: find the first website_pageview_id for relevant session.
-- Step 2: Identify the landing page of each session.
-- Step 3: counting pafeviews for each session, to identify "bounces".
-- Step 4: summarizing total session and bounces session , by landing pages

-- finding the minimum website pageview id associated with each session we care about.

select
	wpv.website_session_id,
    min(wpv.website_pageview_id) as min_pageview_id
from website_pageviews wpv
	INNER JOIN website_sessions ws
		ON wpv.website_session_id = ws.website_session_id
        AND ws.created_at between '2014-01-01' and '2014-02-01'
group by 1;

-- same query store in temporary table

create temporary table first_pageviews_demo
select
	wpv.website_session_id,
    min(wpv.website_pageview_id) as min_pageview_id
from website_pageviews wpv
	INNER JOIN website_sessions ws
		ON wpv.website_session_id = ws.website_session_id
        AND ws.created_at between '2014-01-01' and '2014-02-01'
group by 1;     

select * from first_pageviews_demo;

-- next , w'll bring in the landing page to each session.
CREATE TEMPORARY TABLE sessions_w_landing_page_demo
select
	first_pageviews_demo.website_session_id,
    website_pageviews.pageview_url as landing_page
from first_pageviews_demo
	LEFT JOIN website_pageviews
		ON website_pageviews.website_pageview_id = first_pageviews_demo.min_pageview_id;
        
select * from sessions_w_landing_page_demo;        

-- next, we make a table to indclude a count of pageview per session.
CREATE TEMPORARY TABLE bounced_sessions_only
select
	sessions_w_landing_page_demo.website_session_id,
    sessions_w_landing_page_demo.landing_page,
    count(website_pageviews.website_pageview_id) as count_of_page_viewed
from sessions_w_landing_page_demo
	LEFT JOIN website_pageviews
		ON website_pageviews.website_session_id = sessions_w_landing_page_demo.website_session_id
group by 1,2
having count_of_page_viewed=1;     -- for bounced sessions. 

select * from bounced_sessions_only;

select
	sessions_w_landing_page_demo.landing_page,
    count(distinct sessions_w_landing_page_demo.website_session_id) as sessions,
    count(distinct bounced_sessions_only.website_session_id) as bounced_session,
	count(distinct bounced_sessions_only.website_session_id)/count(distinct sessions_w_landing_page_demo.website_session_id) as bounce_rate
from sessions_w_landing_page_demo
	LEFT JOIN bounced_sessions_only
		ON sessions_w_landing_page_demo.website_session_id = bounced_sessions_only.website_session_id
GROUP BY 1;

create temporary table new_bounced
select
	website_session_id,
    count(website_pageview_id) as pageview_count
from website_pageviews
group by 1
having pageview_count = 1;
    

select * from new_bounced;

-- Step 2: calculate bounce rate:

SELECT
	count(website_sessions.website_session_id) as sessions,
	count(new_bounced.website_session_id) as bounced_sessions,
    count(new_bounced.website_session_id)/count(website_sessions.website_session_id) as bounce_rate
from website_sessions
	LEFT JOIN new_bounced
		ON new_bounced.website_session_id = website_sessions.website_session_id
        where created_at < '2012-06-14';

-- Analyzing landing page test ('/lander-1' and '/home')
-- Step 0: find out when new page(lander-1) is launched
select
	min(created_at) as first_created_at,
    min(website_pageview_id) as first_pageview_id
from website_pageviews
where pageview_url = '/lander-1'
and created_at IS NOT NULL; -- new lander-1 page is first created_at '2012-06-19' & pageview_id '23504'


-- Step 2:finding first website_pageview_id for relevant session.
CREATE TEMPORARY TABLE first_test_pageviews
select 
	website_pageviews.website_session_id,
    min(website_pageviews.website_pageview_id) as min_pageview_id
from  website_pageviews
	INNER JOIN website_sessions
		ON website_pageviews.website_session_id = website_sessions.website_session_id
        AND website_sessions.created_at < '2012-07-28' -- prescribed by assignment
        AND website_pageviews.website_pageview_id > '23504'
        AND utm_source = 'gsearch'
        AND utm_campaign = 'nonbrand' -- as per assignment
group by 1;       

select * from first_test_pageviews;


-- Step:3 identifying the landing page for each session.
CREATE TEMPORARY TABLE nonbrand_test_sessions_w_landing_page
select 
first_test_pageviews.website_session_id,
website_pageviews.pageview_url as landing_page
from first_test_pageviews
	LEFT JOIN website_pageviews
		ON first_test_pageviews.min_pageview_id = website_pageviews.website_pageview_id
where website_pageviews.pageview_url IN ('/home','/lander-1');

select * from nonbrand_test_sessions_w_landing_page;


-- Step 4:counting pageview for each session, then limit it to just bounced sessions.

CREATE TEMPORARY TABLE nonbrand_test_bounced_sessions
select
	nonbrand_test_sessions_w_landing_page.website_session_id,
    nonbrand_test_sessions_w_landing_page.landing_page,
    count(distinct website_pageviews.website_pageview_id) as count_pageview
from nonbrand_test_sessions_w_landing_page
	LEFT JOIN website_pageviews
		ON nonbrand_test_sessions_w_landing_page.website_session_id = website_pageviews.website_session_id
group by 1,2
having count(distinct website_pageviews.website_pageview_id) = 1;

select * from nonbrand_test_bounced_sessions;


-- Step 5: summarizing total session, bounced session.

select
	nonbrand_test_sessions_w_landing_page.landing_page,
	count(distinct nonbrand_test_sessions_w_landing_page.website_session_id) AS sessions,
    count(distinct nonbrand_test_bounced_sessions.website_session_id) AS bounced_sessions,
    count(distinct nonbrand_test_bounced_sessions.website_session_id)/count(distinct nonbrand_test_sessions_w_landing_page.website_session_id) as bounce_rate
from nonbrand_test_sessions_w_landing_page
	LEFT JOIN nonbrand_test_bounced_sessions
		ON nonbrand_test_bounced_sessions.website_session_id=nonbrand_test_sessions_w_landing_page.website_session_id
GROUP BY 1;        


-- landing page trend analysis 

-- Step 1: finding the first website_pageview_id for relevant session.
CREATE TEMPORARY TABLE session_w_min_pv_id_and_view_count
select
	website_sessions.website_session_id,
	min(website_pageviews.website_pageview_id) as first_pageview_id,
    count(distinct website_pageviews.website_pageview_id) as count_pageviews
from website_sessions
	LEFT JOIN website_pageviews
		ON website_sessions.website_session_id=website_pageviews.website_session_id
where website_sessions.created_at > '2012-06-01'  -- asked by requestor
  AND website_sessions.created_at < '2012-08-31'  -- prescribed by assignment
  AND website_sessions.utm_source = 'gsearch'
  AND website_sessions.utm_campaign='nonbrand'
group by 1;

select * from session_w_min_pv_id_and_view_count;

-- Step 2: identifying the landinf page of each session and counting pageview of each sessions.
CREATE TEMPORARY TABLE sessions_w_counts_lander_and_created_at
select 
	session_w_min_pv_id_and_view_count.website_session_id,
    session_w_min_pv_id_and_view_count.first_pageview_id,
    session_w_min_pv_id_and_view_count.count_pageviews,
    website_pageviews.pageview_url AS landing_page,
    website_pageviews.created_at AS session_created_at
from session_w_min_pv_id_and_view_count
	LEFT JOIN website_pageviews
		ON session_w_min_pv_id_and_view_count.first_pageview_id=website_pageviews.website_pageview_id;
        
        
select * from sessions_w_counts_lander_and_created_at;
-- Step 4: summarizing by week (bounce_rate, session to each lander)
select 
	min(date(session_created_at)) AS week_start_date,
	count(distinct website_session_id) AS total_sessions,
    count(distinct case when count_pageviews = 1 then website_session_id else NULL end) bounced_session,
    count(distinct case when count_pageviews = 1 then website_session_id else NULL end) /count(distinct website_session_id) AS bounced_rate,
    count(distinct case when landing_page = '/home' then website_session_id else NULL end) AS home_sessions,
    count(distinct case when landing_page = '/lander-1' then website_session_id else NULL end)AS lander_sessions
from sessions_w_counts_lander_and_created_at
group by yearweek(session_created_at);



-- Analyzing and testing conversion funnel (using subqueries)
-- Business Context:
-- we want to build mini conversion funnel, from /lander-2 to /cart.
-- we want to know how many people reach each step, also dropoff rates.
-- for simplicity of the demo, we're looking at /lander-2 traffic only.
-- for simplicity of the demo, we're looking at customers who like Mr fuzzy only

-- Step 1: select all pageviews for relevant sessions.
-- Step 2: identify each relevant pageview as the specific funnel step.
-- Step 3: create the session level conversion funnel view.
-- Step 4: aggredate the data to access funnel level.

select
	website_sessions.website_session_id,
    website_pageviews.pageview_url,
    website_pageviews.created_at,
    CASE WHEN pageview_url = '/products' THEN 1 ELSE 0 END AS product_page,
    CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS mrfuzzy_page,
    CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page
from website_sessions
	LEFT JOIN website_pageviews
		ON website_sessions.website_session_id=website_pageviews.website_session_id
WHERE website_sessions.created_at BETWEEN '2014-01-01' AND '2014-02-01' -- just random time frame
	AND website_pageviews.pageview_url IN ('/lander-2','/products','/the-original-mr-fuzzy','/cart')
    ORDER BY 1,3;
    
-- Next we will put the previous query into sub-query(same as temporary table).
-- we will group by website_session_id and take the MAX() of each flag.
-- this MAX() becomes a made_it flag for that sessions, to show the sessions made it there.


SELECT
website_session_id,
MAX(product_page) AS product_made_it,
MAX(mrfuzzy_page) AS mrfuzzy_made_it,
MAX(cart_page) AS cart_made_it
FROM
(select
	website_sessions.website_session_id,
    website_pageviews.pageview_url,
    website_pageviews.created_at,
    CASE WHEN pageview_url = '/products' THEN 1 ELSE 0 END AS product_page,
    CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS mrfuzzy_page,
    CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page
from website_sessions
	LEFT JOIN website_pageviews
		ON website_sessions.website_session_id=website_pageviews.website_session_id
WHERE website_sessions.created_at BETWEEN '2014-01-01' AND '2014-02-01' -- just random time frame
	AND website_pageviews.pageview_url IN ('/lander-2','/products','/the-original-mr-fuzzy','/cart')
    ORDER BY 1,3) AS pageview_level
    GROUP BY website_session_id;
    
   --  DROP temporary table session_level_made_it_flag_demo;
    -- now we will create temporary table.
CREATE TEMPORARY TABLE session_level_made_it_flag_demo
SELECT
website_session_id,
MAX(product_page) AS product_made_it,
MAX(mrfuzzy_page) AS mrfuzzy_made_it,
MAX(cart_page) AS cart_made_it
FROM
(select
	website_sessions.website_session_id,
    website_pageviews.pageview_url,
    website_pageviews.created_at,
    CASE WHEN pageview_url = '/products' THEN 1 ELSE 0 END AS product_page,
    CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS mrfuzzy_page,
    CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page
from website_sessions
	LEFT JOIN website_pageviews
		ON website_sessions.website_session_id=website_pageviews.website_session_id
WHERE website_sessions.created_at BETWEEN '2014-01-01' AND '2014-02-01' -- just random time frame
	AND website_pageviews.pageview_url IN ('/lander-2','/products','/the-original-mr-fuzzy','/cart')
    ORDER BY 1,3) AS pageview_level
    GROUP BY website_session_id;    
    
select * from session_level_made_it_flag_demo;

-- this would produce final output.

SELECT
	COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT CASE WHEN product_made_it = 1 THEN website_session_id ELSE NULL END) AS to_products,
    COUNT(DISTINCT CASE WHEN mrfuzzy_made_it = 1 THEN website_session_id ELSE NULL END) AS to_mrfuzzy,
    COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END) AS to_cart
FROM session_level_made_it_flag_demo;    


-- now we translate this into click_rate

SELECT
	COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT CASE WHEN product_made_it = 1 THEN website_session_id ELSE NULL END)
		/COUNT(DISTINCT website_session_id) AS clicked_to_products_OR_lander_clickthrough_rate,
    COUNT(DISTINCT CASE WHEN mrfuzzy_made_it = 1 THEN website_session_id ELSE NULL END)
		/COUNT(DISTINCT CASE WHEN product_made_it = 1 THEN website_session_id ELSE NULL END) AS clicked_to_mrfuzzy_OR_product_clickthrough_rate,
    COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END)
		/COUNT(DISTINCT CASE WHEN mrfuzzy_made_it = 1 THEN website_session_id ELSE NULL END) AS clicked_to_cart_OR_mrfuzzy_clickthrough_rate
FROM session_level_made_it_flag_demo;  



-- 
select * from website_pageviews where website_session_id=1059;


select
	website_session_id,
	MAX(product_page) AS to_product,
    MAX(mrfuzzy_page) AS to_mrfuzzy,
    MAX(cart_page) AS to_cart,
    MAX(shipping_page) AS to_shipping,
    MAX(billing_page) AS to_billing,
    MAX(thank_you_page) AS to_thank_you
FROM
(select  
	website_sessions.website_session_id,
    website_pageviews.pageview_url,
    CASE WHEN pageview_url = '/products' THEN 1 ELSE 0 END AS product_page,
    CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS mrfuzzy_page,
    CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page,
    CASE WHEN pageview_url =  '/shipping' THEN 1 ELSE 0 END AS shipping_page,
    CASE WHEN pageview_url = '/billing' THEN 1 ELSE 0 END AS billing_page,
    CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thank_you_page
from website_sessions
	LEFT JOIN website_pageviews
		ON website_sessions.website_session_id=website_pageviews.website_session_id
where 		website_sessions.utm_source ='gsearch'
		AND website_sessions.utm_campaign='nonbrand'
		AND	website_sessions.created_at > '2012-08-05'
		AND  website_sessions.created_at < '2012-09-05'
        AND website_pageviews.pageview_url IN ('/products','/the-original-mr-fuzzy','/cart',
        '/shipping','/billing','/thank-you-for-your-order')
ORDER BY 1,2) AS pageview_level
GROUP BY website_session_id; 



CREATE TEMPORARY TABLE session_level_made_it_flag

 select
	website_session_id,
	MAX(product_page) AS to_product,
    MAX(mrfuzzy_page) AS to_mrfuzzy,
    MAX(cart_page) AS to_cart,
    MAX(shipping_page) AS to_shipping,
    MAX(billing_page) AS to_billing,
    MAX(thank_you_page) AS to_thank_you
FROM
(select  
	website_sessions.website_session_id,
    website_pageviews.pageview_url,
    CASE WHEN pageview_url = '/products' THEN 1 ELSE 0 END AS product_page,
    CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS mrfuzzy_page,
    CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page,
    CASE WHEN pageview_url =  '/shipping' THEN 1 ELSE 0 END AS shipping_page,
    CASE WHEN pageview_url = '/billing' THEN 1 ELSE 0 END AS billing_page,
    CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thank_you_page
from website_sessions
	LEFT JOIN website_pageviews
		ON website_sessions.website_session_id=website_pageviews.website_session_id
where 		website_sessions.utm_source ='gsearch'
		AND website_sessions.utm_campaign='nonbrand'
		AND	website_sessions.created_at > '2012-08-05'
		AND  website_sessions.created_at < '2012-09-05'
        AND website_pageviews.pageview_url IN ('/products','/the-original-mr-fuzzy','/cart',
        '/shipping','/billing','/thank-you-for-your-order')
ORDER BY 1,2) AS pageview_level
GROUP BY website_session_id;


select * from session_level_made_it_flag;

select
	count(distinct website_session_id) AS sessions,
    count(DISTINCT CASE WHEN to_product=1 THEN website_session_id ELSE NULL END) AS to_product,
    count(DISTINCT CASE WHEN to_mrfuzzy=1 THEN website_session_id ELSE NULL END) AS to_mrfuzzy,
    count(DISTINCT CASE WHEN to_cart=1 THEN website_session_id ELSE NULL END) AS to_cart,
    count(DISTINCT CASE WHEN to_shipping=1 THEN website_session_id ELSE NULL END) AS to_shipping,
    count(DISTINCT CASE WHEN to_billing=1 THEN website_session_id ELSE NULL END) AS to_billing,
    count(DISTINCT CASE WHEN to_thank_you=1 THEN website_session_id ELSE NULL END) AS to_thank_you
From session_level_made_it_flag;

-- getting click_rate

select
	
    count(DISTINCT CASE WHEN to_product=1 THEN website_session_id ELSE NULL END)
		/count(distinct website_session_id) lander_click_rt,
    count(DISTINCT CASE WHEN to_mrfuzzy=1 THEN website_session_id ELSE NULL END)
		/ count(DISTINCT CASE WHEN to_product=1 THEN website_session_id ELSE NULL END) product_click_rt,
    count(DISTINCT CASE WHEN to_cart=1 THEN website_session_id ELSE NULL END)
		/ count(DISTINCT CASE WHEN to_mrfuzzy=1 THEN website_session_id ELSE NULL END) mrfuzzy_click_rt,
    count(DISTINCT CASE WHEN to_shipping=1 THEN website_session_id ELSE NULL END)
		/ count(DISTINCT CASE WHEN to_cart=1 THEN website_session_id ELSE NULL END) cart_click_rt,
    count(DISTINCT CASE WHEN to_billing=1 THEN website_session_id ELSE NULL END)
		/ count(DISTINCT CASE WHEN to_shipping=1 THEN website_session_id ELSE NULL END) shipping_click_rt,
    count(DISTINCT CASE WHEN to_thank_you=1 THEN website_session_id ELSE NULL END)
		/ count(DISTINCT CASE WHEN to_billing=1 THEN website_session_id ELSE NULL END) billing_click_rt
From session_level_made_it_flag;    

-- billing-2 page introduced, comaprasion b/w billing, billing-2.
-- first finding when billing-2 introduced

select
	MIN(website_pageviews.website_pageview_id) AS first_pv_id
from website_pageviews
where pageview_url = '/billing-2';     -- note after this query result-- fisrt_pv_id= 53550


-- now getting billing version

select 
	website_pageviews.website_session_id,
    website_pageviews.pageview_url as billing_version_seen,
    orders.order_id
FROM website_pageviews
	LEFT JOIN orders
		ON website_pageviews.website_session_id=orders.website_session_id
where website_pageviews.website_pageview_id >= 53550
	AND website_pageviews.created_at < '2012-11-10'
	AND website_pageviews.pageview_url IN ('/billing','/billing-2');
    
    
 -- just raping above query into subquery and summarizing total order, total session and cnv_rate
 
SELECT
	billing_version_seen,
    count(distinct website_session_id) AS sessions,
    count(distinct order_id) As orders,
    count(distinct order_id)/count(distinct website_session_id) AS billing_to_order_rt
FROM    
(select 
	website_pageviews.website_session_id,
    website_pageviews.pageview_url as billing_version_seen,
    orders.order_id
FROM website_pageviews
	LEFT JOIN orders
		ON website_pageviews.website_session_id=orders.website_session_id
where website_pageviews.website_pageview_id >= 53550
	AND website_pageviews.created_at < '2012-11-10'
	AND website_pageviews.pageview_url IN ('/billing','/billing-2')
    ) AS billing_session_w_orders
    GROUP BY billing_version_seen;
    
    
-- Channel portfolio optimization.

SELECT
	utm_content,
    count(distinct website_sessions.website_session_id) as sessions,
    count(distinct orders.order_id) as orders,
    count(distinct orders.order_id)/count(distinct website_sessions.website_session_id) as sessions_to_order_cnv_rt
FROM website_sessions
	LEFT JOIN orders
		ON website_sessions.website_session_id=orders.website_session_id
WHERE website_sessions.created_at BETWEEN '2014-01-01' AND '2014-02-01'        
GROUP BY 1;        


select
	min(date(website_sessions.created_at)) as week_start_date,
	count(distinct case when utm_source='gsearch' then website_sessions.website_session_id else null end)as gsearch_sessions,
    count(distinct case when utm_source='bsearch' then website_sessions.website_session_id else null end)as bsearch_sessions
from website_sessions
WHERE website_sessions.created_at < '2012-11-29'   -- as per assignment
	AND website_sessions.created_at > '2012-08-22' -- as per assignment
	AND utm_campaign='nonbrand'
GROUP BY yearweek(created_at);

-- Comparing channel stats.

SELECT
	utm_source,
    count(distinct website_session_id) as sessions,
    count(distinct case when device_type ='mobile' then website_session_id else null end)as mobile_sessions,
    count(distinct case when device_type ='mobile' then website_session_id else null end)/ count(distinct website_session_id) as pct_mobile
FROM website_sessions
	WHERE created_at > '2012-08-22'
		AND created_at < '2012-11-30'
        AND utm_campaign='nonbrand'
GROUP BY 1;

-- Multi channel bidding.

SELECT
	website_sessions.device_type,
    website_sessions.utm_source,
    count(distinct website_sessions.website_session_id) as sessions,
    count(distinct orders.order_id) as orders,
    count(distinct orders.order_id)/ count(distinct website_sessions.website_session_id) as cnv_rt
FROM website_sessions
	LEFT JOIN orders
		ON website_sessions.website_session_id=orders.website_session_id
WHERE website_sessions.created_at > '2012-08-22'
	AND website_sessions.created_at < '2012-09-19'
    AND utm_campaign='nonbrand'
GROUP BY 1,2;    


-- Impact of Bid Changes.

SELECT
	MIN(date(created_at)) as week_start_date,
    count(distinct case when device_type='desktop' and utm_source='gsearch' then website_session_id else null end) as g_dtop_sessions,
    count(distinct case when device_type='desktop' and utm_source='bsearch' then website_session_id else null end) as b_dtop_sessions,
    count(distinct case when device_type='desktop' and utm_source='bsearch' then website_session_id else null end)
		/count(distinct case when device_type='desktop' and utm_source='gsearch' then website_session_id else null end) as b_pct_of_g_dtop,
    count(distinct case when device_type='mobile' and utm_source='gsearch' then website_session_id else null end) as g_mobile_sessions,
    count(distinct case when device_type='mobile' and utm_source='bsearch' then website_session_id else null end) as b_mobile_sessions,
    count(distinct case when device_type='mobile' and utm_source='bsearch' then website_session_id else null end)
		/count(distinct case when device_type='mobile' and utm_source='gsearch' then website_session_id else null end) as b_pct_of_g_mob
FROM website_sessions
WHERE created_at > '2012-11-04'
	AND created_at < '2012-12-22'
    AND utm_campaign='nonbrand'
GROUP BY yearweek(created_at);


-- Analyzing direct, brand driven traffic.
select 
	CASE
		WHEN http_referer IS NULL THEN 'direct_type_in'
        WHEN http_referer = 'https://www.gsearch.com' THEN 'gsearch_organic'
        WHEN http_referer = 'https://www.bsearch.com' THEN 'bsearch_organic'
    ELSE 'others'
END AS 'case',
	count(website_session_id) as sessions
FROM website_sessions
WHERE website_session_id BETWEEN 100000 AND 115000
	AND utm_source IS NULL

GROUP BY 1
ORDER BY 2 desc;


select 
	CASE
		WHEN http_referer IS NULL THEN 'direct_type_in'
        WHEN http_referer = 'https://www.gsearch.com' AND utm_source IS NULL THEN 'gsearch_organic'
        WHEN http_referer = 'https://www.bsearch.com' AND utm_source IS NULL THEN 'bsearch_organic'
    ELSE 'others'
END AS 'case',
	count(website_session_id) as sessions
FROM website_sessions
WHERE website_session_id BETWEEN 100000 AND 115000
-- AND utm_source IS NULL

GROUP BY 1
ORDER BY 2 desc;



-- Analyzing direct traffic.

SELECT distinct
	utm_source,
    utm_campaign,
    http_referer
FROM website_sessions
WHERE created_at < '2012-12-23';


SELECT distinct
	CASE 
		WHEN utm_source IS NULL and http_referer IN ('https://www.gsearch.com', 'https://www.bsearch.com') THEN 'organic_search'
        WHEN utm_campaign = 'nonbrand' THEN 'paid_nonbrand'
        WHEN utm_campaign = 'brand' THEN 'paid_brand'
        WHEN utm_source IS NULL and http_referer IS NULL THEN 'direct_type_in'
        END AS channel_group,
	utm_source,
    utm_campaign,
    http_referer
FROM website_sessions
WHERE created_at < '2012-12-23';    


SELECT 
	website_session_id,
    created_at,
	CASE 
		WHEN utm_source IS NULL and http_referer IN ('https://www.gsearch.com', 'https://www.bsearch.com') THEN 'organic_search'
        WHEN utm_campaign = 'nonbrand' THEN 'paid_nonbrand'
        WHEN utm_campaign = 'brand' THEN 'paid_brand'
        WHEN utm_source IS NULL and http_referer IS NULL THEN 'direct_type_in'
        END AS channel_group,
	utm_source,
    utm_campaign,
    http_referer
FROM website_sessions
WHERE created_at < '2012-12-23'; 



SELECT
	YEAR(created_at) as yr,
    MONTH(created_at) as mo,
    count(distinct case when channel_group='paid_nonbrand' then website_session_id else null end)as nonbrand,
    count(distinct case when channel_group='paid_brand' then website_session_id else null end)as brand,
        count(distinct case when channel_group='paid_brand' then website_session_id else null end)
        /count(distinct case when channel_group='paid_nonbrand' then website_session_id else null end) as brnd_pct_of_nonbrand,
    count(distinct case when channel_group='direct_type_in' then website_session_id else null end) as direct,
	count(distinct case when channel_group='direct_type_in' then website_session_id else null end)
		/count(distinct case when channel_group='paid_nonbrand' then website_session_id else null end)as direct_pct_of_nonbrand,
	count(distinct case when channel_group='organic_search' then website_session_id else null end) as organic,
	count(distinct case when channel_group='organic_search' then website_session_id else null end)
    /count(distinct case when channel_group='paid_nonbrand' then website_session_id else null end)as organic_pct_of_nonbrand
    FROM (SELECT 
	website_session_id,
    created_at,
	CASE 
		WHEN utm_source IS NULL and http_referer IN ('https://www.gsearch.com', 'https://www.bsearch.com') THEN 'organic_search'
        WHEN utm_campaign = 'nonbrand' THEN 'paid_nonbrand'
        WHEN utm_campaign = 'brand' THEN 'paid_brand'
        WHEN utm_source IS NULL and http_referer IS NULL THEN 'direct_type_in'
        END AS channel_group,
	utm_source,
    utm_campaign,
    http_referer
FROM website_sessions
WHERE created_at < '2012-12-23') as sessions_w_channel_group
GROUP BY 1,2; 



-- Analyzing Business Pattern and Seasonality.

-- Understand seasonality

SELECT
	YEAR(website_sessions.created_at) as yr,
	MONTH(website_sessions.created_at) as mo,
	count(distinct website_sessions.website_session_id) as sessions,
	count(distinct orders.order_id) as orders
FROM website_sessions
	LEFT JOIN orders
		ON website_sessions.website_session_id=orders.website_session_id
WHERE website_sessions.created_at < '2013-01-01'
GROUP BY 1,2;        

SELECT
	YEAR(website_sessions.created_at) as yr,
    WEEK(website_sessions.created_at) as week,
	MIN(DATE(website_sessions.created_at)) as start_week_at,
	count(distinct website_sessions.website_session_id) as sessions,
	count(distinct orders.order_id) as orders
FROM website_sessions
	LEFT JOIN orders
		ON website_sessions.website_session_id=orders.website_session_id
WHERE website_sessions.created_at < '2013-01-01'
GROUP BY 1,2;  


-- Analyzing Avg hr , Avg weekday pattern.
select
hr,
round(AVG(website_sessions),1) as avg_sessions,
round(AVG(case when wkday = 0 then website_sessions else null end),1) as mon,
round(AVG(case when wkday = 1 then website_sessions else null end),1) as tues,
round(AVG(case when wkday = 2 then website_sessions else null end),1) as wed,
round(AVG(case when wkday = 3 then website_sessions else null end),1) as thrus,
round(AVG(case when wkday = 4 then website_sessions else null end),1) as fri,
round(AVG(case when wkday = 5 then website_sessions else null end),1) as sat,
round(AVG(case when wkday = 6 then website_sessions else null end),1) as sun
FROM (SELECT
	DATE(created_at) as created_date,
    weekday(created_at) as wkday,
    hour(created_at) as hr,
    count(distinct website_session_id) as website_sessions
from website_sessions
where created_at between '2012-09-15' and '2012-11-15'
group by 1,2,3) as daily_hourly_sessions
group by 1
order by 1; 

-- Product Analysis.

-- product sales & product launch.
SELECT
	primary_product_id,
    count(order_id) as orders,
    sum(price_usd) as revenue,
    sum(price_usd - cogs_usd) as margin,
    avg(price_usd) as aov
from orders
where order_id between 10000 and 11000
group by 1
order by 2 desc;    

-- sales trend.

SELECT
	YEAR(created_at) AS yr,
    MONTH(created_at) AS mo,
    SUM(items_purchased) as sales,
    SUM(price_usd) AS revenue,
    SUM(price_usd - cogs_usd) AS margin
FROM orders
WHERE created_at < '2013-01-04' -- date of request
GROUP BY 1,2;    

-- impact of new product launch.

SELECT
	YEAR(website_sessions.created_at) as yr,
    MONTH(website_sessions.created_at) as mo,
    count(distinct website_sessions.website_session_id) as sessions,
    count(distinct orders.order_id) as orders,
    count(distinct orders.order_id)
		/count(distinct website_sessions.website_session_id) AS conv_rate,
	sum(orders.price_usd)/count(distinct website_sessions.website_session_id) as revenue_per_sessions,
    count(distinct case when orders.primary_product_id=1 then order_id else null end) as product_one_order,
    count(distinct case when orders.primary_product_id=2 then order_id else null end) as product_two_orders
FROM website_sessions
	LEFT JOIN orders
		ON website_sessions.website_session_id=orders.website_session_id
WHERE website_sessions.created_at < '2013-04-01' --  date of request
	AND website_sessions.created_at > '2012-04-01' -- specified in request
GROUP BY 1,2;    

-- Product level website analysis.

SELECT 
	website_pageviews.pageview_url,
    count(distinct website_pageviews.website_session_id) as sessions,
    count(distinct orders.order_id) as orders,
    count(distinct orders.order_id)/ count(distinct website_pageviews.website_session_id) as view_product_to_order_rate    
from website_pageviews
	left join orders
		ON website_pageviews.website_session_id = orders.website_session_id
where website_pageviews.created_at between '2013-02-01' and '2013-03-01'
	AND pageview_url IN ('/the-original-mr-fuzzy', '/the-forever-love-bear')
group by 1;    
	
-- Product Level Website Pathing Analysis.
-- TASK
/* Hi there!
Now that we have a new product, I’m thinking about our
user path and conversion funnel. Let’s look at sessions which
hit the /products page and see where they went next .
Could you please pull clickthrough rates from /products
since the new product launch on 2013 01 06, by product,
and compare to the 3 months leading up to launch as a
baseline?
Thanks, Morgan */
-- Step 1: finding the /product pageview we care about.
CREATE TEMPORARY TABLE product_pageviews    
SELECT
	website_session_id,
    website_pageview_id,
    created_at,
    CASE
		WHEN created_at < '2013-01-06' THEN 'A. Pre_Product_2'
        WHEN created_at >= '2013-01-06' THEN  'B. Post_Product_2'
        ELSE 'uh oh...check logic'
    END AS time_period    
FROM website_pageviews
WHERE created_at < '2013-04-06' -- date of request.
	AND created_at > '2012-10-06' -- before 3 month of product launch.
    AND pageview_url = '/products';
    
    
-- Step 2: finding next pageview id that occurs AFTER the product pageview.

CREATE TEMPORARY TABLE sessions_w_next_pageview_id
SELECT 
	product_pageviews.time_period,
    product_pageviews.website_session_id,
    MIN(website_pageviews.website_pageview_id) as min_next_pageview_id
FROM product_pageviews
	LEFT JOIN website_pageviews
		ON product_pageviews.website_session_id=website_pageviews.website_session_id
        AND website_pageviews.website_pageview_id > product_pageviews.website_pageview_id
GROUP BY 1,2;

-- Step 3: find the page_url associated with any applicable next pageview_id.
CREATE TEMPORARY TABLE sessions_w_next_pageview_url
SELECT 
	sessions_w_next_pageview_id.time_period,
    sessions_w_next_pageview_id.website_session_id,
    website_pageviews.pageview_url as next_pageview_url
FROM sessions_w_next_pageview_id
	LEFT JOIN website_pageviews
		ON sessions_w_next_pageview_id.min_next_pageview_id=website_pageviews.website_pageview_id;
        
        
-- Step 4: summarize the data and analyze pre v/s post period.

SELECT
	time_period,
    count(distinct website_session_id) as sessions,
    count(DISTINCT CASE WHEN next_pageview_url IS NOT NULL THEN website_session_id ELSE NULL END) as next_pg,
    count(DISTINCT CASE WHEN next_pageview_url IS NOT NULL THEN website_session_id ELSE NULL END)
		/count(distinct website_session_id) as pct_w_next_pg,
    count(DISTINCT CASE WHEN next_pageview_url ='/the-original-mr-fuzzy' THEN website_session_id ELSE NULL END) as to_mrfuzzy,
    count(DISTINCT CASE WHEN next_pageview_url ='/the-original-mr-fuzzy' THEN website_session_id ELSE NULL END)
		/count(distinct website_session_id) as pct_to_mrfuzzy,
    count(DISTINCT CASE WHEN next_pageview_url ='/the-forever-love-bear' THEN website_session_id ELSE NULL END) as to_lovebear,    
    count(DISTINCT CASE WHEN next_pageview_url ='/the-forever-love-bear' THEN website_session_id ELSE NULL END)
		/count(distinct website_session_id) as pct_to_lovebear
FROM sessions_w_next_pageview_url
GROUP BY 1;      
 
 -- NEW TASk
 /*
 Hi there!
I’d like to look at our two products since January 6th and
analyze the conversion funnels from each product page to
conversion.
It would be great if you could produce a comparison between
the two conversion funnels, for all website traffic.
Thanks!
Morgan */


-- Solution is a multistep query.

-- Step 1: select all the pageview for relevant session. 
CREATE TEMPORARY TABLE sessions_seeing_product_page
SELECT
	website_session_id,
    website_pageview_id,
    pageview_url AS product_page_seen
FROM website_pageviews
WHERE created_at < '2013-04-10' -- date of assignmnet
	AND created_at > '2013-01-06' -- product 2 launch
    AND pageview_url IN ('/the-original-mr-fuzzy','/the-forever-love-bear');
    
    
-- finding the right pageview_url to build funnel.

SELECT DISTINCT
	website_pageviews.pageview_url
FROM sessions_seeing_product_page
	LEFT JOIN website_pageviews
		ON website_pageviews.website_session_id = sessions_seeing_product_page.website_session_id
        AND website_pageviews.website_pageview_id > sessions_seeing_product_page.website_pageview_id;
        
-- above we have look over the pageview-level results.
-- then turn it into subquery and make it summary with flag.
        
    
SELECT 
    sessions_seeing_product_page.website_session_id,
    sessions_seeing_product_page.product_page_seen,
    CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page,
    CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page,
    CASE WHEN pageview_url = '/billing-2' THEN 1 ELSE 0 END AS billing2_page,
    CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
FROM sessions_seeing_product_page
	LEFT JOIN website_pageviews
		ON website_pageviews.website_session_id = sessions_seeing_product_page.website_session_id
        AND website_pageviews.website_pageview_id > sessions_seeing_product_page.website_pageview_id
ORDER BY 1,
website_pageviews.created_at;    

-- let get it into subquery
CREATE TEMPORARY TABLE session_product_level_made_it_flags
SELECT
	website_session_id,
    CASE
		WHEN product_page_seen='/the-original-mr-fuzzy' THEN 'mrfuzzy' 
        WHEN product_page_seen='/the-forever-love-bear' THEN 'lovebear'
        ELSE 'oh uh...check logic'
    END AS product_seen,
    MAX(cart_page) as cart_made_it,
	MAX(shipping_page) as shipping_made_it,
    MAX(billing2_page) as billing_made_it,
    MAX(thankyou_page) as thankyou_made_it

FROM (SELECT 
    sessions_seeing_product_page.website_session_id,
    sessions_seeing_product_page.product_page_seen,
    CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page,
    CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page,
    CASE WHEN pageview_url = '/billing-2' THEN 1 ELSE 0 END AS billing2_page,
    CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
FROM sessions_seeing_product_page
	LEFT JOIN website_pageviews
		ON website_pageviews.website_session_id = sessions_seeing_product_page.website_session_id
        AND website_pageviews.website_pageview_id > sessions_seeing_product_page.website_pageview_id
ORDER BY 1,
website_pageviews.created_at) as pageview_level
GROUP BY 1,2;

SELECT * from session_product_level_made_it_flags;    

-- final output part-1
SELECT
	product_seen,
    count(distinct website_session_id) as sessions,
    count(DISTINCT CASE WHEN cart_made_it=1 THEN website_session_id ELSE NULL END) as to_cart, 
	count(DISTINCT CASE WHEN shipping_made_it=1 THEN website_session_id ELSE NULL END) as to_shipping,
	count(DISTINCT CASE WHEN billing_made_it=1 THEN website_session_id ELSE NULL END) as to_billing,
	count(DISTINCT CASE WHEN thankyou_made_it=1 THEN website_session_id ELSE NULL END) as to_thankyou
FROM session_product_level_made_it_flags
GROUP BY 1;    

-- final output part-2 for rate.

SELECT
	product_seen,
	count(DISTINCT CASE WHEN cart_made_it=1 THEN website_session_id ELSE NULL END)
		/count(distinct website_session_id) as product_page_click_rt,
	count(DISTINCT CASE WHEN shipping_made_it=1 THEN website_session_id ELSE NULL END)
		/count(DISTINCT CASE WHEN cart_made_it=1 THEN website_session_id ELSE NULL END) as cart_click_rt,
	count(DISTINCT CASE WHEN billing_made_it=1 THEN website_session_id ELSE NULL END)
		/count(DISTINCT CASE WHEN shipping_made_it=1 THEN website_session_id ELSE NULL END) as shipping_click_rt,
	count(DISTINCT CASE WHEN thankyou_made_it=1 THEN website_session_id ELSE NULL END)
		/count(DISTINCT CASE WHEN billing_made_it=1 THEN website_session_id ELSE NULL END) as billing_click_rt
        
FROM session_product_level_made_it_flags
GROUP BY 1;


-- BUSINESS CONCEPT: CROSS-SELLING PRODUCTS.

SELECT 
	orders.primary_product_id,
    -- order_items.product_id AS cross_sold_product_id,
	-- order_items.is_primary_item
	count(distinct orders.order_id) as orders,
    count(distinct case when order_items.product_id=1 then orders.order_id else null end) as x_sell_prod1,
	count(distinct case when order_items.product_id=2 then orders.order_id else null end) as x_sell_prod2,
	count(distinct case when order_items.product_id=3 then orders.order_id else null end) as x_sell_prod3
    
FROM orders
	LEFT JOIN order_items
		ON order_items.order_id=orders.order_id
        AND order_items.is_primary_item = 0 -- cross sell product
WHERE orders.order_id BETWEEN 10000 AND 11000 -- arbitrary
GROUP BY 1;        

-- TASK
/*
Good morning,
On September 25
th we started giving customers the option
to add a 2nd product while on the /cart page . Morgan says
this has been positive, but I’d like your take on it.
Could you please compare the month before vs the month
after the change ? I’d like to see CTR from the /cart page ,
Avg Products per Order , AOV , and overall revenue per
/cart page view
Thanks, Cindy */

-- Assignment cross-sell analysis.
-- Solution is multstep query, let's break it into pieces.

-- Step 1: Identify the relevant /cart page view and their sessions.

CREATE TEMPORARY TABLE sessions_seeing_cart
SELECT
	CASE
		WHEN created_at < '2013-09-25' THEN 'A. Pre_Cross_Sell'
        WHEN created_at >= '2013-09-25' THEN 'B. Post_Cross_Sell'
        ELSE 'Oh...check logic'
    END as time_period,    
	website_pageviews.website_session_id as cart_session_id,
    website_pageviews.website_pageview_id as cart_pageview_id
FROM website_pageviews
WHERE created_at between '2013-08-25' and '2013-10-25'
	AND pageview_url = '/cart';
    
   select * from  sessions_seeing_cart;

-- Step 2: See which of those /cart sessions clicked through the shipping page.
CREATE TEMPORARY TABLE cart_sessions_seeing_another_page
SELECT
	sessions_seeing_cart.time_period,
    sessions_seeing_cart.cart_session_id,
	MIN(website_pageviews.website_pageview_id) as pv_id_after_cart 
FROM sessions_seeing_cart
	LEFT JOIN website_pageviews
		ON sessions_seeing_cart.cart_session_id = website_pageviews.website_session_id
        AND website_pageviews.website_pageview_id > sessions_seeing_cart.cart_pageview_id
GROUP BY 1,2
HAVING MIN(website_pageviews.website_pageview_id) IS NOT NULL;        

select * from cart_sessions_seeing_another_page;


CREATE TEMPORARY TABLE pre_post_sessions_orders
SELECT
	time_period,
    cart_session_id,
    order_id,
    items_purchased,
    price_usd
FROM sessions_seeing_cart
	INNER JOIN orders
		ON sessions_seeing_cart.cart_session_id=orders.website_session_id;
        
select * from pre_post_sessions_orders;




select
	sessions_seeing_cart.time_period,
    sessions_seeing_cart.cart_session_id,
    
	CASE WHEN cart_sessions_seeing_another_page.cart_session_id IS NULL THEN 0 ELSE 1 END as clicked_to_another_page,
	CASE WHEN pre_post_sessions_orders.cart_session_id IS NULL THEN 0 ELSE 1 END as placed_orders,
    pre_post_sessions_orders.items_purchased,
    pre_post_sessions_orders.price_usd
        
from sessions_seeing_cart
	LEFT JOIN cart_sessions_seeing_another_page
		ON sessions_seeing_cart.cart_session_id = cart_sessions_seeing_another_page.cart_session_id
    LEFT JOIN pre_post_sessions_orders
		ON sessions_seeing_cart.cart_session_id=pre_post_sessions_orders.cart_session_id;
        
        
 SELECT
	time_period,
	count(distinct cart_session_id) as cart_session,
    sum(clicked_to_another_page) as clickthroughs,
    sum(clicked_to_another_page)/count(distinct cart_session_id) as cart_ctr,
    sum(placed_orders) as orders_placed,
    sum(items_purchased) as product_purchased,
	sum(items_purchased)/sum(placed_orders) AS products_per_order,
    sum(price_usd) as revenue,
    sum(price_usd)/sum(placed_orders) as aov,
	sum(price_usd)/count(distinct cart_session_id) as rev_per_cart_session
 
FROM (select
	sessions_seeing_cart.time_period,
    sessions_seeing_cart.cart_session_id,
    
	CASE WHEN cart_sessions_seeing_another_page.cart_session_id IS NULL THEN 0 ELSE 1 END as clicked_to_another_page,
	CASE WHEN pre_post_sessions_orders.cart_session_id IS NULL THEN 0 ELSE 1 END as placed_orders,
    pre_post_sessions_orders.items_purchased,
    pre_post_sessions_orders.price_usd
        
from sessions_seeing_cart
	LEFT JOIN cart_sessions_seeing_another_page
		ON sessions_seeing_cart.cart_session_id = cart_sessions_seeing_another_page.cart_session_id
    LEFT JOIN pre_post_sessions_orders
		ON sessions_seeing_cart.cart_session_id=pre_post_sessions_orders.cart_session_id) as full_data
GROUP by time_period;


 /* NEW TASK
 Good morning,
On December 12
th 2013, we launched a third product
targeting the birthday gift market (Birthday Bear).
Could you please run a pre post analysis comparing the
month before vs. the month after , in terms of session to
order conversion rate , AOV , products per order , and
revenue per session
Thank you!
Cindy
 */
 
 use mavenfuzzyfactory;
 SELECT
	CASE 
		WHEN website_sessions.created_at < '2013-12-12' THEN 'A. Pre_Birthday_Bear'
        WHEN website_sessions.created_at >= '2013-12-12' THEN 'A. Post_Birthday_Bear'
        ELSE 'oh check logic'
    END as time_period,    
	count(distinct website_sessions.website_session_id) as sessions,
    count(distinct orders.order_id) as orders,
	count(distinct orders.order_id)/count(distinct website_sessions.website_session_id) as conv_rate,
    SUM(price_usd) as total_revenue,
    SUM(items_purchased) as total_product_sold,
    SUM(price_usd)/count(distinct orders.order_id) as aov,
	SUM(items_purchased)/count(distinct orders.order_id) as product_per_order,
    SUM(price_usd)/count(distinct website_sessions.website_session_id) as revenue_per_sessions 
 
 FROM website_sessions
	LEFT JOIN orders
		ON website_sessions.website_session_id=orders.website_session_id
WHERE website_sessions.created_at BETWEEN '2013-11-12' AND '2014-01-12'
GROUP BY 1;        


-- Product Refund Analysis.


/*
Good morning,
Our Mr. Fuzzy supplier had some quality issues which
weren’t corrected until September 2013. Then they had a
major problem where the bears’ arms were falling off in
Aug/Sep 2014. As a result, we replaced them with a new
supplier on September 16, 2014
Can you please pull monthly product refund rates, by
product, and confirm our quality issues are now fixed
-
Cindy
*/


SELECT
	YEAR(order_items.created_at) as yr,
    MONTH(order_items.created_at) as mo,
    count(distinct CASE WHEN product_id = 1 THEN order_items.order_item_id else NULL end) as p1_orders,
	count(distinct CASE WHEN product_id = 1 THEN order_item_refunds.order_item_id else NULL end)
		/count(distinct CASE WHEN product_id = 1 THEN order_items.order_item_id else NULL end) as p1_refund_rt,
        
    count(distinct CASE WHEN product_id = 2 THEN order_items.order_item_id else NULL end) as p2_orders,
	count(distinct CASE WHEN product_id = 2 THEN order_item_refunds.order_item_id else NULL end)
		/count(distinct CASE WHEN product_id = 2 THEN order_items.order_item_id else NULL end) as p2_refund_rt,
	
	count(distinct CASE WHEN product_id = 3 THEN order_items.order_item_id else NULL end) as p3_orders,
	count(distinct CASE WHEN product_id = 3 THEN order_item_refunds.order_item_id else NULL end)
		/count(distinct CASE WHEN product_id = 3 THEN order_items.order_item_id else NULL end) as p3_refund_rt,
        
    count(distinct CASE WHEN product_id = 4 THEN order_items.order_item_id else NULL end) as p4_orders,
	count(distinct CASE WHEN product_id = 4 THEN order_item_refunds.order_item_id else NULL end)
		/count(distinct CASE WHEN product_id = 4 THEN order_items.order_item_id else NULL end) as p4_refund_rt
FROM order_items
	LEFT JOIN order_item_refunds
		ON order_items.order_item_id=order_item_refunds.order_item_id
WHERE order_items.created_at < '2014-10-15'
GROUP BY 1,2;



-- USER ANALYSIS.
-- 1. Analyzing repeat behavior
/*
Hey there,
We’ve been thinking about customer value based solely on
their first session conversion and revenue. But if customers
have repeat sessions, they may be more valuable than we
thought . If that’s the case, we might be able to spend a bit
more to acquire them.
Could you please pull data on how many of our website
visitors come back for another session ? 2014 to date is good.
Thanks, Tom
*/

CREATE TEMPORARY TABLE sessions_w_repeats
select
	new_sessions.user_id,
    new_sessions.website_session_id as new_session_id,
    website_sessions.website_session_id as repeat_session_id
FROM (SELECT 
	user_id,
	website_session_id
from website_sessions
where created_at < '2014-11-01' -- date of assignment
    AND created_at >='2014-01-01'  -- prescribed date range in assignment
	AND is_repeat_session =0 -- new session only
    ) as new_sessions
    LEFT JOIN website_sessions
		ON website_sessions.user_id=new_sessions.user_id
        AND website_sessions.website_session_id>new_sessions.website_session_id
        AND is_repeat_session = 1
		AND created_at < '2014-11-01' 
		AND created_at >='2014-01-01' ;
        
        
-- DROP table sessions_w_repeats;
select * from sessions_w_repeats;

select
	repeat_session_id,
    count(user_id) as users 
FROM (
select
	user_id,
    count(distinct new_session_id) as new_session_id,
    count(distinct repeat_session_id) as repeat_session_id
FROM sessions_w_repeats
GROUP BY 1
ORDER BY 3) as user_level
GROUP BY 1;    
    
    
use mavenfuzzyfactory;    
-- NEW TASK.
/*        
Ok, so the repeat session data was really interesting to see.
Now you’ve got me curious to better understand the behavior
of these repeat customers.
Could you help me understand
the minimum, maximum, and
average time between the first and second session for
customers who do come back? Again, analyzing 2014 to date
is probably the right time period.
Thanks, Tom */        

-- this is multi step query
-- Step 1: identify the relevant new sessions. 
-- Step 2: use user_id from step 1 and find repeat sessions.
-- Step 3: find the created time for first and second sessions as user level.
-- Step 4: aggregate the user level data to find avg,min and max.

CREATE TEMPORARY TABLE sessions_w_repeats_for_time_diff
SELECT
	new_sessions.user_id,
    new_sessions.website_session_id as new_session_id,
    new_sessions.created_at as new_session_created_at,
    website_sessions.website_session_id as repeat_session_id,
    website_sessions.created_at as repeat_session_created_at
FROM (SELECT
	user_id,
    website_session_id,
    created_at
FROM website_sessions
WHERE created_at < '2014-11-03' -- date of assignment
	AND created_at >= '2014-01-01' -- Prescribed date range
    AND is_repeat_session = 0 -- for new session
    ) new_sessions
    LEFT JOIN website_sessions
		ON new_sessions.user_id=website_sessions.user_id
        AND website_sessions.website_session_id>new_sessions.website_session_id
        AND website_sessions.is_repeat_session=1
        AND website_sessions.created_at < '2014-11-03' -- date of assignment
		AND website_sessions.created_at >= '2014-01-01' -- Prescribed date range
        ;
        
SELECT * FROM sessions_w_repeats_for_time_diff;   


CREATE TEMPORARY TABLE first_to_second        
SELECT
	user_id,
    datediff(second_session_created_at,new_session_created_at) as days_first_to_second_sessions
FROM (SELECT
	user_id,
    new_session_id,
    new_session_created_at,
    MIN(repeat_session_id) as second_session_id,
    MIN(repeat_session_created_at) as second_session_created_at
FROM sessions_w_repeats_for_time_diff
WHERE repeat_session_id is not null
GROUP BY 1,2,3) as first_second;

select * from first_to_second;

select
	avg(days_first_to_second_sessions) as avg_days_first_to_second,
    min(days_first_to_second_sessions) as min_days_first_to_second,
    max(days_first_to_second_sessions) as max_days_first_to_second
FROM first_to_second;
    
    
-- NEW TASK
/*
Hi there,
Let’s do a bit more digging into our repeat customers.
Can you help me understand the channels they come back
through? Curious if it’s all direct type in, or if we’re paying for
these customers with paid search ads multiple times.
Comparing new vs. repeat sessions by channel
would be
really valuable, if you’re able to pull it! 2014 to date is great.
Thanks, Tom
*/    

SELECT
	CASE 
		when utm_source is NULL and http_referer IN ('https://www.gsearch.com','https://www.bsearch.com') then 'organic_search'
        when utm_campaign ='nonbrand' then 'paid_nonbrand'
		when utm_campaign ='brand' then 'paid_brand'
        when utm_source = 'socialbook' then 'paid_social'
        when utm_source is NULL and http_referer is NULL then 'direct_type_in'
	END as channel_group,
	-- utm_source,
    -- utm_campaign,
	-- http_referer,
    COUNT(CASE WHEN is_repeat_session=0 THEN website_session_id ELSE NULL END) AS new_sessions,
    COUNT(CASE WHEN is_repeat_session=1 THEN website_session_id ELSE NULL END) AS repeat_sessions
FROM website_sessions
WHERE created_at <'2014-11-05'
	AND created_at >='2014-01-01'
GROUP BY 1;   



-- NEW TASK
/*
Hi there!
Sounds like you and Tom have learned a lot about our repeat
customers. Can I trouble you for one more thing?
I’d love to do a
comparison of conversion rates and revenue per
session for repeat sessions vs new sessions.
Let’s continue using data from
2014, year to date.
Thank you!
Morgan
*/ 

SELECT 
	is_repeat_session,
    count(distinct website_sessions.website_session_id) as sessions,
    count(distinct orders.order_id)/count(distinct website_sessions.website_session_id) as conv_rate,
    sum(price_usd)/count(distinct website_sessions.website_session_id) as rev_per_session
FROM website_sessions
	LEFT JOIN orders
		ON website_sessions.website_session_id=orders.website_session_id
WHERE website_sessions.created_at < '2014-11-08'
	AND website_sessions.created_at >= '2014-01-01'
GROUP BY 1;    






-- FINAL Project 

/*
INTRODUCING THE
FINAL COURSE PROJECT

SITUATION: Cindy is close to securing Maven Fuzzy Factory’s next round of funding, and she needs your
help to tell a compelling story to investors. You’ll need to pull the relevant data, and help your
CEO craft a story about a data driven company that has been producing rapid growth.

OBJECTIVE
Use SQL to:
Extract and analyze traffic and website performance data to craft a growth story that your
CEO can sell. Dive in to the marketing channel activities and the website improvements that
have contributed to your success to date, and use the opportunity to flex your analytical skills
for the investors while you’re at it.
As an Analyst, the first part of your job is extracting and analyzing the data. The next (equally
important) part is communicating the story effectively to your stakeholders.
*/

-- Q.1 First, I’d like to show our volume growth. Can you pull overall session and order volume, trended by quarter
-- for the life of the business? Since the most recent quarter is incomplete, you can decide how to handle it.

select
	quarter(website_sessions.created_at) as qtr,
    year(website_sessions.created_at) as yr,
    count(website_sessions.website_session_id) as sessions,
    count(orders.order_id) as orders
from website_sessions
	LEFT JOIN  orders
		ON website_sessions.website_session_id=orders.website_session_id
WHERE website_sessions.created_at<'2015-01-01'        
GROUP BY 1,2;


-- Q.2 Next, let’s showcase all of our efficiency improvements. I would love to show quarterly figures since we
-- launched, for session to order conversion rate, revenue per order, and revenue per session.

select
	quarter(website_sessions.created_at) as qtr,
    year(website_sessions.created_at) as yr,
  --  count(website_sessions.website_session_id) as sessions,
  --  count(orders.order_id) as orders,
    count(orders.order_id)/count(website_sessions.website_session_id) as order_conv_rate,
    sum(price_usd)/count(orders.order_id) as revn_per_order,
    sum(price_usd)/count(website_sessions.website_session_id) as revn_per_session
from website_sessions
	LEFT JOIN  orders
		ON website_sessions.website_session_id=orders.website_session_id
-- WHERE website_sessions.created_at<'2015-01-01'        
GROUP BY 1,2;



/*
3. I’d like to show how we’ve grown specific channels. Could you pull a quarterly view of orders 
from Gsearch nonbrand, Bsearch nonbrand, brand search overall, organic search, and direct type-in?
*/

SELECT 
	YEAR(website_sessions.created_at) AS yr,
	QUARTER(website_sessions.created_at) AS qtr, 
    COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' AND utm_campaign = 'nonbrand' THEN orders.order_id ELSE NULL END) AS gsearch_nonbrand_orders, 
    COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' AND utm_campaign = 'nonbrand' THEN orders.order_id ELSE NULL END) AS bsearch_nonbrand_orders, 
    COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN orders.order_id ELSE NULL END) AS brand_search_orders,
    COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN orders.order_id ELSE NULL END) AS organic_search_orders,
    COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN orders.order_id ELSE NULL END) AS direct_type_in_orders
    
FROM website_sessions 
	LEFT JOIN orders
		ON website_sessions.website_session_id = orders.website_session_id
GROUP BY 1,2
ORDER BY 1,2;



/*
4. Next, let’s show the overall session-to-order conversion rate trends for those same channels, 
by quarter. Please also make a note of any periods where we made major improvements or optimizations.
*/

SELECT 
	YEAR(website_sessions.created_at) AS yr,
	QUARTER(website_sessions.created_at) AS qtr, 
    COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' AND utm_campaign = 'nonbrand' THEN orders.order_id ELSE NULL END)
		/COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' AND utm_campaign = 'nonbrand' THEN website_sessions.website_session_id ELSE NULL END) AS gsearch_nonbrand_conv_rt, 
    COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' AND utm_campaign = 'nonbrand' THEN orders.order_id ELSE NULL END) 
		/COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' AND utm_campaign = 'nonbrand' THEN website_sessions.website_session_id ELSE NULL END) AS bsearch_nonbrand_conv_rt, 
    COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN orders.order_id ELSE NULL END) 
		/COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN website_sessions.website_session_id ELSE NULL END) AS brand_search_conv_rt,
    COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN orders.order_id ELSE NULL END) 
		/COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN website_sessions.website_session_id ELSE NULL END) AS organic_search_conv_rt,
    COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN orders.order_id ELSE NULL END) 
		/COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN website_sessions.website_session_id ELSE NULL END) AS direct_type_in_conv_rt
FROM website_sessions 
	LEFT JOIN orders
		ON website_sessions.website_session_id = orders.website_session_id
GROUP BY 1,2
ORDER BY 1,2
;


/*
5. We’ve come a long way since the days of selling a single product. Let’s pull monthly trending for revenue 
and margin by product, along with total sales and revenue. Note anything you notice about seasonality.
*/

SELECT
	YEAR(created_at) as yr,
    MONTH(created_at) as mo,
    sum(case when product_id =1 then price_usd else null end) as mrfuzzy_rev,
	sum(case when product_id =1 then price_usd-cogs_usd else null end) as mrfuzzy_mrgn,
    sum(case when product_id =2 then price_usd else null end) as lovebear_rev,
    sum(case when product_id =2 then price_usd-cogs_usd else null end) as lovebear_mrgn,
    sum(case when product_id =3 then price_usd else null end) as birthdaypanda_rev,
    sum(case when product_id =3 then price_usd-cogs_usd else null end) as birthdaypanda_mrgn,
    sum(case when product_id =4 then price_usd else null end) as minibear_rev,
    sum(case when product_id =4 then price_usd-cogs_usd else null end) as minibear_mrgn,
    SUM(price_usd) as Revenue,
    SUM(price_usd-cogs_usd) as Margin
FROM order_items
GROUP BY 1,2;


/*
6. Let’s dive deeper into the impact of introducing new products. Please pull monthly sessions to 
the /products page, and show how the % of those sessions clicking through another page has changed 
over time, along with a view of how conversion from /products to placing an order has improved.
*/
CREATE TEMPORARY TABLE product_pageview
SELECT
	website_session_id,
    website_pageview_id,
    created_at as saw_product_page_at
FROM website_pageviews
WHERE pageview_url ='/products';

select * from product_pageview;

SELECT
	YEAR(saw_product_page_at) as yr,
    MONTH(saw_product_page_at) as mo,
	count(product_pageview.website_session_id) session_to_product,
    count(website_pageviews.website_session_id) clicked_to_next_page,
	count(DISTINCT website_pageviews.website_session_id)/COUNT(DISTINCT product_pageview.website_session_id) AS clickthrough_rt,
    count(orders.order_id) as orders,
     count(orders.order_id)/count(product_pageview.website_session_id) product_to_order_rt
FROM product_pageview
	LEFT JOIN website_pageviews
		ON product_pageview.website_session_id=website_pageviews.website_session_id -- same session
        AND website_pageviews.website_pageview_id>product_pageview.website_pageview_id -- they had another page AFTER
     LEFT JOIN orders
		ON product_pageview.website_session_id=orders.website_session_id
GROUP BY 1,2;        



/*
7. We made our 4th product available as a primary product on December 05, 2014 (it was previously only a cross-sell item). 
Could you please pull sales data since then, and show how well each product cross-sells from one another?
*/

create temporary table primary_products
SELECT 
	order_id,
    primary_product_id,
    created_at as ordered_at
FROM orders
WHERE created_at > '2014-12-05'  -- when the 4th product was added (says so in question)
;

select * from primary_products;

SELECT
	primary_product_id,
    COUNT(distinct order_id) as total_orders,
    COUNT(DISTINCT CASE WHEN cross_sell_product_id = 1 THEN order_id ELSE NULL END) AS _xsold_p1,
    COUNT(DISTINCT CASE WHEN cross_sell_product_id = 2 THEN order_id ELSE NULL END) AS _xsold_p2,
    COUNT(DISTINCT CASE WHEN cross_sell_product_id = 3 THEN order_id ELSE NULL END) AS _xsold_p3,
    COUNT(DISTINCT CASE WHEN cross_sell_product_id = 4 THEN order_id ELSE NULL END) AS _xsold_p4,
    COUNT(DISTINCT CASE WHEN cross_sell_product_id = 1 THEN order_id ELSE NULL END)/COUNT(DISTINCT order_id) AS p1_xsell_rt,
    COUNT(DISTINCT CASE WHEN cross_sell_product_id = 2 THEN order_id ELSE NULL END)/COUNT(DISTINCT order_id) AS p2_xsell_rt,
    COUNT(DISTINCT CASE WHEN cross_sell_product_id = 3 THEN order_id ELSE NULL END)/COUNT(DISTINCT order_id) AS p3_xsell_rt,
    COUNT(DISTINCT CASE WHEN cross_sell_product_id = 4 THEN order_id ELSE NULL END)/COUNT(DISTINCT order_id) AS p4_xsell_rt
FROM(
select
	primary_products.*,
    order_items.product_id AS cross_sell_product_id
FROM primary_products
	LEFT JOIN order_items
		ON primary_products.order_id=order_items.order_id
        AND order_items.is_primary_item=0 -- only bringing in cross-sells
)primary_w_cross_sell
GROUP BY 1;






