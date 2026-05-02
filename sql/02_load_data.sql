-- ============================================================
-- PROJECT  : AI Jobs Market - Data Warehouse
-- FILE     : 02_load_data.sql
-- PURPOSE  : Load dimension and fact tables from staging table
-- AUTHOR   : Yuvaraj Murugan
-- CREATED  : 2026
-- ============================================================
-- PREREQUISITE : Run 01_create_schema.sql before this script.
-- SOURCE TABLE : [dbo].[ai_jobs_market] (staging / raw import)
-- ============================================================

USE AI_Jobs_DW;
GO


-- ============================================================
-- SECTION 0: VALIDATE SOURCE TABLE
-- ============================================================

SELECT COUNT(*) AS total_source_rows
FROM   dbo.ai_jobs_market;
GO


-- ============================================================
-- SECTION 1: LOAD DIMENSION TABLES
-- Order matters — all dims must load before the fact table.
-- ============================================================

-- ------------------------------------------------------------
-- 1.1  Dim_Date
-- Surrogate key format: YYYYMM (e.g., 202401 = Jan 2024)
-- ------------------------------------------------------------

INSERT INTO dw.Dim_Date
(
    date_sk,
    posting_year,
    posting_month,
    month_name,
    quarter,
    quarter_label
)
SELECT DISTINCT
    posting_year * 100 + posting_month                                              AS date_sk,
    posting_year,
    posting_month,
    DATENAME(MONTH,   DATEFROMPARTS(posting_year, posting_month, 1))                AS month_name,
    DATEPART(QUARTER, DATEFROMPARTS(posting_year, posting_month, 1))                AS quarter,
    'Q' + CAST(DATEPART(QUARTER, DATEFROMPARTS(posting_year, posting_month, 1)) AS VARCHAR(1))
        + ' ' + CAST(posting_year AS VARCHAR(4))                                    AS quarter_label
FROM dbo.ai_jobs_market;

PRINT 'Dim_Date loaded.';
GO

-- ------------------------------------------------------------
-- 1.2  Dim_JobCategory
-- ------------------------------------------------------------

INSERT INTO dw.Dim_JobCategory (job_category)
SELECT DISTINCT job_category
FROM   dbo.ai_jobs_market;

PRINT 'Dim_JobCategory loaded.';
GO

-- ------------------------------------------------------------
-- 1.3  Dim_Experience
-- experience_order maps seniority levels for sorting.
-- ------------------------------------------------------------

INSERT INTO dw.Dim_Experience (experience_level, experience_order)
SELECT DISTINCT
    experience_level,
    CASE experience_level
        WHEN 'Entry (0-2 yrs)'  THEN 1
        WHEN 'Mid (3-5 yrs)'    THEN 2
        WHEN 'Senior (6-9 yrs)' THEN 3
        WHEN 'Lead (10+ yrs)'   THEN 4
        ELSE 99
    END AS experience_order
FROM dbo.ai_jobs_market;

PRINT 'Dim_Experience loaded.';
GO

-- ------------------------------------------------------------
-- 1.4  Dim_Education
-- ------------------------------------------------------------

INSERT INTO dw.Dim_Education (education_required)
SELECT DISTINCT education_required
FROM   dbo.ai_jobs_market;

PRINT 'Dim_Education loaded.';
GO

-- ------------------------------------------------------------
-- 1.5  Dim_Country
-- ------------------------------------------------------------

INSERT INTO dw.Dim_Country (country)
SELECT DISTINCT country
FROM   dbo.ai_jobs_market;

PRINT 'Dim_Country loaded.';
GO

-- ------------------------------------------------------------
-- 1.6  Dim_RemoteWork
-- ------------------------------------------------------------

INSERT INTO dw.Dim_RemoteWork (remote_work)
SELECT DISTINCT remote_work
FROM   dbo.ai_jobs_market;

PRINT 'Dim_RemoteWork loaded.';
GO

-- ------------------------------------------------------------
-- 1.7  Dim_CompanySize
-- company_tier ranks from Big Tech (1) down to Startup (5).
-- ------------------------------------------------------------

INSERT INTO dw.Dim_CompanySize (company_size, company_tier, company_tier_label)
SELECT DISTINCT
    company_size,
    CASE company_size
        WHEN 'Big Tech (FAANG+)'    THEN 1
        WHEN 'Enterprise (5000+)'   THEN 2
        WHEN 'Mid-size (501-5000)'  THEN 3
        WHEN 'SME (51-500)'         THEN 4
        WHEN 'Startup (1-50)'       THEN 5
        ELSE 99
    END AS company_tier,
    CASE company_size
        WHEN 'Big Tech (FAANG+)'    THEN 'Tier 1'
        WHEN 'Enterprise (5000+)'   THEN 'Tier 2'
        WHEN 'Mid-size (501-5000)'  THEN 'Tier 3'
        WHEN 'SME (51-500)'         THEN 'Tier 4'
        WHEN 'Startup (1-50)'       THEN 'Tier 5'
        ELSE 'Unknown'
    END AS company_tier_label
FROM dbo.ai_jobs_market;

PRINT 'Dim_CompanySize loaded.';
GO

-- ------------------------------------------------------------
-- 1.8  Dim_Industry
-- ------------------------------------------------------------

INSERT INTO dw.Dim_Industry (industry)
SELECT DISTINCT industry
FROM   dbo.ai_jobs_market;

PRINT 'Dim_Industry loaded.';
GO

-- ------------------------------------------------------------
-- 1.9  Dim_SalaryTier
-- salary_tier_order ranks from Entry (1) to Elite (5).
-- ------------------------------------------------------------

INSERT INTO dw.Dim_SalaryTier (salary_tier, salary_tier_order)
SELECT DISTINCT
    salary_tier,
    CASE salary_tier
        WHEN 'Entry (<$100k)'           THEN 1
        WHEN 'Mid ($100-150k)'          THEN 2
        WHEN 'Upper-Mid ($150-200k)'    THEN 3
        WHEN 'Senior ($200-300k)'       THEN 4
        WHEN 'Elite (>$300k)'           THEN 5
        ELSE 99
    END AS salary_tier_order
FROM dbo.ai_jobs_market;

PRINT 'Dim_SalaryTier loaded.';
GO


-- ============================================================
-- SECTION 2: LOAD FACT TABLE
-- All dimension lookups use natural key joins.
-- ============================================================

INSERT INTO dw.Fact_JobPostings
(
    -- Foreign Keys
    date_sk,
    job_category_sk,
    experience_sk,
    education_sk,
    country_sk,
    remote_work_sk,
    company_size_sk,
    industry_sk,
    salary_tier_sk,

    -- Degenerate Dimensions
    job_id,
    job_title,
    city,

    -- Measures
    annual_salary_usd,
    salary_min_usd,
    salary_max_usd,
    years_of_experience,
    ai_salary_premium_pct,
    demand_score,
    demand_growth_yoy_pct,
    benefits_score_10,

    -- Boolean Flags
    is_senior,
    is_llm_role,
    is_remote_friendly
)
SELECT
    -- Foreign Keys (resolved via dim joins)
    d.date_sk,
    jc.job_category_sk,
    ex.experience_sk,
    ed.education_sk,
    ct.country_sk,
    rw.remote_work_sk,
    cs.company_size_sk,
    ind.industry_sk,
    st.salary_tier_sk,

    -- Degenerate Dimensions
    r.job_id,
    r.job_title,
    r.city,

    -- Measures
    r.annual_salary_usd,
    r.salary_min_usd,
    r.salary_max_usd,
    r.years_of_experience,
    r.ai_salary_premium_pct,
    r.demand_score,
    r.demand_growth_yoy_pct,
    r.benefits_score_10,

    -- Boolean Flags
    r.is_senior,
    r.is_llm_role,
    r.is_remote_friendly

FROM       dbo.ai_jobs_market   r
JOIN dw.Dim_Date        d   ON d.date_sk            = (r.posting_year * 100 + r.posting_month)
JOIN dw.Dim_JobCategory jc  ON jc.job_category      = r.job_category
JOIN dw.Dim_Experience  ex  ON ex.experience_level  = r.experience_level
JOIN dw.Dim_Education   ed  ON ed.education_required= r.education_required
JOIN dw.Dim_Country     ct  ON ct.country           = r.country
JOIN dw.Dim_RemoteWork  rw  ON rw.remote_work       = r.remote_work
JOIN dw.Dim_CompanySize cs  ON cs.company_size      = r.company_size
JOIN dw.Dim_Industry    ind ON ind.industry         = r.industry
JOIN dw.Dim_SalaryTier  st  ON st.salary_tier       = r.salary_tier;

PRINT 'Fact_JobPostings loaded.';
GO


-- ============================================================
-- SECTION 3: ROW COUNT VALIDATION
-- Compare source rows against each loaded table.
-- ============================================================

SELECT tbl, row_count
FROM (
    SELECT 'ai_jobs_market (source)'    AS tbl, COUNT(*) AS row_count FROM dbo.ai_jobs_market
    UNION ALL
    SELECT 'Dim_Date',                           COUNT(*) FROM dw.Dim_Date
    UNION ALL
    SELECT 'Dim_JobCategory',                    COUNT(*) FROM dw.Dim_JobCategory
    UNION ALL
    SELECT 'Dim_Experience',                     COUNT(*) FROM dw.Dim_Experience
    UNION ALL
    SELECT 'Dim_Education',                      COUNT(*) FROM dw.Dim_Education
    UNION ALL
    SELECT 'Dim_Country',                        COUNT(*) FROM dw.Dim_Country
    UNION ALL
    SELECT 'Dim_RemoteWork',                     COUNT(*) FROM dw.Dim_RemoteWork
    UNION ALL
    SELECT 'Dim_CompanySize',                    COUNT(*) FROM dw.Dim_CompanySize
    UNION ALL
    SELECT 'Dim_Industry',                       COUNT(*) FROM dw.Dim_Industry
    UNION ALL
    SELECT 'Dim_SalaryTier',                     COUNT(*) FROM dw.Dim_SalaryTier
    UNION ALL
    SELECT 'Fact_JobPostings',                   COUNT(*) FROM dw.Fact_JobPostings
) AS validation
ORDER BY
    CASE tbl
        WHEN 'ai_jobs_market (source)'  THEN 0
        WHEN 'Dim_Date'                 THEN 1
        WHEN 'Dim_JobCategory'          THEN 2
        WHEN 'Dim_Experience'           THEN 3
        WHEN 'Dim_Education'            THEN 4
        WHEN 'Dim_Country'              THEN 5
        WHEN 'Dim_RemoteWork'           THEN 6
        WHEN 'Dim_CompanySize'          THEN 7
        WHEN 'Dim_Industry'             THEN 8
        WHEN 'Dim_SalaryTier'           THEN 9
        WHEN 'Fact_JobPostings'         THEN 10
        ELSE 99
    END;

PRINT '====================================================';
PRINT 'Data load complete. Validation query executed above.';
PRINT '====================================================';
GO
