# Global COVID-19 Case and Mortality Patterns Across Development Levels and Regions: An Exploratory Data Analysis

> **Note:**  
> The final submission is contained in the `main` branch.  
> The branch `20260305-cds-group-2-final-assignment-same-as-main` contains identical content and was used during final preparation.

![Language](https://img.shields.io/badge/language-R-blue)
![Reproducible](https://img.shields.io/badge/reproducible-renv-green)
![Report](https://img.shields.io/badge/report-RMarkdown-purple)
![Course](https://img.shields.io/badge/course-EPI4934B-orange)
![License](https://img.shields.io/badge/license-Academic-lightgrey)

> [!IMPORTANT]
> **IMPORTANT REPRODUCIBILITY NOTICE — PLEASE READ BEFORE RUNNING THE ANALYSIS**
>
> To ensure that this project can be reproduced exactly, the analysis depends on the **specific R package environment recorded in `renv.lock`.**
>
> Before running the analysis or rendering the report, please restore the project environment:
>
> ```r
> renv::restore()
> ```
>
> This installs the **exact package versions used during development**.
>
> If the environment is not restored first, the project may:
>
> • fail to run  
> • encounter missing package errors  
> • produce results or figures that differ from the original analysis
>
> Thank you for restoring the environment before running the report.

---

### EPI4934B – Clinical Data Science
**2026 Group Assignment (Group 2)**

This repository contains a **reproducible analysis of global COVID-19 trends**, including:

- Time-series analyses by **continent**
- Time-series analyses by **Human Development Index (HDI)**
- Global **choropleth maps**

All results are generated **directly from code using R and RMarkdown**, ensuring transparency and reproducibility.

---

# Key Visualisations

### COVID-19 Time-Series by Continent

<p align="center">
<img src="Figures/Time_Series_Continent.png" width="75%">
</p>

---

### COVID-19 Time-Series by Human Development Index

<p align="center">
<img src="Figures/Time_Series_HDI.png" width="75%">
</p>

---

### Global COVID-19 Choropleth Map

<p align="center">
<img src="Figures/Choropleth_Map.png" width="75%">
</p>

---

# Running the Analysis

### 1. Restore the environment

```r
renv::restore()
````

### 2. Render the report

```r
rmarkdown::render("EPI4934B_Group_2_Final_Assignment.Rmd")
```

This command will:

* restore the package environment
* load the dataset
* execute the analysis pipeline
* regenerate all figures
* rebuild the final HTML report (`EPI4934B_Group_2_Final_Assignment.html`)

---

# Repository Structure

```
.
├── EPI4934B_Group_2_Final_Assignment.Rmd
├── EPI4934B_Group_2_Final_Assignment.html
├── EPI4934B_Group_2_Abstract_Figures.pdf
│
├── Reproducible_Environment_Management.Rmd
├── Reproducible_Environment_Management.html
│
├── Figures/
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
│
├── README.md
├── README.html
│
└── 2026-Group2.Rproj
```

---

# Software

* **R**
* **RMarkdown**
* **renv**
* **dplyr**
* **ggplot2**
* **plotly**
* **sf**
* **rnaturalearth**

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
