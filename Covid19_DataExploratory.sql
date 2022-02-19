--Create a table from the CovidDeaths file and import to SQL

CREATE TABLE public."SQL_CovidDeaths"
(
    iso_code varchar,
    continent varchar,
    location varchar,
    reported_date varchar,
    population real,
    total_cases real,
    new_cases real,
    new_cases_smoothed real,
    total_deaths real,
    new_deaths real,
    new_deaths_smoothed real,
    total_cases_per_million real,
    new_cases_per_million real,
    new_cases_smoothed_per_million real,
    total_deaths_per_million real,
    new_deaths_per_million real,
    new_deaths_smoothed_per_million real,
    reproduction_rate real,
    icu_patients real,
    icu_patients_per_million real,
    hosp_patients real,
    hosp_patients_per_million real,
    weekly_icu_admissions real,
    weekly_icu_admissions_per_million real,
    weekly_hosp_admissions real,
    weekly_hosp_admissions_per_million real
);

SELECT * FROM public."SQL_CovidDeaths";

COPY public."SQL_CovidDeaths"
FROM '/Users/hamaiphuongvy/Desktop/CovidDeaths.csv' 
DELIMITER ','
CSV HEADER;

ALTER TABLE public."SQL_CovidDeaths"
ALTER COLUMN reported_date TYPE date USING (reported_date::text::date);

SELECT * FROM public."SQL_CovidDeaths";

--Total Cases vs. Total Deaths in the United States
--This table demonstrates the percentage of people died out of those who were infected with Covid-19.

SELECT location, reported_date, total_cases, new_cases, total_deaths, 
(total_deaths/total_cases)*100 AS DeathPercentage
FROM public."SQL_CovidDeaths"
WHERE location LIKE '%States%'
AND continent IS NOT null
ORDER BY 1,2;

--Total Cases vs. Population in the United States
--This table demonstrates the percentage of people who got Covid out of their nations' population.

SELECT location, reported_date, total_cases, population, 
(total_cases/population)*100 AS InfectedPeoplePercentage
FROM public."SQL_CovidDeaths"
WHERE location LIKE '%States%'
AND continent IS NOT null
ORDER BY 1,2;

--Which nation has the highest infection rate?

SELECT location, population, 
MAX(total_cases) AS HighestInfectionCount,
MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM public."SQL_CovidDeaths"
WHERE total_cases IS NOT null AND population IS NOT null
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC;

--From the result table, Andorra has the highest infection rate.

--Which nation has the highest death count per its population?

SELECT location, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM public."SQL_CovidDeaths"
WHERE continent IS NOT null AND total_deaths IS NOT null
GROUP BY location
ORDER BY TotalDeathCount DESC;

--From the result table, the United States has the highest number of casualties due to Covid.

--Which continent has the highest death count per its population?

SELECT continent, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM public."SQL_CovidDeaths"
WHERE continent IS NOT null AND total_deaths IS NOT null
GROUP BY continent
ORDER BY TotalDeathCount DESC;

--From the result table, North America has the highest number of casualties due to Covid.

--Covid-19 cases and deaths over time (from Jan 2020 to Feb 2022)

SELECT reported_date, SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS int)) AS total_deaths, 
SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 AS DeathPercentage
FROM public."SQL_CovidDeaths"
WHERE continent IS NOT null
AND total_cases IS NOT null
GROUP BY reported_date
ORDER BY 1,2;

--Create a table from the file CovidVaccinations and import to SQL

CREATE TABLE public."SQL_CovidVaccinations"
(
    iso_code varchar,
    continent varchar,
    location varchar,
    reported_date varchar,
new_tests real,
	total_tests real,
	total_tests_per_thousand real,
	new_tests_per_thousand real,
	new_tests_smoothed real,
	new_tests_smoothed_per_thousand real,
	positive_rate real,
	tests_per_case real, 
	tests_units varchar,
	total_vaccinations real,
	people_vaccinated real,
	people_fully_vaccinated real,
	total_boosters real,
	new_vaccinations real,
	new_vaccinations_smoothed real,
	total_vaccinations_per_hundred real,
	people_vaccinated_per_hundred real,
	people_fully_vaccinated_per_hundred real,
	total_boosters_per_hundred real,
	new_vaccinations_smoothed_per_million real,
	new_people_vaccinated_smoothed real,
	new_people_vaccinated_smoothed_per_hundred real,
	median_age real,
	aged_65_older real,
	aged_70_older real,
	gdp_per_capita real,
	extreme_poverty real,
	cardiovasc_death_rate real,
	diabetes_prevalence real,
	female_smokers real,
	male_smokers real,
	handwashing_facilities real,
	hospital_beds_per_thousand real,
	life_expectancy real,
);

SELECT * FROM public."SQL_CovidVaccinations";

COPY public."SQL_CovidVaccinations"
FROM '/Users/hamaiphuongvy/Desktop/CovidVaccinations.csv' 
DELIMITER ','
CSV HEADER;

ALTER TABLE public."SQL_CovidVaccinations"
ALTER COLUMN reported_date TYPE date USING (reported_date::text::date);

-- JOIN function

SELECT * 
FROM public."SQL_CovidDeaths" dea
JOIN public."SQL_CovidVaccinations" vac
	ON dea.location = vac.location
	AND dea.reported_date = vac.reported_date;
	
--View the number of people getting vaccinated over time by location
	
SELECT dea.continent, dea.location, dea.reported_date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.reported_date) AS RollingPeopleVaccinated
FROM public."SQL_CovidDeaths" dea
JOIN public."SQL_CovidVaccinations" vac
	ON dea.location = vac.location
	AND dea.reported_date = vac.reported_date
WHERE dea.continent IS NOT null 
ORDER BY 2,3;

--Create a temporary Table

CREATE TABLE PercentPopulationVaccinated
(continent varchar,
location varchar,
reported_date date,
population real,
new_vaccinations real,
rollingpeoplevaccinated real
);

INSERT INTO PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.reported_date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.reported_date) AS rollingpeoplevaccinated
FROM public."SQL_CovidDeaths" dea
JOIN public."SQL_CovidVaccinations" vac
	ON dea.location = vac.location
	AND dea.reported_date = vac.reported_date
WHERE dea.continent IS NOT null;

SELECT *, (rollingpeoplevaccinated/population)*100 AS percentpopuvax
FROM PercentPopulationVaccinated;

--Creating View to store data for visualization

CREATE VIEW PercentPopulationVaccinated_View1 AS 
SELECT dea.continent, dea.location, dea.reported_date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.reported_date) AS rollingpeoplevaccinated
FROM public."SQL_CovidDeaths" dea
JOIN public."SQL_CovidVaccinations" vac
	ON dea.location = vac.location
	AND dea.reported_date = vac.reported_date
WHERE dea.continent IS NOT null;

SELECT * FROM PercentPopulationVaccinated_View1;

