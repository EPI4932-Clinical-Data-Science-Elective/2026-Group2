# COVID-19 Global Trends Analysis

![Language](https://img.shields.io/badge/language-R-blue)
![Reproducible](https://img.shields.io/badge/reproducible-renv-green)
![Report](https://img.shields.io/badge/report-RMarkdown-purple)
![Course](https://img.shields.io/badge/course-EPI4932-orange)
![License](https://img.shields.io/badge/license-Academic-lightgrey)

### EPI4932 – Clinical Data Science Elective

**2026 Group Assignment (Group 2)**

This repository contains the **code, data pipeline, and outputs** used to analyse global COVID-19 trends. The project investigates **temporal and spatial patterns in COVID-19 cases and deaths worldwide** using reproducible data science workflows.

The analysis produces:

* **Time-series analyses by continent**
* **Time-series analyses stratified by Human Development Index (HDI)**
* Global **choropleth maps**

All results are generated **directly from code**, ensuring full **transparency, reproducibility, and methodological clarity**.

---

# Project Overview

This project demonstrates a reproducible workflow for analysing global epidemiological data using the R ecosystem.

The analysis pipeline:

1. Imports global COVID-19 datasets
2. Cleans and structures time-series data
3. Produces visualisations of global trends
4. Generates a reproducible analytical report using **RMarkdown**

The final report integrates all results and visualisations.

---

# Key Visualisations

## COVID-19 Time-Series by Continent

<p align="center">
<img src="Outputs_Time_Series_Continent_by_Paulina/time_series_continent.png" width="75%">
</p>

Temporal evolution of COVID-19 cases across continents.

---

## COVID-19 Time-Series by Human Development Index

<p align="center">
<img src="Outputs_Time_Series_HDI_by_Lin/time_series_hdi.png" width="75%">
</p>

Comparison of COVID-19 trajectories across countries grouped by development level.

---

## Global COVID-19 Choropleth Map

<p align="center">
<img src="Outputs_Choropleth_Map_by_Shiqiu/choropleth_map.png" width="75%">
</p>

Spatial visualisation of global COVID-19 metrics using geographic mapping.

---

# Repository Structure

<details>
<summary><strong>Click to expand repository structure</strong></summary>

```
.
├── Final_Group_Assignment.Rmd
├── Final_Group_Assignment.html
├── Reproducible_Environment_Management.Rmd
├── Reproducible_Environment_Management.html
│
├── open_covid_data/
│
├── Outputs_Choropleth_Map_by_Shiqiu/
├── Outputs_Time_Series_Continent_by_Paulina/
├── Outputs_Time_Series_HDI_by_Lin/
│
├── renv/
├── renv.lock
│
├── .gitignore
├── .Rprofile
├── .RData
├── .Rhistory
└── 2026-Group2.Rproj
```

</details>

---

# Reproducibility

This project uses the **`renv`** package to ensure reproducible dependency management.

The file:

```
renv.lock
```

records the exact versions of all R packages used during development.

To recreate the environment:

```r
renv::restore()
```

This installs all required packages with the precise versions specified in the lockfile.

---

# Running the Analysis

After restoring the environment, the full analysis pipeline can be reproduced by rendering the report:

```r
rmarkdown::render("Final_Group_Assignment.Rmd")
```

This command:

* loads the dataset
* executes the full analysis pipeline
* regenerates all figures
* rebuilds the final HTML report

---

# Software Stack

| Tool              | Purpose                               |
| ----------------- | ------------------------------------- |
| **R**             | Statistical computing                 |
| **RMarkdown**     | Reproducible analytical reporting     |
| **renv**          | Environment and dependency management |
| **dplyr**         | Data manipulation                     |
| **ggplot2**       | Data visualisation                    |
| **plotly**        | Interactive visualisation             |
| **sf**            | Spatial data processing               |
| **rnaturalearth** | Global geographic datasets            |

---

# Authors

**Group 2 – EPI4932 Clinical Data Science**

* Lin
* Paulina
* Shiqiu (Q)

---

# Reproducible Research Statement

All figures, tables, and results presented in this repository are generated directly from the analysis code contained in the RMarkdown documents.

The use of **`renv` environment management** ensures that the analysis can be reproduced with identical package versions, supporting transparency, reproducibility, and scientific reliability.
