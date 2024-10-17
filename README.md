# Business Intelligence (BI) Analytics for a SaaS Company in SQL
## Project Overview
Throughout this project, I will be acting as the member of the analytics team for a SaaS company, solving a wide range of real world buisness problems in collaboration with various stakeholders at the firm.

## Background
The business in question here is a product based company offering **'basic'** and **'expert'** level subscriptions to a diverse clientale. For the scope of this project, the company's data is avaialable till the end of the year 2022. This data will be used to make decisions for 2023 and onwards. In other words, the project simulates all the analytical tasks taking place during the year 2023.

## Project Toolkit
The entire analysis for the project was done using SQL. A wide range of SQL functionalities were explored over the course of the project such as:
* INNER JOINS and SELF JOINS.
* UNION and UNION ALL.
* Common Table Expressions (CTEs).
* Aggregate functions such as 'COUNT()', 'SUM()', 'MAX()', 'MIN()', 'AVG()' etc along with the 'GROUP BY' clause.
* Date-time fucntions such as 'DATE_TRUNC()'.
* Functions to find and fill in null values such as 'COALESCE()'.
* Window functions such as 'PARTITION BY()', 'RANK()', 'ROW_NUMBER()', 'LEAD()' etc.

## Main Data Model
The entire data model / entity relationship digram for the firm is shown below with multiple fact and dimension tables:
![image](https://github.com/Sha95544/Business-Intelligence-Analytics-for-a-product-based-startup/assets/62758405/24cc2b86-4014-4c6e-b548-4164a2010414)
## Solutions to Key Buisness Problems
### Descriptive statistics for monthly revenue by product
#### Business Problem
The leadership team at the company is making goals for 2023 and wants to understand how much revenue each of the product subscriptions, 'basic' and 'expert' are generating each month. More specifically, they want to understand the distribution of monthly revenue across the past year, 2022.<br>

They've asked you the following questions:
1. How much revenue does each product usually generate each month?
2. Which product had the most success throughout all of last year?
3. Did either product fluctuate greatly each month or was the month-to-month trend fairly consistent?

The query below can be used to accomplish this task:
#### Code
```sql
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
```
![Result 1](https://github.com/Sha95544/Business-Intelligence-Analytics-for-a-product-based-startup/assets/62758405/9d416207-595e-4f0a-9857-39549fb3f190)<br>

#### Analysis
The expert product subscription genertaed more revenue than the basic one over the months however had a higher standard deviation. So although the "expert" product subscription generated a higher revenue, the revenue from the basic subscription was more consistent across the months and centered across the mean. <br><br>
### Tracking the performance of a recent email campaign
#### Business Problem
A manager on the marketing team comes to you to ask about the performance of their recent email campaign. Now that the campaign has been launched, the marketing manager wants to know how many users have clicked the link in the email. <br>

While this project was being planned, the analysts collaborated with the front-end engineers to create tracking events for the front end of the product located in the **'frontendeventlog'** table. One of these events, **eventid = 5**, is logged when the user reaches a unique landing page that is only accessed from this campaign email. Since the event tracks when a user views the unique landing page from the email, tracking eventid = 5 will be the best method to count how many users have clicked the link in the campaign email.

#### Code
Since an overall aggregate metric like an average can hide outliers and further insights under the hood, it's best to calculate the distribution of the **number of email link clicks per user**. In other words, how many users clicked the email link one time, two times, three times, and so on?
```sql
WITH Clicks_per_user AS(
SELECT USERID, COUNT(EVENTID) AS NUM_LINK_CLICKS
FROM FrontendEventLog
WHERE EVENTID = 5
GROUP BY USERID)


SELECT NUM_LINK_CLICKS,COUNT(USERID) AS NUM_USERS
FROM Clicks_per_user
GROUP BY NUM_LINK_CLICKS
```
![image](https://github.com/Sha95544/Business-Intelligence-Analytics-for-a-product-based-startup/assets/62758405/62b96912-981e-4d6a-8167-87b719c5989f)<br>
#### Analysis
Based on the results obtained, it can be seen that about half of the users returned to the email to click on the link multiple times in order to reach a unique landing page that could only be accesed from within the campaign email. These insigts would be useful for the marketing team in order to understand how the users are interacting with the email link.<br><br>

### Payment Funnel Analysis
#### Business Problem
The product manager has requested a payment funnel analysis from the analytics team; she wants to understand what the furthest point in the payment process users are getting to and where users are falling out of the process. She wants to have full visibility into each possible stage of the payment process from the user's point of view.<br>

Here's the payment process a user goes through when signing up for a subscription:
1. The user opens the widget to initiate payment process.
2. The user types in credit card information.
3. The user clicks the submit button to complete their part of the payment process.
4. The product sends the data to the third-party payment processing company.
5. The payment company completes the transaction and reports back with "complete."

This process is converted into statusids using the following mapping in the **"statusdefinition"** table below:
![image](https://github.com/Sha95544/Business-Intelligence-Analytics-for-a-product-based-startup/assets/62758405/c94d29c2-d0e4-4014-8d80-b413cffc63cf)


#### Code
```sql
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


SELECT paymentfunnelstage, COUNT(SUBSCRIPTIONID)  AS SubscriptionsFROM Funnel_Stage
GROUP BY paymentfunnelstage
```
![image](https://github.com/Sha95544/Business-Intelligence-Analytics-for-a-product-based-startup/assets/62758405/44f900ae-2205-472c-b680-2cd8d81485f6)

#### Analysis
There are 25 total users out of which 12 (roughly half of the total users) have successfully signed up for the product subscription. 7 of them have opened the paymnet widget but haven't taken any further steps. A samll chunk of users are facing some technical issues with the payment processing either on the vendor side or due to their own user error. At this stage some of the following measures can be taken: 
* Address the reasons why 12% of users (3 out of 25)  do not start the payment process. Improve call-to-action clarity and page design to guide users towards starting the process.
* Investigating and fixing vendor-related payment processing issues to prevent user frustration.
* Focus on reducing the drop-off from opening the widget to entering payment details by simplifying it's design and making the transition to entering details smoother.

Further actionable insights can be drawn as the users who just opened the payment wudget take further steps to initiate a payment submission in order to better investigate the critical stages where the users are dropping oof from the funnel.

### Flagging upsell oppurtunities for the sales team
#### Business Problem
The product team has just launched a new product offering that can be added on top of the current subscription for an increase in the customer's annual fee. The sales team first wants to test it by reaching out to a select group of customers to get their feedback before offering it to the entire customer base.

They are reaching out to ptential customers that meet one of the following conditions:

Have atleast 5000 registered users : These companies have a significant upsell oppurtunity, because they can lead to more potenital revenue owing to a large number of existing users.

Have only one product subscription: Companies that already have subscriptions for two products are not going to be willing to add on to their current subscription.

#### Code
```sql
SELECT CustomerID, COUNT(ProductID) AS NUM_PRODUCTS,
SUM(NumberofUsers) AS TOTAL_USERS,
CASE
WHEN SUM(NumberofUsers) >=5000 OR COUNT(ProductID) = 1 THEN 1
WHEN SUM(NumberofUsers) <5000 OR COUNT(ProductID)  <> 1 THEN 0
END AS UPSELL_OPPORTUNITY
FROM Subscriptions
GROUP BY CustomerID
```
![image](https://github.com/Sha95544/Business-Intelligence-Analytics-for-a-product-based-startup/assets/62758405/f6810901-331a-4cd6-b26d-f09e014681a8)

#### Analysis
The results show that customers with IDs "29335", "55533", "82772", "93888" are an upsell oppurtunity for the business as they either have subscription for just a single product or have atleast 5000 or more registered users or either satisfy both conditions.

### Tracking user activity with frontend events
#### Business Problem
The design team has recently redesigned the customer support page and want to run an A/B test in order to gauge how the newly designed page performs compared to the original one.<br>

The users will be randomly assigned into two groups: control and treatment. The users in control group will see the current customer support page, and the users in treatment will see the new page design. The analytics team needs to track user activity via frontend events (button clicking, page viewing, etc.) to inform the product team for future iterations. At the end of the experiment, the results of the control and treatment group will be compared to make a final product recommendation.<br>

The analytics team decides that it will be important to track user activity and ticket submissions on the customer support page since they could be impacted, either positively or negatively, by the design changes. The follwoing events will be tracked:
* When a user views the help center page: ViewedHelpCenterPage
* When a user clicks on the Frequently Asked Questions link: ClickedFAQs
* When a user clicks the contact customer support button: ClickedContactSupport 
* When a user clicks the submit ticket button: SubmittedTicket

#### Code
```sql
SELECT UserID,
SUM(CASE WHEN fed.EventID = 1 THEN 1 ELSE 0 END) AS ViewedHelpCenterPage,
SUM(CASE WHEN fed.EventID = 2 THEN 1 ELSE 0 END) AS ClickedFAQS,
SUM(CASE WHEN fed.EventID = 3 THEN 1 ELSE 0 END) AS ClickedContactSupport,
SUM(CASE WHEN fed.EventID = 4 THEN 1 ELSE 0 END) AS SubmittedTicket
FROM FrontendEventLog fel
JOIN FrontendEventDefinitions fed
ON fel.EventID = fed.EventID
WHERE EventType = 'Customer Support'
GROUP BY fel.UserID
```
![image](https://github.com/Sha95544/Business-Intelligence-Analytics-for-a-product-based-startup/assets/62758405/24bf5b7c-7032-4504-82be-6a5ae760d96b)


#### Analysis
The results above show the number of times an individual user has performed a certain action on the customer support page such as navigating to the FAQ section or viewing the help center page etc. This event tracking would be quite useful in the A/B test.


### Expiration of all active subscriptions
#### Business Problem
The chief growth officer wants to know when all the active subscriptios are going to expire as part of a broader effort to reduce customer churn. <br>

She is planning to launch multiple product experiments and marketing campaigns throughout 2023 to drive users to renew their subscriptions. She is paritcularly interested in understanding the impact that the churn initiative will have on the business.<br>

Because of data modeling limitations, the company was prevented from putting both products in the same table, so there are currently separate tables for each product, "subscriptionsproduct1" and "subscriptionsproduct2". Now it is the job of the analytics team to combine data from these multiple sources to find the number of active product subscriptions that are going to expire in the present and upcoming years.

#### Code
```sql
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
GROUP BY exp_year
```
![image](https://github.com/Sha95544/Business-Intelligence-Analytics-for-a-product-based-startup/assets/62758405/658458f5-4ffa-4dd0-82b9-86fad174c5b6)


#### Analysis
The results show that 5 of the buisness's active subscriptions will expire in 2023 which is more than double the total of active subscriptions that wil expire in 2024. So due to the much higher number of subscriptions expiring in the present year, it is viable for the growth officer to strategically design marketing strategies and product campaigns for 2023 in order to drive users to renew their subscriptions and thus prevent a future loss for the business.

### Analyzing subscription cancellation reasons
#### Business Problem
As the chief growth officer is tackling customer churn one of their key questions is understadning the factors why users are not renewing their subscriptions. Is it because they are not satsified with the product? Are they leaving for a competitor?. <br>

When users decide to cancel their subscription, they're able to select up to three reasons for canceling out of a preset list. Users can't select the same reason twice, and some users may even select less than three reasons and have "nu11" values in some of the cancelation reason columns. Since the economy has been tough lately, the analytics teams finds it reasonable to first pull the percent of canceled subscriptions that canceled due to the product being too expensive.

#### Code
```sql
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
FROM all_cancelation_reasons
```
![image](https://github.com/Sha95544/Business-Intelligence-Analytics-for-a-product-based-startup/assets/62758405/b76833a9-8a30-445f-9d63-12c25ea16e5e)



#### Analysis
The reuslts reveal a significant insight that about half the users (50%) that cancelled their product subscriptions did so because they found the product to be too expensive. Thus, the business would need to reconsider it's future pricing startegies in efforts to reduce the customer churn.

### Notifying the sales team of an important business change
#### Business Problem
The VP of Sales wants to notify all the managers who have direct reports in the sales department regarding an important business chnage that will affect the sales team. In an ideal sceanrio a simple report with the employee name along with the name of their manager and the manager's email address would have sufficed.<br>

However the data has certain limitations such as a manager is not logged for several employees within the database. So the query will be modified in a way to pull directly the email addresses of those employees who dont have a manager's email addresses logged in or a 'null' in place of a manager's email address .<br>

#### Code
```sql
SELECT employees.EMPLOYEEID, employees.NAME AS employee_name,
managers.NAME AS manager_name, COALESCE(managers.EMAIL, employees.EMAIL) AS contact_email
FROM employees
LEFT JOIN employees managers
ON employees.MANAGERID = managers.EMPLOYEEID
WHERE employees.DEPARTMENT='Sales'
```
![image](https://github.com/Sha95544/Business-Intelligence-Analytics-for-a-product-based-startup/assets/62758405/0691e472-63b0-4106-9b3b-49fd42a1f06a)

#### Analysis
The results above show that the manager for employees with IDs 'E738' and 'E192'is Bonnie Clark who is email is directly pulled in the rows for these employees. However since Bonnie Clarke and Roy Martin don't have a manager logged in, so the query pulls their employee email instad in order to directly notify them about the buisness change.

### Comparing Month over Month (MoM) revenue
#### Business Problem
Its time for the end of the year reporting and manager of the analytics team needs a report of the top revenue highlights for the year suggesting the analytics team highlights the months where the revenue was up Month over Month (MoM) i.e to highlight the months where the revenue was up from the previous month. The following query will be used for the task:
#### Code
```sql
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
datediff('Month',previous_month.Month,current_month.Month) = 1
```
![image](https://github.com/Sha95544/Business-Intelligence-Analytics-for-a-product-based-startup/assets/62758405/f9e142ea-11c3-4104-9db1-68d302f960ba)

#### Analysis
The results show that the revenue was up in July and then again in October 2022. The revenue in July was double that of June 2022 amounting to $32,000 while the revenue increase from September to October was quite less, totalling to about $1000. As the reports presents only the months where the revenue was up Month over Month (MoM), it can be concluded that the business saw the most significant growth between June and July in the year 2022. To summarize, these results show that the business was more profitable in the middle of the year 2022 than it was at either at the start or the end of it.

### Tracking Sales Quota progress over time
#### Business Problem
![image](https://github.com/Sha95544/Business-Intelligence-Analytics-for-a-product-based-startup/assets/62758405/3004a8ec-a336-48a2-bb5e-4ac924dcfcfe)

The sales team works diligently to sell the product, and they have quotas that they must reach in order to earn all of their commission. Because these goals are so intimately tied to revenue, the manager of the team wants to track each sales member's performance throughout the year.<br>

The sales manager expresses her concern that a single metric such as the % of quota reached won't give her visibility into the progress of the represenatatives throughout the year. Thus the analytics team suggests providing a "running_total of sales revenue" and a "percent_quota metric" that will be recalculated every time a sales member makes another sale. The query below will be used to accomplish this task:
#### Code
```sql
SELECT SalesEmployeeID, SaleDate, SaleAmount,
SUM(SaleAmount) OVER (PARTITION BY SalesEmployeeID
ORDER BY SaleDate) AS RUNNING_TOTAL,
CAST(SUM(SaleAmount) OVER (PARTITION BY SalesEmployeeID
ORDER BY SaleDate) AS FLOAT) / Quota AS PERCENT_QUOTA
FROM Sales s
INNER JOIN Employees e
ON s.SALESEMPLOYEEID = e.EMPLOYEEID
```
![image](https://github.com/Sha95544/Business-Intelligence-Analytics-for-a-product-based-startup/assets/62758405/c3d9bae1-6942-4e80-8b8e-8e97b58f0004)

#### Analysis
The following are the key insights from the sales quota progress report shown above:
* The sales representative with the employee ID "E738" has performed the best among all the other sales representatives since by almost the third quarter of 2023, they have achieved 14% above their yearly sales quota. Thus they are entitled to receive an additional amount above their pre-decided yearly commision for putting in the extra efforts for the buisness.<br>
* The representative with employee ID "E172" follows in this trail; having reached 76% of their yearly quota by the third quarter of 2023 and then by "E192" who have reached 65% of their yearly sales quota by the second quarter of 2023. 
* "E192" haven't made a sale in the third quarter of 2023 unlike the other sales reps.
* The performance of "E429" is concerning since they have only reached 26% of their yearly sales quota by the third quarter of 2023. They seriously need to take a more proactive approach if they wish to receive a significant proportion of their yearly sales commision for 2023.
* To conclude, "E738" have contributed the most to the yearly sales revenue while "E429" have contributed the least.


### Tracking User Payment Funnel Times
#### Business Problem
A customer has complained that it took too long for them complete their payment process due to there being an error with the system. The customer support team brought this issue up and asked the analytics team to investigate the payment funnel time data for **"subscriptionid= 38844"**.<br>

As subscriptions move through the payment statuses, they are logged in the "paymentstatuslog" table using the statusid to show what status they moved to. They can go back and forth and move through statuses multiple times.<br>


Each step of the payment process from the user point of view is outlined below:
1. The user opens the widget to initiate the payment process.
2. The user types in their credit card information.
3. The user clicks the "submit" button to complete their part of the payment process.
4. The product sends the data to the third-party payment company.
5. The third-party payment company completes the transaction and reports back.

This process is converted into statusid s using the following ID to definition mapping below and stored in the "statusdefinition" table:

![image](https://github.com/Sha95544/Business-Intelligence-Analytics-for-a-product-based-startup/assets/62758405/aefc94b5-4a4c-4005-ba14-e511198ff465)

The analytics team will pull the payment funnel data for subscriptionid = 38844. For each status timestamp, the time difference between that timestamp and the next chronological timestamp will be calculated in order to show how long the user was in each status before moving to the next status.
#### Code
```sql
SELECT *,
 LEAD(MOVEMENTDATE,1) OVER (PARTITION BY SUBSCRIPTIONID ORDER BY MOVEMENTDATE) AS NEXTSTATUSMOVEMENTDATE,
 LEAD(MOVEMENTDATE,1) OVER (PARTITION BY SUBSCRIPTIONID ORDER BY MOVEMENTDATE) - MOVEMENTDATE AS TIMEINSTATUS
FROM PaymentStatusLog
WHERE SUBSCRIPTIONID = '38844'
ORDER BY MOVEMENTDATE
```
![image](https://github.com/Sha95544/Business-Intelligence-Analytics-for-a-product-based-startup/assets/62758405/bc275c9b-072c-49ba-a30d-ee215350d54c)


#### **Analysis**
Based on the results above, it can be seen that the customer was in each status of the payment funnel for just a couple of seconds. The only noticeable time delay of 15 seoconds was observed in the statuses of the user getting the first system error message (statusid = 0) to correctly typing out their credit card information (statusid = 2). This time differance is quite naturally expected and other than that the entire payment process took less than a minute. Thus, the customer wasn't particularly 'stuck' in a particular status for too long as they claim to be.

## Conclusion
This project can be further enhanced by making an end to end dashboard using both SQL and a visualization tool to present key insights in a visually appealing format to prospective stakeholders.
