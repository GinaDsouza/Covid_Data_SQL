--Data exploration guided project
--We explore the data to see how covid impacted India

SELECT *
FROM Project..CovidDeaths
WHERE continent is not NULL
ORDER BY 3,4

SELECT *
FROM Project.dbo.CovidVaccinations
ORDER BY 3,4

--Selecting relevent data
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM Project..CovidDeaths
WHERE continent is not NULL
ORDER BY 1,2

--Total cases vs total deaths
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentatge
FROM Project..CovidDeaths
WHERE location like '%India%' AND continent is not NULL
ORDER BY 1,2
--the likelihood of dying once u were infected reached a peak of a little above 3%

--total cases vs population
SELECT location, date, population, total_cases, (total_cases/population)*100 AS InfectedPercentatge
FROM Project..CovidDeaths
WHERE location like '%India%' AND continent is not NULL
ORDER BY 1,2

--To see the highest infected percentage in India
SELECT location, date, population, total_cases, (total_cases/population)*100 AS InfectedPercentatge
FROM Project..CovidDeaths
WHERE location like '%India%' AND continent is not NULL
ORDER BY 5 desc
--infected percentage reached a little over 1%

-- highest infection rate vs population
SELECT location, population, MAX(total_cases) AS Highest_Infection_Count, MAX((total_cases/population))*100 AS InfectedPercentatge
FROM Project..CovidDeaths
WHERE continent is not NULL
GROUP BY location, population
ORDER BY InfectedPercentatge desc
--Andorra has the highest infected percentage(~17%) out of all the countries whose data is available

-- Highest death count in terms of location
SELECT location, MAX(CAST(total_deaths AS int)) AS Highest_Death_Count
FROM Project..CovidDeaths
WHERE continent is not NULL
GROUP BY location
ORDER BY Highest_Death_Count desc
--US has the highest death count (576232)

--Highest death count in terms of continent
SELECT continent, MAX(CAST(total_deaths AS int)) AS Highest_Death_Count
FROM Project..CovidDeaths
WHERE continent is not NULL
GROUP BY continent
ORDER BY Highest_Death_Count desc
--The Highest death count is in North America (576232)
-- the above query is not giving us accurate data. eg: the value in north america seems to have only united states value and no canada values

--The below commented query is used to see why the above query didnt work as intended
/*SELECT location
FROM Project..CovidDeaths
WHERE continent like '%North America%' */

--Trying a different approach as done by Alex The Analyst
SELECT location, MAX(CAST(total_deaths AS int)) AS Highest_Death_Count
FROM Project..CovidDeaths
WHERE continent is NULL
GROUP BY location
ORDER BY Highest_Death_Count desc
--The below query is a query I wrote on my own. It gives the same result as the above query
--but without 'World', 'European Union', 'International' locations
SELECT continent, SUM(Highest_Death_Count) AS Total_Continent_death
FROM (
SELECT continent, location, MAX(CAST(total_deaths AS int)) AS Highest_Death_Count
FROM Project..CovidDeaths
WHERE continent is not NULL
GROUP BY location, continent
) AS Subquery
GROUP BY continent
ORDER BY Total_Continent_death desc
--Europe had the highest Death count

/*--continents with highest death count per population
SELECT continent, MAX(CAST(total_deaths AS int)) AS Highest_Death_Count
FROM Project..CovidDeaths
WHERE continent is not NULL
GROUP BY continent
ORDER BY Highest_Death_Count desc*/

-- GLOBAL NUMBERS
SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS int)) AS total_deaths, SUM(CAST(new_deaths as int))/SUM(new_cases)*100 AS Death_percentage
FROM Project..CovidDeaths
WHERE continent is not NULL
--GROUP BY date
ORDER BY 1,2

-- joining the 2 tables
SELECT *
FROM Project..CovidDeaths dea
JOIN Project..CovidVaccinations vac
    ON dea.location = vac.location
	AND dea.date = vac.date

-- total population vs vaccinations
---below we try to make a rolling count of the new_vaccinations column, i.e the value in the last column is the previous values in new_vaccinations addded up
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_ppl_vaccinated
FROM Project..CovidDeaths dea
JOIN Project..CovidVaccinations vac
    ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not NULL 
ORDER BY 1,2,3

--now we attempt to find the total population vs vaccinations but we have to make a temp table as we cannot use a recently calculated column for further calculations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_ppl_vaccinated
FROM Project..CovidDeaths dea
JOIN Project..CovidVaccinations vac
    ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not NULL 
ORDER BY 1,2,3

--we gonna do this using 2 methods. method 1: using CTE
WITH POPvsVAC (Continent, Location, Date, Population, new_vaccinations,rolling_ppl_vaccinated)
AS(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_ppl_vaccinated
FROM Project..CovidDeaths dea
JOIN Project..CovidVaccinations vac
    ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not NULL
--ORDER BY 1,2,3
)
SELECT *,(rolling_ppl_vaccinated/Population)*100 AS Fraction_Vaccinated
FROM POPvsVAC
WHERE Location LIKE '%Gibraltar%'

--Checking which country has highest fraction of the population vaccinated i.e which country did a good job vaccinating its population
 -- within the date 2021-04-30
WITH POPvsVAC (Continent, Location, Date, Population, new_vaccinations,rolling_ppl_vaccinated)
AS(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_ppl_vaccinated
FROM Project..CovidDeaths dea
JOIN Project..CovidVaccinations vac
    ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not NULL
--ORDER BY 1,2,3
)
SELECT Location, MAX((rolling_ppl_vaccinated/Population)*100) AS Fraction_Vaccinated
FROM POPvsVAC
GROUP BY Location 
ORDER BY 2 DESC
--It looks like the country 'Gibraltar' and 'Israel' have Vaccinated people more than their population. I am not sure why this is the 
 --case but I checked the data and the rolling_ppl_vaccinated count is more than these countries' population. It might be that the
 --booster dose of the covid vaccine is being counted as a new vaccination.

--method 2: temp table
DROP TABLE IF EXISTS #PercentPopulationVaccinated --always add this so that u can edit the temp table after creating it 
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
loaction nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_ppl_vaccinated numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_ppl_vaccinated
FROM Project..CovidDeaths dea
JOIN Project..CovidVaccinations vac
    ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not NULL 
--ORDER BY 1,2,3

SELECT *,(rolling_ppl_vaccinated/Population)*100
FROM #PercentPopulationVaccinated

--Creating view to store data for later visualizations (view is a permanent table which u can use later to make viz)
USE Project --used so that it appreared in view
GO --same as above comment
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_ppl_vaccinated
FROM Project..CovidDeaths dea
JOIN Project..CovidVaccinations vac
    ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not NULL 
--ORDER BY 1,2,3
