-- Q1. Total Revenue by Gender

SELECT
    ROUND(SUM(CASE WHEN gender = 'Male' THEN purchase_amount ELSE 0 END), 2) AS male_revenue,
    ROUND(SUM(CASE WHEN gender = 'Female' THEN purchase_amount ELSE 0 END), 2) AS female_revenue,
    ROUND(SUM(purchase_amount), 2) AS total_revenue
FROM customer;


-- Q2. Discount Customers Who Spent Above Average

SELECT customer_id, purchase_amount
FROM (
    SELECT 
        customer_id,
        purchase_amount,
        discount_applied,
        AVG(purchase_amount) OVER () AS avg_purchase
    FROM customer
) ranked
WHERE discount_applied = 'Yes'
  AND purchase_amount >= avg_purchase;


-- Q3. Top 5 Products by Average Review Rating

WITH product_ratings AS (
    SELECT 
        item_purchased,
        ROUND(AVG(CAST(review_rating AS DECIMAL(10,2))), 2) AS avg_rating,
        RANK() OVER (
            ORDER BY AVG(CAST(review_rating AS DECIMAL(10,2))) DESC
        ) AS rnk
    FROM customer
    GROUP BY item_purchased
)
SELECT item_purchased, avg_rating, rnk
FROM product_ratings
WHERE rnk <= 5
ORDER BY rnk;


-- Q4. Standard vs Express Shipping — Average Purchase Comparison

SELECT
    ROUND(AVG(CASE WHEN shipping_type = 'Standard' THEN purchase_amount END), 2) AS standard_avg,
    ROUND(AVG(CASE WHEN shipping_type = 'Express' THEN purchase_amount END), 2) AS express_avg,
    ROUND(
        AVG(CASE WHEN shipping_type = 'Express' THEN purchase_amount END)
        -
        AVG(CASE WHEN shipping_type = 'Standard' THEN purchase_amount END),
    2) AS difference
FROM customer
WHERE shipping_type IN ('Standard', 'Express');


-- Q5. Subscriber vs Non-Subscriber Spend

SELECT
    subscription_status,
    COUNT(*) AS total_customers,
    ROUND(AVG(purchase_amount), 2) AS avg_spend,
    ROUND(SUM(purchase_amount), 2) AS total_revenue,
    ROUND(
        100.0 * SUM(purchase_amount)
        / SUM(SUM(purchase_amount)) OVER (),
    2) AS revenue_share_pct
FROM customer
GROUP BY subscription_status
ORDER BY total_revenue DESC;


-- Q6. Top 5 Products by Discount Rate

SELECT
    item_purchased,
    ROUND(
        100.0 * AVG(CASE WHEN discount_applied = 'Yes' THEN 1 ELSE 0 END),
    2) AS discount_rate_pct,
    COUNT(*) AS total_purchases,
    SUM(CASE WHEN discount_applied = 'Yes' THEN 1 ELSE 0 END) AS discounted_purchases
FROM customer
GROUP BY item_purchased
ORDER BY discount_rate_pct DESC
LIMIT 5;


-- Q7. Customer Segmentation — New / Returning / Loyal

SELECT
    CASE
        WHEN previous_purchases = 1 THEN 'New'
        WHEN previous_purchases BETWEEN 2 AND 10 THEN 'Returning'
        ELSE 'Loyal'
    END AS customer_segment,
    
    COUNT(*) AS customer_count,
    ROUND(AVG(purchase_amount), 2) AS avg_spend,
    MIN(previous_purchases) AS min_purchases,
    MAX(previous_purchases) AS max_purchases

FROM customer
GROUP BY customer_segment
ORDER BY customer_count DESC;


-- Q8. Top 3 Most Purchased Products per Category

WITH ranked_items AS (
    SELECT
        category,
        item_purchased,
        COUNT(*) AS total_orders,
        DENSE_RANK() OVER (
            PARTITION BY category
            ORDER BY COUNT(*) DESC
        ) AS item_rank
    FROM customer
    GROUP BY category, item_purchased
)

SELECT
    item_rank,
    category,
    item_purchased,
    total_orders
FROM ranked_items
WHERE item_rank <= 3
ORDER BY category, item_rank;


-- Q9. Repeat Buyers (> 5 Purchases) & Subscription Status

SELECT
    subscription_status,
    COUNT(*) AS repeat_buyers,

    ROUND(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER (),
    2) AS pct_of_repeat_buyers,

    ROUND(AVG(purchase_amount), 2) AS avg_spend

FROM customer
WHERE previous_purchases > 5
GROUP BY subscription_status
ORDER BY repeat_buyers DESC;


-- Q10. Revenue Contribution by Age Group

SELECT
    age_group,

    SUM(purchase_amount) AS total_revenue,

    ROUND(
        100.0 * SUM(purchase_amount)
        / SUM(SUM(purchase_amount)) OVER (),
    2) AS revenue_share_pct,

    RANK() OVER (
        ORDER BY SUM(purchase_amount) DESC
    ) AS revenue_rank,

    ROUND(
        SUM(SUM(purchase_amount)) OVER (
            ORDER BY SUM(purchase_amount) DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ),
    2) AS cumulative_revenue

FROM customer
GROUP BY age_group
ORDER BY revenue_rank;
