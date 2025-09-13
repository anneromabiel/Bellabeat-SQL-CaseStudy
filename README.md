# Bellabeat SQL Case Study  

This project analyzes the **Bellabeat fitness dataset** using SQL. The case study is inspired by the **Google Data Analytics Capstone Project**, where the goal is to derive actionable insights for Bellabeat, a high-tech company that manufactures health-focused smart products for women.  

The analysis is done in **SQL Server (T-SQL)** and includes **data cleaning, deduplication, and exploratory analysis** to answer key business questions.  

---

## 📂 Files in this Repository  
- `bellabeat_case_study.sql` → Complete SQL script for cleaning, processing, and analyzing the dataset.  

---

## 🛠️ Process  
1. **Data Cleaning**  
   - Rounded decimals (2 places) for consistency.  
   - Checked and removed duplicates (especially in `sleepDay_merged`).  
   - Standardized column types (dates, numeric values).  

2. **Data Analysis**  
   - Queries to explore user activity, calories, steps, sleep, and weight logs.  
   - Correlation analysis (steps vs calories, sleep vs next-day activity).  
   - User segmentation and consistency checks.  

---

## ❓ Business Questions Answered  
1. How many active users and days of data do we have?  
2. What % of days meet the 10,000-steps goal (overall + by user)?  
3. Which weekday is most/least active (steps)?  
4. What’s the relationship between steps and calories?  
5. Do days ≥10k steps burn more calories than <10k?  
6. Which intensity contributes most on high-calorie days?  
7. Does more sleep correlate with more steps next day?  
8. What is the average sleep efficiency (minutes asleep ÷ time in bed)?  
9. Segment users by average daily steps.  
10. Who is most consistent (lowest step variability)?  
11. What are the weekly trends of steps and calories?  
12. Do users who log weight consistently show better activity engagement than those who rarely log?  
13. Do users who start logging weight maintain or increase their daily steps over the following month?  

---

## 📊 Key Insights  
1. **10k Steps Goal** → Only ~32% of user-days reached the 10,000 steps target.  
2. **Calories vs Steps** → Positive correlation (~0.52), confirming activity drives calorie burn.  
3. **Sleep vs Next-Day Steps** → Weak negative correlation (-0.15), no strong link.  
4. **Consistency** → Some users walk 12k+ steps daily, others <5k (high variation).  
5. **Weight Logging** → Users who frequently log weight average ~13k steps/day, while non-loggers average ~7k.

---

## ✅ Recommendations  

- **Encourage Daily Movement** → Notifications/reminders to help users reach the 10k steps goal.  
- **Weekend Engagement** → Introduce weekend challenges to raise activity levels when engagement is typically lower.  
- **Integrate Sleep Insights** → Provide personalized feedback on sleep, but avoid overstating sleep–activity correlation.  
- **Gamify Weight Logging** → Add rewards or streaks for consistent weight tracking to sustain engagement.  
- **Personalized Coaching** → Target low-activity users (<5k/day) with tailored programs to gradually increase activity.  

---


## 🚀 Tools Used  
- **SQL Server (T-SQL)** → for queries, cleaning, and analysis.  
- **Excel/CSV** → raw dataset format before import.  
- **GitHub** → version control and sharing.  

---

## 📌 Next Steps  
- Build a **Power BI or Tableau dashboard** for visualization.  
- Explore **seasonality or clustering of users**.  
- Provide **business recommendations** for Bellabeat based on patterns.  
