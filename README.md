# ✈️ Airline Flight Operations Analytics Platform

An end-to-end airline flight operations analytics project built using **Databricks, Lakeflow Spark Declarative Pipelines, SQL, and AI/BI Dashboards**.

This project analyzes synthetic domestic airline flight data for 2025 using the **Medallion Architecture (Bronze, Silver, and Gold)** to transform raw flight records into meaningful business insights.

## 📌 Project Overview

The platform helps analyze airline operational performance, route revenue, passenger capacity utilization, flight delays, and data quality.

**Dataset:** Synthetic Airline Flights Dataset  
**Records:** 1,365 raw rows  
**Period:** January–December 2025

## 🛠️ Tools & Technologies

- Databricks
- Lakeflow Spark Declarative Pipelines
- SQL
- PySpark
- Medallion Architecture
- Databricks AI/BI Dashboards

## 🏗️ Data Architecture

The project follows the Medallion Architecture:

### 1. Bronze Layer
- Ingested raw airline flight CSV data.
- Preserved source records and ingestion metadata.

### 2. Silver Layer
- Removed duplicate records using `flight_id`.
- Cleaned text fields and handled missing values.
- Derived missing delay minutes and ticket revenue.
- Categorized flights by delay.
- Separated rejected records for data-quality validation.

### 3. Gold Layer
Created business-ready analytical tables:

| Gold Table | Purpose |
|---|---|
| `gold_monthly_flights` | Monthly flight and revenue trends |
| `gold_airline_summary` | Airline operational performance |
| `gold_route_summary` | Route-level revenue and performance |
| `gold_delay_summary` | Delay categories and reasons |
| `gold_data_quality` | Data-quality metrics and reconciliation |

## 📊 Dashboard Pages

### 1. Overview
- Total Flights
- Total Passengers
- Ticket Revenue
- Delayed Flights
- Monthly Ticket Revenue Trend
- On-Time Percentage by Airline

### 2. Airlines, Routes & Delays
- Airline Performance
- Top 10 Routes by Revenue
- Flights by Delay Category
- Delayed Flights by Reason

### 3. Data Quality
- Bronze Rows
- Clean Flights
- Rejected Rows
- Duplicate Rows
- Data Quality Reconciliation
- Data Quality Issues

## 📈 Data Quality Results

| Metric | Result |
|---|---:|
| Bronze Rows | 1,365 |
| Clean Rows | 1,321 |
| Rejected Rows | 19 |
| Duplicate Rows | 25 |

**Reconciliation Check:**

`Bronze Rows = Clean Rows + Rejected Rows + Duplicate Rows`

`1,365 = 1,321 + 19 + 25`

**Status: PASSED**

## 📷 Dashboard Screenshots

Screenshots of the dashboard and successful pipeline execution are available in the `screenshots` folder.

## 📁 Repository Structure

```text
Airline-Flight-Operations-Analytics/
│
├── dataset/
│   └── airline_flights_raw.csv
│
├── sql/
│   └── airline_pipeline.sql
│
├── screenshots/
│   ├── Overview
│   ├── Airlines and Routes
│   ├── Delay Analysis
│   ├── Data Quality
│   └── Pipeline Success
│
└── README.md
```

## 💡 Key Learnings

- Implemented an end-to-end data pipeline in Databricks.
- Applied Medallion Architecture for structured data processing.
- Performed data cleaning and validation using SQL.
- Built Gold-layer analytical tables.
- Designed interactive AI/BI dashboards.
- Translated flight operations data into business insights.

## 👩‍💻 Author

**Bandi Pavani**  
Aspiring Data Analyst

- GitHub: [pavanibandi-130](https://github.com/pavanibandi-130)
- LinkedIn: [Pavani Bandi](https://linkedin.com/in/pavani-bandi-81a81127b)

---

⭐ If you find this project useful, feel free to explore the repository!
