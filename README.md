# COVID-19 Global Trends Analysis

### 2026 EPI4932 Clinical Data Science Elective Assignment (Group 2)

This repository contains the code, data, and outputs for the **2026 Group Assignment** analysing global COVID-19 trends. The project produces time-series analyses and global visualisations of COVID-19 cases and deaths.

---

# Table of Contents

* [Project Structure](#project-structure)
* [Reproducibility](#reproducibility)
* [Running the Analysis](#running-the-analysis)
* [Software](#software)
* [Authors](#authors)

---

# Project Structure

<details>
<summary>Click to expand</summary>

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

This project uses the **`renv` package** to manage package dependencies and ensure that the analysis can be reproduced with the exact package versions used during development.

The file

```
renv.lock
```

records all package versions used in the project.

To recreate the environment on another machine:

```r
renv::restore()
```

---

# Running the Analysis

After restoring the environment, the analysis can be reproduced by rendering the report:

```r
rmarkdown::render("Final_Group_Assignment.Rmd")
```

This command runs the full analysis pipeline and regenerates all figures and outputs.

---

# Software

The analysis was conducted using:

* **R**
* **RMarkdown**
* **renv** for environment management
* **dplyr** for data manipulation
* **ggplot2** and **plotly** for visualisation
* **sf** and **rnaturalearth** for geographic mapping

---

# Authors

Group 2 – 2026 Course Assignment

* Lin
* Paulina
* Shiqiu (Q)

---

# Notes

All figures and results in the report are generated directly from the code contained in the RMarkdown documents, ensuring transparency and reproducibility.
