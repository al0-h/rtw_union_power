# Right-to-Work Laws, Union Decline, and Employer Power  
**Evidence from Staggered Reforms in U.S. Labor Markets**  

**Author:** Alexander Leon-Hernandez  
**Replication Do Files** — *version dated 08 .06 .2025*  

---

## Table of Contents
1. [Overview](#overview)  
2. [Folder Structure](#folder-structure)  
3. [Prerequisites](#prerequisites)  
4. [Quick Start](#quick-start)  
5. [Step-by-Step Replication Guide](#step-by-step-replication-guide)  
6. [Expected Output](#expected-output)  
7. [Troubleshooting](#troubleshooting)  
8. [Citation](#citation)  
9. [Contact](#contact)  
10. [License](#license)  

---

## Overview
This repository contains all **Stata .do** scripts and auxiliary materials required to reproduce the empirical results in **“Right-to-Work Laws, Union Decline, and Employer Power: Evidence from Staggered Reforms in U.S. Labor Markets.”**  
The replication package:

* Downloads and cleans the raw data sources.  
* Constructs the key variables and analytic datasets.  
* Generates all tables and figures in the paper and online appendix.  

---

## Folder Structure
```
├── Code/            # Replication .do files
│   ├── _Archive  # Stores older code
│   └── Logs/     # Keeps logs of code
├── Data/                  # Raw data; empty; .gitignored
│   ├── CPS_ORG_Data/
│   └── CPS_ORG_dta/
├── Intm/                  # Processed data
├── Presentations/
│  ├── _Archive/              # Previous versions
│  ├── Bibliography/
│  ├── Figures/               # Final figures (.pdf, .png)
│  ├── Formatting/
│  │  └── Formatting Ref/         # AEJ LaTeX reference
│  ├── Sections/
│  └── Tables/
├── LICENSE.txt
├── README.txt
└── README.md              # This file
```

## Prerequisites
* Stata/SE or MP 18  (earlier versions ≥16 may work)
* R $\geq$ 4.2 with tidyverse (only for optional plots)
*  GNU Make (or run .do files manually)

## Quick Start

git clone https://github.com/al0-h/rtw_union_power.git
cd rtw_union_power
make demo            # builds a 100-row sample and runs a toy DiD
make clean           # removes temp files

## Step-by-Step Replication Guide
1. Place RTW_Years.xlsx in the data folder
2. In Stata, run Code/00_Master.do. If you only want to run some parts comment out the line including that do file.
Logs are saved to Code/Logs/.

## Expected Output

| Script                | Output                         | Where saved                           |
| --------------------- | ------------------------------ | ------------------------------------- |
| 03b\_TWFE\_HetT10.do  | TWFE estimates of High Union Share Industries      | Presentations/Tables/TWFE\_HetT10.pdf |
| 03c\_CSDID\_HetT10.do | CSDID estimates of High Union Share Industries | Presentations/Figures/CSDID\_HetT10.pdf   |


## Troubleshooting (short FAQ)
* “file RTW_Years.xlsx not found” → place RTW_Years.xlsx in Data/.
* Make sure that if you you have csdid install by typing "ssc install csdid" in the Stata console

## Citation 
Leon-Hernandez, Alexander (2025).
“Right-to-Work Laws, Union Decline, and Employer Power: Evidence from Staggered Reforms in U.S. Labor Markets.” Replication files, GitHub.

## Contact
alexander.leon-hernandez@utexas.edu

## License
(This repo is released under the MIT License; see LICENSE.)
