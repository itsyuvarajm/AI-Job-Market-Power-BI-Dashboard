-- ============================================================
-- PROJECT  : AI Jobs Market - Data Warehouse
-- FILE     : 01_create_schema.sql
-- PURPOSE  : Create database, schema, dimension tables, and fact table
-- AUTHOR   : Yuvaraj Murugan
-- CREATED  : 2026
-- ============================================================
-- USAGE    : Run this script first before loading data.
--            Requires SQL Server 2016+ (DROP IF EXISTS support).
-- ============================================================


-- ------------------------------------------------------------
-- SECTION 0: CREATE DATABASE
-- ------------------------------------------------------------

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'AI_Jobs_DW')
BEGIN
    CREATE DATABASE AI_Jobs_DW;
    PRINT 'Database AI_Jobs_DW created.';
END
ELSE
    PRINT 'Database AI_Jobs_DW already exists. Skipping creation.';
GO

USE AI_Jobs_DW;
GO

-- ------------------------------------------------------------
-- SECTION 1: CREATE SCHEMA
-- ------------------------------------------------------------

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'dw')
BEGIN
    EXEC('CREATE SCHEMA dw');
    PRINT 'Schema dw created.';
END
ELSE
    PRINT 'Schema dw already exists. Skipping creation.';
GO


-- ============================================================
-- SECTION 2: DROP EXISTING TABLES
-- Note: Fact table must be dropped before dimension tables
--       to respect foreign key constraints.
-- ============================================================

-- Fact Table
DROP TABLE IF EXISTS dw.Fact_JobPostings;

-- Dimension Tables
DROP TABLE IF EXISTS dw.Dim_SalaryTier;
DROP TABLE IF EXISTS dw.Dim_Industry;
DROP TABLE IF EXISTS dw.Dim_CompanySize;
DROP TABLE IF EXISTS dw.Dim_RemoteWork;
DROP TABLE IF EXISTS dw.Dim_Country;
DROP TABLE IF EXISTS dw.Dim_Education;
DROP TABLE IF EXISTS dw.Dim_Experience;
DROP TABLE IF EXISTS dw.Dim_JobCategory;
DROP TABLE IF EXISTS dw.Dim_Date;

PRINT 'All existing tables dropped successfully.';
GO


-- ============================================================
-- SECTION 3: CREATE DIMENSION TABLES
-- ============================================================

-- ------------------------------------------------------------
-- Dim_Date
-- Surrogate key format: YYYYMM (e.g., 202401 for Jan 2024)
-- ------------------------------------------------------------

DROP TABLE IF EXISTS dw.Dim_Date;
GO

CREATE TABLE dw.Dim_Date (
    date_sk         INT             NOT NULL,
    posting_year    INT             NOT NULL,
    posting_month   INT             NOT NULL,
    month_name      VARCHAR(15)     NOT NULL,
    quarter         INT             NOT NULL,
    quarter_label   VARCHAR(10)     NOT NULL,

    CONSTRAINT PK_Dim_Date PRIMARY KEY (date_sk)
);
GO

PRINT 'Table dw.Dim_Date created.';
GO

-- ------------------------------------------------------------
-- Dim_JobCategory
-- ------------------------------------------------------------

DROP TABLE IF EXISTS dw.Dim_JobCategory;
GO

CREATE TABLE dw.Dim_JobCategory (
    job_category_sk INT             NOT NULL    IDENTITY(1, 1),
    job_category    VARCHAR(60)     NOT NULL,

    CONSTRAINT PK_Dim_JobCategory   PRIMARY KEY (job_category_sk),
    CONSTRAINT UQ_Dim_JobCategory   UNIQUE      (job_category)
);
GO

PRINT 'Table dw.Dim_JobCategory created.';
GO

-- ------------------------------------------------------------
-- Dim_Experience
-- experience_order enables sorting by seniority level
-- ------------------------------------------------------------

DROP TABLE IF EXISTS dw.Dim_Experience;
GO

CREATE TABLE dw.Dim_Experience (
    experience_sk       INT             NOT NULL    IDENTITY(1, 1),
    experience_level    VARCHAR(40)     NOT NULL,
    experience_order    INT             NOT NULL,

    CONSTRAINT PK_Dim_Experience    PRIMARY KEY (experience_sk),
    CONSTRAINT UQ_Dim_Experience    UNIQUE      (experience_level)
);
GO

PRINT 'Table dw.Dim_Experience created.';
GO

-- ------------------------------------------------------------
-- Dim_Education
-- ------------------------------------------------------------

DROP TABLE IF EXISTS dw.Dim_Education;
GO

CREATE TABLE dw.Dim_Education (
    education_sk        INT             NOT NULL    IDENTITY(1, 1),
    education_required  VARCHAR(60)     NOT NULL,

    CONSTRAINT PK_Dim_Education     PRIMARY KEY (education_sk),
    CONSTRAINT UQ_Dim_Education     UNIQUE      (education_required)
);
GO

PRINT 'Table dw.Dim_Education created.';
GO

-- ------------------------------------------------------------
-- Dim_Country
-- ------------------------------------------------------------

DROP TABLE IF EXISTS dw.Dim_Country;
GO

CREATE TABLE dw.Dim_Country (
    country_sk  INT             NOT NULL    IDENTITY(1, 1),
    country     VARCHAR(80)     NOT NULL,

    CONSTRAINT PK_Dim_Country   PRIMARY KEY (country_sk),
    CONSTRAINT UQ_Dim_Country   UNIQUE      (country)
);
GO

PRINT 'Table dw.Dim_Country created.';
GO

-- ------------------------------------------------------------
-- Dim_RemoteWork
-- ------------------------------------------------------------

DROP TABLE IF EXISTS dw.Dim_RemoteWork;
GO

CREATE TABLE dw.Dim_RemoteWork (
    remote_work_sk  INT             NOT NULL    IDENTITY(1, 1),
    remote_work     VARCHAR(30)     NOT NULL,

    CONSTRAINT PK_Dim_RemoteWork    PRIMARY KEY (remote_work_sk),
    CONSTRAINT UQ_Dim_RemoteWork    UNIQUE      (remote_work)
);
GO

PRINT 'Table dw.Dim_RemoteWork created.';
GO

-- ------------------------------------------------------------
-- Dim_CompanySize
-- company_tier enables sorting from Big Tech (1) to Startup (5)
-- ------------------------------------------------------------

DROP TABLE IF EXISTS dw.Dim_CompanySize;
GO

CREATE TABLE dw.Dim_CompanySize (
    company_size_sk     INT             NOT NULL    IDENTITY(1, 1),
    company_size        VARCHAR(40)     NOT NULL,
    company_tier        INT             NOT NULL,
    company_tier_label  VARCHAR(10)     NOT NULL,

    CONSTRAINT PK_Dim_CompanySize   PRIMARY KEY (company_size_sk),
    CONSTRAINT UQ_Dim_CompanySize   UNIQUE      (company_size)
);
GO

PRINT 'Table dw.Dim_CompanySize created.';
GO

-- ------------------------------------------------------------
-- Dim_Industry
-- ------------------------------------------------------------

DROP TABLE IF EXISTS dw.Dim_Industry;
GO

CREATE TABLE dw.Dim_Industry (
    industry_sk INT             NOT NULL    IDENTITY(1, 1),
    industry    VARCHAR(60)     NOT NULL,

    CONSTRAINT PK_Dim_Industry  PRIMARY KEY (industry_sk),
    CONSTRAINT UQ_Dim_Industry  UNIQUE      (industry)
);
GO

PRINT 'Table dw.Dim_Industry created.';
GO

-- ------------------------------------------------------------
-- Dim_SalaryTier
-- salary_tier_order enables sorting from Entry (1) to Elite (5)
-- ------------------------------------------------------------

DROP TABLE IF EXISTS dw.Dim_SalaryTier;
GO

CREATE TABLE dw.Dim_SalaryTier (
    salary_tier_sk      INT             NOT NULL    IDENTITY(1, 1),
    salary_tier         VARCHAR(40)     NOT NULL,
    salary_tier_order   INT             NOT NULL,

    CONSTRAINT PK_Dim_SalaryTier    PRIMARY KEY (salary_tier_sk),
    CONSTRAINT UQ_Dim_SalaryTier    UNIQUE      (salary_tier)
);
GO

PRINT 'Table dw.Dim_SalaryTier created.';
GO


-- ============================================================
-- SECTION 4: CREATE FACT TABLE
-- ============================================================

DROP TABLE IF EXISTS dw.Fact_JobPostings;
GO

CREATE TABLE dw.Fact_JobPostings (
    -- ------------------------------------------------------------
    -- Surrogate Key
    -- ------------------------------------------------------------
    fact_sk             INT             NOT NULL    IDENTITY(1, 1),

    -- ------------------------------------------------------------
    -- Foreign Keys to Dimension Tables
    -- ------------------------------------------------------------
    date_sk             INT             NOT NULL,
    job_category_sk     INT             NOT NULL,
    experience_sk       INT             NOT NULL,
    education_sk        INT             NOT NULL,
    country_sk          INT             NOT NULL,
    remote_work_sk      INT             NOT NULL,
    company_size_sk     INT             NOT NULL,
    industry_sk         INT             NOT NULL,
    salary_tier_sk      INT             NOT NULL,

    -- ------------------------------------------------------------
    -- Degenerate Dimensions (stored directly on fact)
    -- ------------------------------------------------------------
    job_id              VARCHAR(20)     NOT NULL,
    job_title           VARCHAR(100)    NOT NULL,
    city                VARCHAR(80)     NOT NULL,

    -- ------------------------------------------------------------
    -- Measures
    -- ------------------------------------------------------------
    annual_salary_usd       DECIMAL(12, 2)  NOT NULL,
    salary_min_usd          INT             NOT NULL,
    salary_max_usd          INT             NOT NULL,
    salary_range_usd        AS (salary_max_usd - salary_min_usd) PERSISTED,  -- Computed column

    years_of_experience     INT             NOT NULL,
    ai_salary_premium_pct   DECIMAL(6, 2)   NOT NULL,
    demand_score            INT             NOT NULL,
    demand_growth_yoy_pct   DECIMAL(6, 2)   NOT NULL,
    benefits_score_10       DECIMAL(4, 2)   NOT NULL,

    -- ------------------------------------------------------------
    -- Boolean Flags (0 = No, 1 = Yes)
    -- ------------------------------------------------------------
    is_senior               TINYINT         NOT NULL,
    is_llm_role             TINYINT         NOT NULL,
    is_remote_friendly      TINYINT         NOT NULL,

    -- ------------------------------------------------------------
    -- Constraints
    -- ------------------------------------------------------------
    CONSTRAINT PK_Fact_JobPostings      PRIMARY KEY (fact_sk),

    CONSTRAINT FK_Fact_Date             FOREIGN KEY (date_sk)           REFERENCES dw.Dim_Date          (date_sk),
    CONSTRAINT FK_Fact_JobCategory      FOREIGN KEY (job_category_sk)   REFERENCES dw.Dim_JobCategory   (job_category_sk),
    CONSTRAINT FK_Fact_Experience       FOREIGN KEY (experience_sk)     REFERENCES dw.Dim_Experience     (experience_sk),
    CONSTRAINT FK_Fact_Education        FOREIGN KEY (education_sk)      REFERENCES dw.Dim_Education      (education_sk),
    CONSTRAINT FK_Fact_Country          FOREIGN KEY (country_sk)        REFERENCES dw.Dim_Country        (country_sk),
    CONSTRAINT FK_Fact_RemoteWork       FOREIGN KEY (remote_work_sk)    REFERENCES dw.Dim_RemoteWork     (remote_work_sk),
    CONSTRAINT FK_Fact_CompanySize      FOREIGN KEY (company_size_sk)   REFERENCES dw.Dim_CompanySize    (company_size_sk),
    CONSTRAINT FK_Fact_Industry         FOREIGN KEY (industry_sk)       REFERENCES dw.Dim_Industry       (industry_sk),
    CONSTRAINT FK_Fact_SalaryTier       FOREIGN KEY (salary_tier_sk)    REFERENCES dw.Dim_SalaryTier     (salary_tier_sk)
);
GO

PRINT 'Table dw.Fact_JobPostings created.';
PRINT '====================================================';
PRINT 'Schema setup complete. Run 02_load_data.sql next.';
PRINT '====================================================';
GO
