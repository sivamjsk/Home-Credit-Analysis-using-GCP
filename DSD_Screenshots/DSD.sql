-- 1. How many clients live in a rented apartment
SELECT COUNT(application_train.name_housing_type)
FROM
application_train 
WHERE application_train.name_housing_type = 'Rented apartment'

-- 2. How many credit Bureau status are “Active” for “Cash Loans” (bureau and application train)
SELECT application_train.SK_ID_CURR, 
bureau.CREDIT_ACTIVE,
application_train.NAME_CONTRACT_TYPE
FROM bureau 
INNER JOIN application_train 
ON application_train.SK_ID_CURR = bureau.SK_ID_CURR
WHERE bureau.CREDIT_ACTIVE = 'Active' AND application_train.NAME_CONTRACT_TYPE = 'Cash loans'

-- 3. What is the monthly balance and credit type for the “active” loans for “labourers - occupation type” (credit_balance, application train,bureau)
SELECT DISTINCT application_train.SK_ID_CURR, 
bureau.CREDIT_ACTIVE, 
application_train.OCCUPATION_TYPE,
credit_card_balance.AMT_BALANCE,
MIN (credit_card_balance.MONTHS_BALANCE) over (PARTITION BY credit_card_balance.SK_ID_CURR) as curr_month_balance,
bureau.CREDIT_TYPE
FROM bureau 
INNER JOIN application_train 
ON application_train.SK_ID_CURR = bureau.SK_ID_CURR
INNER JOIN credit_card_balance 
ON application_train.SK_ID_CURR = credit_card_balance.SK_ID_CURR
WHERE bureau.CREDIT_ACTIVE = 'Active' AND application_train.OCCUPATION_TYPE = 'Laborers' 



-- 4. Amount paid for by each user [Target 0 and 1 [application_train.csv]] with amount payment [installments_payments.csv]
SELECT DISTINCT
application_train.SK_ID_CURR,
application_train.TARGET,
SUM (installments_payments.AMT_PAYMENT) over (PARTITION BY application_train.SK_ID_CURR) as total_amt_paid
FROM installments_payments 
INNER JOIN application_train 
ON installments_payments.SK_ID_CURR = application_train.SK_ID_CURR
ORDER BY application_train.SK_ID_CURR 
fetch next 1000 rows only
 


-- 5. what is the instalment days to pay amount [use credit card balance and instalment payments]

SELECT DISTINCT
credit_card_balance.SK_ID_CURR,
installments_payments.DAYS_INSTALMENT,
installments_payments.DAYS_ENTRY_PAYMENT,
ABS("installments_payments.DAYS_ENTRY_PAYMENT - installments_payments.DAYS_INSTALMENT) AS delay_days,
installments_payments.AMT_INSTALMENT,
installments_payments.AMT_PAYMENT
FROM credit_card_balance 
INNER JOIN installments_payments
ON credit_card_balance .SK_ID_CURR = installments_payments.SK_ID_CURR
fetch next 1000 rows only;

-- 6. What is the average number of days for decision made for the application for new clients(Days-decision and client type new - previous application) for cash loans (application train)

SELECT
AVG(TBL1.DAYS_DECISION) AS AVERAGE_DAYS_TO_DECISION 
FROM (
SELECT 
previous_application.SK_ID_CURR, 
previous_application .NAME_CLIENT_TYPE , 
previous_application.DAYS_DECISION,
application_train.NAME_CONTRACT_TYPE
FROM public.previous_application 
INNER JOIN application_train
ON application_train .SK_ID_CURR = previous_application .SK_ID_CURR 
where previous_application.NAME_CLIENT_TYPE = 'New' AND application_train.NAME_CONTRACT_TYPE = 'Cash loans'
) AS TBL1


-- 7. For each loan of self employed organization type (application_Train)  what is the Status of the Credit Bureau (CB) reported credits (bureau)

SELECT DISTINCT
application_train.SK_ID_CURR,
bureau.CREDIT_ACTIVE,
bureau.DAYS_CREDIT,
bureau.CREDIT_DAY_OVERDUE,
bureau.DAYS_CREDIT_ENDDATE,
bureau.CREDIT_TYPE,
bureau.DAYS_CREDIT_UPDATE
FROM application_train 
INNER JOIN bureau 
ON application_train.SK_ID_CURR = bureau.SK_ID_CURR
WHERE application_train.ORGANIZATION_TYPE = 'Self-employed'

-- 8. List of clients who changed their phone on the day of their application and who applied for loan on a Saturday.

SELECT DISTINCT
SK_ID_CURR,
DAYS_LAST_PHONE_CHANGE,
WEEKDAY_APPR_PROCESS_START,
application_train.NAME_CONTRACT_TYPE,
application_train.CODE_GENDER,
application_train.AMT_INCOME_TOTAL,
application_train.AMT_CREDIT,
application_train.AMT_GOODS_PRICE,
application_train.NAME_INCOME_TYPE,
application_train.NAME_EDUCATION_TYPE,
application_train.NAME_FAMILY_STATUS,
application_train.DAYS_EMPLOYED,
application_train.OCCUPATION_TYPE
FROM application_train 
where WEEKDAY_APPR_PROCESS_START = 'SATURDAY' and DAYS_LAST_PHONE_CHANGE = 0


-- 9. clients who work in  government organization provided work phone number and whose annual income is above 1 lakh.

SELECT 
SK_ID_CURR,
NAME_CONTRACT_TYPE,
CODE_GENDER,
OCCUPATION_TYPE,
ORGANIZATION_TYPE,
FLAG_WORK_PHONE,
AMT_INCOME_TOTAL
FROM application_train 
where AMT_INCOME_TOTAL >= 100000 AND FLAG_WORK_PHONE = 1 AND ORGANIZATION_TYPE = 'Government'

-- 10. Client details who are are pentioners/state servents and their contract type.

SELECT 
SK_ID_CURR,
NAME_CONTRACT_TYPE,
CODE_GENDER,
OCCUPATION_TYPE,
ORGANIZATION_TYPE,
NAME_INCOME_TYPE,
FLAG_WORK_PHONE,
AMT_INCOME_TOTAL,
NAME_CONTRACT_TYPE
FROM application_train 
where NAME_INCOME_TYPE = 'Pensioner' or NAME_INCOME_TYPE = 'State servant'

-- 11. Rank all Clients according to their income type and their credit amount

SELECT DISTINCT
SK_ID_CURR,
NAME_CONTRACT_TYPE,
NAME_INCOME_TYPE,
CNT_CHILDREN,
AMT_INCOME_TOTAL,
AMT_CREDIT,
NAME_FAMILY_STATUS,
TARGET,
DENSE_RANK() OVER (PARTITION BY NAME_INCOME_TYPE ORDER BY AMT_CREDIT ASC) ranking
FROM application_train 
order by NAME_INCOME_TYPE, ranking 


-- 12. What is the trend of each income type to have more successful credit due payments

SELECT DISTINCT
NAME_INCOME_TYPE,
TARGET,
count(TARGET)
FROM application_train 
GROUP BY NAME_INCOME_TYPE, TARGET
ORDER BY NAME_INCOME_TYPE, TARGET