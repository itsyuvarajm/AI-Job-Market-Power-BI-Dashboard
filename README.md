# 🤖 AI Jobs Market — Data Warehouse & Power BI Dashboard

An end-to-end data analytics project covering the global AI jobs market.
Built a **SQL Server star schema pipeline** and a **multi-page Power BI dashboard** to analyse salary trends, job demand, remote work patterns, and industry insights across **1,500+ job postings from 14 countries**.

---

## 📊 Dashboard Preview

### Page 1 — Job Market Overview
![Job Market Overview](images/img1.png)

### Page 2 — Experience, Education & Industry
![Experience, Education & Industry](images/img2.png)

---

## 🔍 Key Findings

- **AI Engineering dominates hiring** — 736 of 1,500 postings (49%) are AI Engineering roles, nearly 6× the next category (Data Science at 127)
- **Hybrid is the leading work model** — 45.73% of all AI job postings offer hybrid work, ahead of Fully Remote (29.67%) and On-site (24.6%)
- **PhD premium grows with seniority** — PhD holders earn $37K more than Associate's degree holders at Lead level ($253K vs $216K), vs only $11K more at Entry level — the credential gap widens with experience
- **Big Tech pays 42% more than Startups** — average salary of $238K (Big Tech / FAANG+) vs $168K (Startup 1–50 employees)
- **Automotive leads all industries** at $212K average salary; Education and Energy trail at $188K and $183K respectively
- **AI hiring peaked sharply in Q1** — 361 postings in March, dropping over 88% by May, with a flat low-volume tail through December
- **Senior roles dominate supply** — 49.67% of all postings are senior-level, and 21.80% are specifically LLM-focused roles
- **AI salary premium stands at 10.9%** above standard market rates across all roles and industries

---

## 🗂️ Project Structure

```
ai-jobs-market/
│
├── sql/
│   ├── 01_create_schema.sql      # Database, schema, dim & fact table DDL
│   └── 02_load_data.sql          # Staging → dimension & fact table load
│
├── images/
│   ├── img1.png                  # Dashboard — Job Market Overview
│   └── img2.png                  # Dashboard — Experience, Education & Industry
│
├── ai_job_market.pbix            # Power BI report file
└── README.md
```

---

## 🏗️ Data Architecture

### Star Schema — `AI_Jobs_DW` (SQL Server)

```
                    ┌──────────────────┐
                    │  Fact_JobPostings │
                    └────────┬─────────┘
         ┌──────────┬────────┼─────────┬──────────┐
         │          │        │         │          │
    Dim_Date  Dim_JobCategory  Dim_Experience  Dim_Education
    Dim_Country  Dim_RemoteWork  Dim_CompanySize
    Dim_Industry  Dim_SalaryTier
```

| Layer | Object | Description |
|-------|--------|-------------|
| Staging | `dbo.ai_jobs_market` | Raw CSV import table |
| Dimensions | `dw.Dim_*` — 9 tables | Conformed dimension tables |
| Fact | `dw.Fact_JobPostings` | Grain: one row per job posting |

### Key Design Decisions

- **Surrogate key format — Dim_Date:** `YYYYMM` (e.g. `202501` = Jan 2025)
- **Computed column:** `salary_range_usd = salary_max_usd − salary_min_usd` (PERSISTED)
- **Ordinal sort columns:** `experience_order`, `salary_tier_order`, `company_tier` — enable correct sort order in Power BI without custom sorting hacks
- **Boolean flags on fact:** `is_senior`, `is_llm_role`, `is_remote_friendly` (TINYINT 0/1)
- **Explicit FK constraint naming:** all foreign keys named `FK_Fact_*` for maintainability

---

## 📈 Dashboard Highlights

### Page 1 — Job Market Overview

| KPI | Value |
|-----|-------|
| Total Postings | 1.5K |
| AVG Salary | $194.89K |
| AVG Demand Score | 87.52 |
| Total Countries | 14 |

**Visuals included:**
- 6-slicer filter bar — Country · Industry · Month · Education · Experience Level · Salary Tier
- Job count by category (horizontal bar — sorted descending)
- Remote work split (donut — Hybrid / Fully Remote / On-site)
- Total postings by salary tier (horizontal bar — all 5 tiers)
- AVG salary by experience level (horizontal bar — Lead → Entry)
- Monthly postings Jan → Dec (area chart — shows Q1 hiring spike)

### Page 2 — Experience, Education & Industry

| KPI | Value |
|-----|-------|
| Senior % | 49.67% |
| LLM Roles % | 21.80% |
| AI Salary Premium % | 10.9% |
| Top Industry Salary | $212.31K |

**Visuals included:**
- AVG salary by education level (bar — PhD to Associate's)
- Job count by industry & salary tier (treemap — size = postings, detail = salary tier)
- Industry salary vs demand score sized by postings (bubble/scatter chart)
- AVG salary by company size (waterfall — Big Tech → Startup with avg reference line)
- AVG salary by industry (horizontal bar — 14 industries sorted by salary)
- AVG salary by experience & education (clustered bar — sequential orange credential color scale)

---

## 🛠️ Tech Stack

| Tool | Usage |
|------|-------|
| **SQL Server 2019** | Data warehouse, star schema design |
| **T-SQL** | DDL, ETL pipeline, row-count validation queries |
| **Power BI Desktop** | Data modelling, DAX measures, multi-page dashboard |
| **DAX** | KPI measures, % calculations, salary aggregations, FORMAT display measures |

---

## 🚀 How to Run

### 1. Set up the Database

```sql
-- Run scripts in order:
01_create_schema.sql    -- Creates DB, schema, and all dim + fact tables
02_load_data.sql        -- Loads all dims and fact from staging table
```

> **Prerequisite:** Import the raw CSV into `dbo.ai_jobs_market` before running `02_load_data.sql`.  
> The load script ends with a row-count validation query across all 10 tables.

### 2. Open the Power BI Report

1. Open `ai_job_market.pbix` in **Power BI Desktop**
2. Go to **Transform Data → Data Source Settings**
3. Update the SQL Server connection string to your local instance (`AI_Jobs_DW`)
4. Click **Refresh** — both pages will populate from your local star schema

---

## 👤 Author

**Yuvaraj Murugan**  
Data Analyst | SQL · Power BI · Python  
🌐 [iamyuvaraj.site](https://iamyuvaraj.site) · 💼 [GitHub](https://github.com/itsyuvarajm)
