/*

        SQL DATA CLEANING PROJECT - GLOBAL LAYOFFS
        
Project Goal:
Clean a real-world layoffs dataset by removing duplicates,
standardizing values, handling missing data, and preparing
the dataset for further analysis.

Skills Used:
- CREATE TABLE
- INSERT
- UPDATE
- DELETE
- CTE
- Window Functions
- String Functions
- Date Functions
- ALTER TABLE

*/


-- 1. Create a Staging Table


-- View the original dataset
SELECT *
FROM layoffs;

-- Create a copy of the original table
CREATE TABLE layoffs_staging
LIKE layoffs;

-- Copy all records into the staging table
INSERT INTO layoffs_staging
SELECT *
FROM layoffs;

SELECT *
FROM layoffs_staging;


-- 2. Remove Duplicate Records


-- Identify duplicate rows using ROW_NUMBER()

SELECT *,
       ROW_NUMBER() OVER (
       PARTITION BY company,
                    location,
                    industry,
                    total_laid_off,
                    percentage_laid_off,
                    `date`,
                    stage,
                    country,
                    funds_raised_millions
       ) AS row_num
FROM layoffs_staging;

-- View only duplicate records

WITH duplicate_cte AS
(
SELECT *,
       ROW_NUMBER() OVER (
       PARTITION BY company,
                    location,
                    industry,
                    total_laid_off,
                    percentage_laid_off,
                    `date`,
                    stage,
                    country,
                    funds_raised_millions
       ) AS row_num
FROM layoffs_staging
)

SELECT *
FROM duplicate_cte
WHERE row_num > 1;

-- Create another staging table with row numbers

CREATE TABLE layoffs_staging2
(
    company TEXT,
    location TEXT,
    industry TEXT,
    total_laid_off INT,
    percentage_laid_off TEXT,
    `date` TEXT,
    stage TEXT,
    country TEXT,
    funds_raised_millions INT,
    row_num INT
);

-- Insert data along with row numbers

INSERT INTO layoffs_staging2

SELECT *,
       ROW_NUMBER() OVER (
       PARTITION BY company,
                    location,
                    industry,
                    total_laid_off,
                    percentage_laid_off,
                    `date`,
                    stage,
                    country,
                    funds_raised_millions
       ) AS row_num
FROM layoffs_staging;

-- Check duplicate rows

SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

-- Delete duplicate records

DELETE
FROM layoffs_staging2
WHERE row_num > 1;


-- 3. Standardize Data


-- Remove extra spaces from company names

UPDATE layoffs_staging2
SET company = TRIM(company);

-- Check unique industries

SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY industry;

-- Standardize Crypto values

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- Check country names

SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY country;

-- Remove trailing period from United States.

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';


-- 4. Convert Date Format

-- Convert text dates into DATE format

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;


-- 5. Handle Missing Values


-- Replace blank industries with NULL

UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

-- Fill missing industries using records
-- from the same company

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
ON t1.company = t2.company

SET t1.industry = t2.industry

WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

-- Verify remaining missing industries

SELECT *
FROM layoffs_staging2
WHERE industry IS NULL;


-- 6. Remove Unnecessary Records


-- Find rows with no layoff information

SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Delete rows that contain no useful layoff data

DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;


-- 7. Final Cleanup

-- Remove helper column

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

-- View cleaned dataset

SELECT *
FROM layoffs_staging2;