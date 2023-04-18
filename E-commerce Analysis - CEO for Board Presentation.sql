
/* The below questions are based on a series of emails from the CEO, based on company performance metrics ahead of 
presenting to the board next week. Our task is to deliver the relevant metrics to show the company's promising growth. 
We must extract and analyse website traffic and performance data from the database to quantify the company's growth, and tell the story
of how we have been able to generate that growth.

In the below tasks, we are working under the assumption that all questions were asked on '2012-11-27', so all queries must provide data
with this in mind. */


SELECT * FROM orders;
SELECT * FROM website_sessions;
SELECT * FROM website_pageviews;

/* Gsearch seems to be the biggest driver of our business. Could you pull monthly trends for gsearch sessions and orders
so that we can showcase the growth there?*/

SELECT
-- YEAR(website_sessions.created_at) AS Yr,
-- MONTH(website_sessions.created_at) AS Mnth,
MIN(DATE(website_sessions.created_at)) AS monthly_data,
COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
COUNT(DISTINCT orders.order_id) AS orders
FROM 
website_sessions
LEFT JOIN orders
ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.utm_source = 'gsearch'
AND website_sessions.created_at <'2012-11-27'
GROUP BY 
YEAR(website_sessions.created_at),
MONTH(website_sessions.created_at);

/* Next, it would be great to see similar monthly trend for Gsearch, but this time splitting out nonbrand and brand campaigns separately.
I am wondering if brand is picking up at all. If so, this is a good story to tell.*/

SELECT
-- YEAR(website_sessions.created_at) AS Yr,
-- MONTH(website_sessions.created_at) AS Mnth,
MIN(DATE(website_sessions.created_at)) AS monthly_data,
COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
COUNT(DISTINCT orders.order_id) AS orders,
website_sessions.utm_campaign AS campaign_type 
FROM 
website_sessions
LEFT JOIN orders
ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.utm_source = 'gsearch'
AND website_sessions.created_at <'2012-11-27'
AND website_sessions.utm_campaign IN ('nonbrand', 'brand')
GROUP BY 
website_sessions.utm_campaign,
YEAR(website_sessions.created_at),
MONTH(website_sessions.created_at)
ORDER BY monthly_data;


/* While we're on Gsearch, could you dive into nonbrand, and pull monthly sessions and orders split by device type? 
I want to flex our analytical muscles a little and show the board we really know our traffic sources!*/ 

SELECT
-- YEAR(website_sessions.created_at) AS YR,
-- MONTH(website_sessions.created_at) AS Mnth,
MIN(DATE(website_sessions.created_at)) AS monthly_data,
COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
COUNT(DISTINCT orders.order_id) AS orders,
website_sessions.device_type AS device
FROM website_sessions
LEFT JOIN orders
ON website_sessions.website_session_id = orders.website_session_id
WHERE 
utm_source = 'gsearch' AND
utm_campaign = 'nonbrand' AND
website_sessions.created_at <'2012-11-27'
GROUP BY 
YEAR(website_sessions.created_at),
MONTH(website_sessions.created_at),
website_sessions.device_type;

/* I'm worried that one of our more pessimistic board members may be concerned about the large % of traffic from Gsearch.
Can you pull monthly trends for Gsearch, alongside monthly trends for each of our other channels? */


SELECT 
-- YEAR(website_sessions.created_at) AS YR,
-- MONTH(website_sessions.created_at) AS Mnth,
MIN(DATE(website_sessions.created_at)) AS monthly_data,
utm_source as channel,
COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
COUNT(DISTINCT orders.order_id) AS orders
FROM website_sessions
LEFT JOIN orders
ON website_sessions.website_session_id = orders.website_session_id
WHERE 
website_sessions.created_at < '2012-11-27'
GROUP BY 
YEAR(website_sessions.created_at),
MONTH(website_sessions.created_at),
 utm_source;
 
 /* I'd like to tell the story of our website performance improvements over the course of the first 8 months. 
 Could you pull sessions to order conversion rates, by month? */
 
SELECT 
-- YEAR(website_sessions.created_at) AS YR,
-- MONTH(website_sessions.created_at) AS Mnth,
MIN(DATE(website_sessions.created_at)) AS monthly_data,
COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
COUNT(DISTINCT orders.order_id) AS orders,
COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT website_sessions.website_session_id) AS session_to_order_conversion_rate
FROM website_sessions
LEFT JOIN orders
ON website_sessions.website_session_id = orders.website_session_id
WHERE 
website_sessions.created_at < '2012-11-27'
GROUP BY 
YEAR(website_sessions.created_at),
MONTH(website_sessions.created_at);



/* For the gsearch lander test page, please estimate the revenue that test earned us. The test period was 19 Jun - 28 Jul */

SELECT 
COUNT(DISTINCT orders.order_id) AS orders,
COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT website_sessions.website_session_id) AS conversion_rate,
SUM(orders.price_usd) AS revenue,
website_sessions.utm_source,
website_pageviews.pageview_url AS landing_page
FROM website_sessions
LEFT JOIN  website_pageviews
ON website_sessions.website_session_id = website_pageviews.website_session_id
LEFT JOIN orders
ON website_sessions.website_session_id = orders.website_session_id
WHERE 
website_sessions.utm_source = 'gsearch' AND
website_sessions.utm_campaign = 'nonbrand' AND
website_sessions.created_at BETWEEN '2012-06-19' AND '2012-07-28' AND
website_pageviews.pageview_url IN ('/lander-1', '/home')
GROUP BY website_pageviews.pageview_url;

/* For the landing page test you analysed previously, it would be great to show a full conversion funnel from each of the two pages to 
orders. You can use the same time period you analysed last time (19 Jun - 28 Jul) */

CREATE TEMPORARY TABLE funnels
SELECT 
website_session_id,
MAX(home) AS to_home,
MAX(lander) AS to_lander,
MAX(products) AS to_products,
MAX(mrfuzzy) AS to_mrfuzzy,
MAX(cart) AS to_cart,
MAX(shipping) AS to_shipping,
MAX(billing) AS to_billing,
MAX(thankyou) AS to_thankyou
FROM
(SELECT 
website_sessions.website_session_id,
website_pageviews.pageview_url,
CASE WHEN website_pageviews.pageview_url = '/home' THEN 1 ELSE 0 END AS home,
CASE WHEN website_pageviews.pageview_url = '/lander-1' THEN 1 ELSE 0 END AS lander,
CASE WHEN website_pageviews.pageview_url = '/products' THEN 1 ELSE 0 END AS products,
CASE WHEN website_pageviews.pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS mrfuzzy,
CASE WHEN website_pageviews.pageview_url = '/cart' THEN 1 ELSE 0 END AS cart,
CASE WHEN website_pageviews.pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping,
CASE WHEN website_pageviews.pageview_url = '/billing' THEN 1 ELSE 0 END AS billing,
CASE WHEN website_pageviews.pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou
FROM website_sessions
LEFT JOIN website_pageviews
ON website_sessions.website_session_id = website_pageviews.website_session_id
WHERE
website_sessions.utm_source = 'gsearch' AND
website_sessions.utm_campaign = 'nonbrand' AND
website_sessions.created_at BETWEEN '2012-06-19' AND '2012-07-28') AS funnel 
GROUP BY website_session_id;


SELECT * FROM funnels;

SELECT
COUNT(DISTINCT CASE WHEN to_thankyou = 1 then website_session_id ELSE NULL END)/COUNT(DISTINCT website_session_id) AS sessions_to_orders_conversion_rate, 
CASE 
WHEN to_home = 1 THEN 'from_homepage'
WHEN to_lander = 1 THEN 'from_lander'
ELSE 'check error'
END AS landing_segment,
COUNT(DISTINCT website_session_id) AS sessions,
COUNT(DISTINCT CASE WHEN to_products = 1 then website_session_id ELSE NULL END) AS products,
COUNT(DISTINCT CASE WHEN to_mrfuzzy = 1 then website_session_id ELSE NULL END) AS mrfuzzy,
COUNT(DISTINCT CASE WHEN to_cart = 1 then website_session_id ELSE NULL END) AS cart,
COUNT(DISTINCT CASE WHEN to_shipping = 1 then website_session_id ELSE NULL END) AS shipping,
COUNT(DISTINCT CASE WHEN to_billing = 1 then website_session_id ELSE NULL END) AS billing,
COUNT(DISTINCT CASE WHEN to_thankyou = 1 then website_session_id ELSE NULL END) AS thankyou
FROM funnels
GROUP BY 2;

/* I'd love for you to quantify the impact of our billing test as well. Please analyse the lift generated from the test
(10 Sep - 10 Nov), in terms of revenue per billing page session and then pull the number of billing page sessions for the past month
to understand the monthly impact. */

SELECT * FROM orders;
SELECT * FROM website_sessions;
SELECT * FROM website_pageviews;

SELECT
COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
COUNT(DISTINCT orders.order_id) AS orders,
SUM(orders.price_usd) AS revenue,
SUM(orders.price_usd)/COUNT(DISTINCT website_sessions.website_session_id) AS revenue_per_billing_page,
website_pageviews.pageview_url
FROM website_sessions
LEFT JOIN orders
ON orders.website_session_id = website_sessions.website_session_id
LEFT JOIN website_pageviews
ON website_pageviews.website_session_id = website_sessions.website_session_id
WHERE
website_sessions.created_at BETWEEN '2012-09-10' AND '2012-11-10' AND
website_pageviews.pageview_url IN ('/billing', '/billing-2')
GROUP BY 5;

SELECT
COUNT(DISTINCT website_pageviews.website_session_id) AS sessions_past_month
from website_pageviews
WHERE
website_pageviews.created_at BETWEEN '2012-10-27' AND '2012-11-27' AND
website_pageviews.pageview_url IN ('/billing', '/billing-2');

-- Sessions past month 1193
-- Increased revenue per billing session $8.51
-- Value of billing test over past month $10,156 