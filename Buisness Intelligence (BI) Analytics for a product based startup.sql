-- Descriptive statistics for monthly revenue by product:
WITH Monthly_Rev AS(
SELECT date_trunc('month',s.OrderDate) AS Order_Month,
p.ProductName,
SUM(s.Revenue) AS Total_Revenue
FROM Subscriptions s
JOIN Products p
ON s.ProductID = p.ProductID
WHERE s.OrderDate BETWEEN '2022-01-01' AND '2022-12-31'
GROUP BY
    date_trunc('month',s.OrderDate),p.ProductName
)
SELECT ProductName,
min(Total_Revenue) AS MIN_REV,
max(Total_Revenue) AS MAX_REV,
avg(Total_Revenue) AS AVG_REV,
stddev(Total_Revenue) AS STD_DEV_REV
FROM Monthly_Rev
GROUP BY ProductName;

-- Tracking the performance of a recent email campaign
WITH Clicks_per_user AS(
SELECT USERID, COUNT(EVENTID) AS NUM_LINK_CLICKS
FROM FrontendEventLog
WHERE EVENTID = 5
GROUP BY USERID)

SELECT NUM_LINK_CLICKS,COUNT(USERID) AS NUM_USERS
FROM Clicks_per_user
GROUP BY NUM_LINK_CLICKS;

-- Payment Funnel Analysis
WITH Max_Stage AS(
SELECT SUBSCRIPTIONID,MAX(STATUSID) as maxstatus
FROM paymentstatuslog
GROUP BY SUBSCRIPTIONID
), Funnel_Stage AS(
SELECT s.SUBSCRIPTIONID,
case when maxstatus = 1 then 'PaymentWidgetOpened'
        when maxstatus = 2 then 'PaymentEntered'
        when maxstatus = 3 and currentstatus = 0 then 'User Error with Payment Submission'
        when maxstatus = 3 and currentstatus != 0 then 'Payment Submitted'
        when maxstatus = 4 and currentstatus = 0 then 'Payment Processing Error with Vendor'
        when maxstatus = 4 and currentstatus != 0 then 'Payment Success'
        when maxstatus = 5 then 'Complete'
        when maxstatus is null then 'User did not start payment process'
        end as paymentfunnelstage
FROM Subscriptions s
LEFT JOIN Max_Stage m
ON s.SUBSCRIPTIONID = m.SUBSCRIPTIONID)
SELECT paymentfunnelstage, COUNT(SUBSCRIPTIONID)  AS Subscriptions
FROM Funnel_Stage
GROUP BY paymentfunnelstage;

-- Flagging upsell oppurtunities for the sales team
SELECT CustomerID, COUNT(ProductID) AS NUM_PRODUCTS,
SUM(NumberofUsers) AS TOTAL_USERS,
CASE
WHEN SUM(NumberofUsers) >=5000 OR COUNT(ProductID) = 1 THEN 1
WHEN SUM(NumberofUsers) <5000 OR COUNT(ProductID)  <> 1 THEN 0
END AS UPSELL_OPPORTUNITY
FROM Subscriptions
GROUP BY CustomerID;

-- Tracking user activity with frontend events
SELECT UserID,
SUM(CASE WHEN fed.EventID = 1 THEN 1 ELSE 0 END) AS ViewedHelpCenterPage,
SUM(CASE WHEN fed.EventID = 2 THEN 1 ELSE 0 END) AS ClickedFAQS,
SUM(CASE WHEN fed.EventID = 3 THEN 1 ELSE 0 END) AS ClickedContactSupport,
SUM(CASE WHEN fed.EventID = 4 THEN 1 ELSE 0 END) AS SubmittedTicket
FROM FrontendEventLog fel
JOIN FrontendEventDefinitions fed
ON fel.EventID = fed.EventID
WHERE EventType = 'Customer Support'
GROUP BY fel.UserID;

-- Expiration of all active subscriptions
WITH all_subscriptions AS(
SELECT SubscriptionID, ExpirationDate, Active
FROM SubscriptionsProduct1
WHERE Active = 1
UNION
SELECT SubscriptionID, ExpirationDate, Active
FROM SubscriptionsProduct2
WHERE Active = 1)
SELECT date_trunc('year',ExpirationDate) as exp_year,
COUNT(SUBSCRIPTIONID) as subscriptions
FROM all_subscriptions
GROUP BY exp_year;

--  Analyzing subscription cancellation reasons
WITH all_cancelation_reasons AS(
SELECT subscriptionid,cancelationreason1 as cancelationreason
FROM Cancelations
WHERE cancelationreason1 IS NOT NULL
UNION
SELECT subscriptionid,cancelationreason2 as cancelationreason
FROM Cancelations
WHERE cancelationreason2 IS NOT NULL
UNION
SELECT subscriptionid,cancelationreason3 as cancelationreason
FROM Cancelations
WHERE cancelationreason3 IS NOT NULL)
SELECT
(CAST(SUM(CASE WHEN cancelationreason = 'Expensive'THEN 1 ELSE 0 END) AS FLOAT) /
COUNT(DISTINCT subscriptionid)) AS percent_expensive
FROM all_cancelation_reasons;

-- Notifying the sales team of an important business change
SELECT employees.EMPLOYEEID, employees.NAME AS employee_name,
managers.NAME AS manager_name, COALESCE(managers.EMAIL, employees.EMAIL) AS contact_email
FROM employees
LEFT JOIN employees managers
ON employees.MANAGERID = managers.EMPLOYEEID
WHERE employees.DEPARTMENT='Sales';

-- Comparing Month over Month (MoM) revenue
WITH monthly_revenue AS(
SELECT DATE_TRUNC('Month',OrderDate) AS Month,
SUM(Revenue) AS Total_Revenue
FROM subscriptions
GROUP BY DATE_TRUNC('Month',OrderDate))
SELECT current_month.Month AS current_month,
previous_month.Month AS previous_month,
current_month.Total_Revenue AS current_revenue,
previous_month.Total_Revenue AS previous_revenue
FROM monthly_revenue current_month
JOIN monthly_revenue previous_month
WHERE current_month.Total_Revenue > previous_month.Total_Revenue
AND
datediff('Month',previous_month.Month,current_month.Month) = 1;

-- Tracking sales quota progress over time
SELECT SalesEmployeeID, SaleDate, SaleAmount,
SUM(SaleAmount) OVER (PARTITION BY SalesEmployeeID
ORDER BY SaleDate) AS RUNNING_TOTAL,
CAST(SUM(SaleAmount) OVER (PARTITION BY SalesEmployeeID
ORDER BY SaleDate) AS FLOAT) / Quota AS PERCENT_QUOTA
FROM Sales s
INNER JOIN Employees e
ON s.SALESEMPLOYEEID = e.EMPLOYEEID;

--  Tracking User Payment Funnel Times
SELECT *,
 LEAD(MOVEMENTDATE,1) OVER (PARTITION BY SUBSCRIPTIONID ORDER BY MOVEMENTDATE) AS NEXTSTATUSMOVEMENTDATE,
 LEAD(MOVEMENTDATE,1) OVER (PARTITION BY SUBSCRIPTIONID ORDER BY MOVEMENTDATE) - MOVEMENTDATE AS TIMEINSTATUS
FROM PaymentStatusLog
WHERE SUBSCRIPTIONID = '38844'
ORDER BY MOVEMENTDATE;


