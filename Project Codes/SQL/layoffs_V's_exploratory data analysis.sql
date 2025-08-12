USE world_layoffs;

SELECT * FROM layoffs;

/*
To perform exploratory data analysis (EDA), we need to make sure the data we're gonna be using is clean and ready to be analyzed.
In order to do that, we will be doing these steps:
1. Remove Duplicates
2. Standardize the Data
3. Null / Missing Values
4. Remove Any Columns / Rows (if necessary)
*/

-- Making a "checkpoint" so the real data is safe
CREATE TABLE layoffs_staging
LIKE layoffs;

INSERT layoffs_staging
SELECT * 
FROM layoffs;

-- 1. Remove Duplicates (on this data, we don't have the identifier, so it's a little bit more complicated to find duplicates)
SELECT *, 
ROW_NUMBER() OVER(PARTITION BY company, industry, total_laid_off, percentage_laid_off, `date`) AS row_num
FROM layoffs_staging;

WITH duplicate_cte AS
(
SELECT *, 
ROW_NUMBER() OVER(PARTITION BY company, industry, total_laid_off, percentage_laid_off, `date`, funds_raised_millions) AS row_num
FROM layoffs_staging
)
SELECT * FROM duplicate_cte
WHERE row_num > 1; -- Finding data that has more than 1 same values on company, industry, total_laid_off, percentage_laid_off, date, and funds_raised_millions

-- Checking all one by one to make sure it's real duplicates (optional but just to be safe)
SELECT * 
FROM layoffs_staging 
WHERE company = 'Casper';

SELECT * 
FROM layoffs_staging 
WHERE company = 'Cazoo';

SELECT * 
FROM layoffs_staging 
WHERE company = 'Hibob';

SELECT * 
FROM layoffs_staging 
WHERE company = 'Wildlife Studios';

SELECT * 
FROM layoffs_staging 
WHERE company = 'Yahoo';

-- Now, we're making another table with the same data from layoff_staging but adding row_num as a new column
-- Right click layoffs_staging -> copy to clipboard -> create statement
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT * FROM layoffs_staging2;

INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(PARTITION BY company, industry, total_laid_off, percentage_laid_off, `date`, funds_raised_millions) AS row_num
FROM layoffs_staging;

-- Deleting duplicate
SELECT * FROM layoffs_staging2
WHERE row_num > 1;

DELETE 
FROM layoffs_staging2
WHERE row_num > 1;



-- 2. Standardizing Data
SELECT * FROM layoffs_staging2;

SELECT DISTINCT(company)
FROM layoffs_staging2
ORDER BY 1;

SELECT TRIM(company)
FROM layoffs_staging2; 

UPDATE layoffs_staging2
SET company = TRIM(company); -- Updating company from the table by deleting extra spaces

SELECT * FROM layoffs_staging2;

SELECT DISTINCT(industry)
FROM layoffs_staging2
ORDER BY 1;

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%'; -- Standardizing names that are similiar to just have 1 name

SELECT DISTINCT(location)
FROM layoffs_staging2
ORDER BY 1;

SELECT DISTINCT(country)
FROM layoffs_staging2
ORDER BY 1;

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%'; -- Removing some data from United States that has extra dot in the end

-- Change data type from text to date
SELECT `date`,
STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;



-- 3. Null / Missing Values
SELECT *
FROM layoffs_staging2
WHERE industry IS NULL OR
industry = "";

-- Checking each company one by one and add some additional notes for myself
SELECT *
FROM layoffs_staging2
WHERE company = "Airbnb";
-- Industry = Travel

SELECT *
FROM layoffs_staging2
WHERE company = "Bally's Interactive";
-- Industry = UNKNOWN, Total_laid_off = NULL

SELECT *
FROM layoffs_staging2
WHERE company = "Carvana";
-- Industry = Transportation

SELECT *
FROM layoffs_staging2
WHERE company = "Juul";
-- Industry = Consumer, Percentage_laid_off = NULL

-- Changing all the blanks to null
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

SELECT * 
FROM layoffs_staging2 x1
JOIN layoffs_staging2 x2
	ON x1.company = x2.company
WHERE x1.industry IS NULL
AND x2.industry IS NOT NULL;

UPDATE layoffs_staging2 x1
JOIN layoffs_staging2 x2
	ON x1.company = x2.company
SET x1.industry = x2.industry
WHERE x1.industry IS NULL
AND x2.industry IS NOT NULL; -- Updating NULL industry from rows that has the same company to be replaced with the same one

SELECT * FROM layoffs_staging2;

-- 4. Remove any columns (/rows)
-- These can't quite help the analysis, but deleting rows needs to be extra cautious, so delete only what don't matter at all
SELECT * FROM layoffs_staging2
WHERE total_laid_off IS NULL AND 
percentage_laid_off IS NULL;

DELETE FROM layoffs_staging2
WHERE total_laid_off IS NULL AND 
percentage_laid_off IS NULL;

SELECT * FROM layoffs_staging2;

ALTER TABLE layoffs_staging2
DROP COLUMN row_num; -- Deleting row_num column from the layoffs_staging2 because the data cleaning process is done



/*
Now that we cleaned the data, we can start the exploratory data analysis process from here.
I usually split it into 3 parts for the EDA process:
1. Overview and summary stats
2. Breakdowns
3. Trend and ranking analysis
*/

/* 1. General scanning */
SELECT *
FROM layoffs_staging2;

-- Data range -> 2020-03-11	- 2023-03-06
SELECT MIN(`date`), MAX(`date`)
FROM layoffs_staging2;

-- Looking at highest people that got laid off -> 12000 people in a day
SELECT MAX(total_laid_off)
FROM layoffs_staging2;

-- Finding total layoffs by year -> 2023 (125677), 2022 (160661), 2021 (15823), 2020 (80998), NULL (500)
SELECT YEAR(`date`), SUM(total_laid_off) AS total_layoffs
FROM layoffs_staging2
GROUP BY YEAR(`date`)
ORDER BY 1 DESC;

-- Finding total layoffs by country -> United States (256559), India (35993), Netherlands (17220), ...
SELECT country, SUM(total_laid_off) AS total_layoffs
FROM layoffs_staging2
GROUP BY country
ORDER BY 2 DESC;

-- Finding total layoffs by industry -> Consumer (45182), Retail (43613), Other (36289), ...
SELECT industry, SUM(total_laid_off) AS total_layoffs
FROM layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC;

-- Finding average layoffs percentage by industry -> Aerospave (0.57%), Education (36%), Travel (35%), ...
SELECT industry, ROUND(AVG(percentage_laid_off), 2) AS average_layoffs
FROM layoffs_staging2
WHERE percentage_laid_off IS NOT NULL
GROUP BY industry
ORDER BY 2 DESC;

/* 2. Breakdowns */
-- Looking at all bankrupts company by checkin the percentage of 1 (100%)
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;

-- Looking at companies with highest total layoffs -> Amazon (18150), Google (12000), Meta (11000), ...
SELECT company, SUM(total_laid_off) AS total_layoffs
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;

-- Finding total layoffs by stage -> Post-IPO (204132), Unknown (40716), Acquired (27576), ...
SELECT stage, SUM(total_laid_off) AS total_layoffs
FROM layoffs_staging2
GROUP BY stage
ORDER BY 2 DESC;

-- Finding total layoffs per month
SELECT MONTH(`date`) AS month, SUM(total_laid_off) AS total_layoffs
FROM layoffs_staging2
GROUP BY month
ORDER BY month;



/* 3. Trend and ranking analysis */
-- Rolling total from total layoffs by month -> Starts from 9628, Ends with 383159
WITH Rolling_Total AS
(
	SELECT SUBSTRING(`date`,1,7) AS `MONTH`, SUM(total_laid_off) AS total_layoffs
	FROM layoffs_staging2
	WHERE SUBSTRING(`date`,1,7) IS NOT NULL
	GROUP BY `MONTH`
	ORDER BY 1
)
SELECT `MONTH`, total_layoffs, SUM(total_layoffs) OVER(ORDER BY `MONTH`) AS rolling_total
FROM Rolling_Total;

-- Total layoffs yearly by every company, sorted by total layoffs
SELECT company, YEAR(`date`), SUM(total_laid_off) AS total_layoffs
FROM layoffs_staging2
WHERE YEAR(`date`) IS NOT NULL
GROUP BY company, YEAR(`date`)
ORDER BY 3 DESC;

-- Top 5 companies with total layoffs yearly using DENSE RANK -> Top 1 2020 = Uber (7525), Top 1 2021 = Bytedance (3600), ...
WITH Company_Year (company, years, total_laid_off) AS
(
	SELECT company, YEAR(`date`), SUM(total_laid_off) AS total_layoffs
	FROM layoffs_staging2
	WHERE YEAR(`date`) IS NOT NULL
	GROUP BY company, YEAR(`date`)	
), Company_Year_Rank AS
(
	SELECT *, DENSE_RANK() OVER(PARTITION BY years ORDER BY total_laid_off DESC) AS Ranking
	FROM Company_Year
	ORDER BY years
)
SELECT * 
FROM Company_Year_Rank
WHERE Ranking <= 5;

-- Worst month of the dataset (highest total layoffs) -> 2023-01 (84714 people laid off)
SELECT DATE_FORMAT(date, '%Y-%m') AS bulan, SUM(total_laid_off) AS total_layoff
FROM layoffs_staging2
GROUP BY bulan
ORDER BY total_layoff DESC
LIMIT 1;

-- All the steps applied here is using data and steps from Youtube - Alex The Analyst - Learn SQL Beginner to Advanced in Under 4 Hours
-- https://www.youtube.com/watch?v=OT1RErkfLNQ