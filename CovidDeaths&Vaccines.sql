--SQL Queries of COVID-19 Deaths and Vaccination rates using Our World in Data COVID-19 dataset.
Select*
From ProjectPortfolio..CovidDeaths$
Where continent is not null
Order by 3,4

-- Select data to use
Select location, date, total_cases, new_cases, total_deaths, population
From ProjectPortfolio..CovidDeaths$
Order by 1,2

--Total cases vs total deaths
-- calculates likelihood of death if contracted by country
Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
From ProjectPortfolio..CovidDeaths$
-- Edit location 
Where location like '%states%' and continent is not null
Order by 1,2

--Total cases vs population
--Shows what percentage of population got Covid
Select location, date, total_cases, population, (total_cases/population)*100 as infection_percentage
From ProjectPortfolio..CovidDeaths$
-- Edit location 
Where location like '%states%' and continent is not null
Order by 1,2

--Examining countries with the highest infection rate compared to population
Select location, population, MAX(total_cases) as highest_infection_count, MAX((total_cases/population))*100 as infection_percentage
From ProjectPortfolio..CovidDeaths$
--Edit location
Where location like '%states%' and continent is not null
Group by location, population
Order by infection_percentage desc

--Showing countries with highest death count per population
Select location, MAX(cast(total_deaths as int)) as total_death_count
From ProjectPortfolio..CovidDeaths$
Where continent is not null
Group by location
Order by total_death_count desc

--Death count by continent
Select continent, MAX(cast(total_deaths as int)) as total_death_count
From ProjectPortfolio..CovidDeaths$
Where continent is not null
Group by continent
Order by total_death_count desc

-- Global count of total cases, total deaths, and death percentage
Select sum(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, Sum(cast(new_deaths as int))/SUM(new_cases)*100 as death_percent
From ProjectPortfolio..CovidDeaths$
Where continent is not null
Order by 1,2

--Total population vs Vaccinations
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as vaccination_count
From ProjectPortfolio..CovidDeaths$ dea
join ProjectPortfolio..CovidVaccine$ vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
Order by 2,3

-- CTE
With PopVsVac (Continent, Location, date, Population, new_vaccinations, vaccination_count)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as vaccination_count
From ProjectPortfolio..CovidDeaths$ dea
join ProjectPortfolio..CovidVaccine$ vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
)
Select *, (vaccination_count/population)*100
From PopVsVac

-- Temp Table
DROP Table if exists #PercentOfPopulationVaccinated
Create Table #PercentOfPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
date datetime,
Population numeric,
new_vaccinations numeric,
vaccination_count numeric
)

Insert into #PercentOfPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as vaccination_count
From ProjectPortfolio..CovidDeaths$ dea
join ProjectPortfolio..CovidVaccine$ vac
	On dea.location = vac.location
	and dea.date = vac.date 
Select *, (vaccination_count/population)*100
From #PercentOfPopulationVaccinated

-- View creation
USE ProjectPortfolio
GO
Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.Date) as vaccination_count
--, (RollingPeopleVaccinated/population)*100
From ProjectPortfolio..CovidDeaths$ dea
Join ProjectPortfolio..CovidVaccine$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 

Select *
From PercentPopulationVaccinated
