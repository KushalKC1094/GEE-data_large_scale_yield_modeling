# GEE Data: Large-Scale Yield Modeling

Research code for agricultural yield analysis using Google Earth Engine (GEE) and R.

This repository contains scripts developed for previous research on agricultural yield modeling using vegetation indices, and weather variables. It is preserved as a reference resource for students and researchers who wish to understand, reuse, or extend the existing workflows.

> **Repository status: Historical research code.** The scripts are preserved for future reference and are not actively maintained. Compatibility with current software, datasets, and Google Earth Engine assets has not necessarily been verified.

## Overview

The repository includes scripts and workflows related to:

- Field-scale agricultural yield modeling.
- Satellite-derived vegetation indices, including NDVI and EVI.
- Crop yield visualization and comparisons across years.
- Soybean yield and cover cropping analysis.
- Geospatial data processing using Google Earth Engine.
- Analysis of agricultural and environmental variables.

The scripts may provide a useful starting point for understanding previous analyses and developing new research workflows.

## Repository Contents

The repository contains R scripts and Google Earth Engine code for different aspects of agricultural data analysis.

### Google Earth Engine scripts (JavaScript, run in the GEE Code Editor)

| File | Description |
|---|---|
| `NDVI_EVI_HISTARFM` | Vegetation index (NDVI, EVI) analysis using HISTARFM gap-filled reflectance data. |
| `Weather variables` | Extraction of weather variables over the study area. |
| `corn_soybean_masked` | Annual corn and soybean masks from the USDA NASS Cropland Data Layer (CDL) for the study watershed. |

### R scripts

| File | Description |
|---|---|
| `Yield_modeling_field_scale.R` | Field-scale yield modeling with machine learning methods (e.g., random forest, SVM, XGBoost). |
| `Plotting_yield_data.R` | Observed vs. predicted yield plots and accuracy metrics. |
| `Plot_yield_vs_cover_cropping_years.R` | Yield comparisons by number of cover cropping years, with histograms of cover cropping frequency. |
| `plot_corn_yield.R` | Maps of predicted corn yield rasters. |
| `plot_soybean_yield.R` | Maps of predicted soybean yield rasters. |
| `yearly_boxplot_yield.R` | Yearly corn yield boxplots comparing areas with and without cover crops. |
| `yearly_yield_soybean.R` | Yearly soybean yield comparison with and without cover crops (2009–2019). Documented and configurable; see the header of the script. |

Please inspect each script to understand its specific inputs, assumptions, dependencies, and expected outputs before using it.

### Notes for reuse

- Most R scripts set a working directory to a local path (e.g., `C:/Users/...`). Change this to the location of your own data before running.
- Some R scripts load `rgdal` and `maptools`, which have been retired from CRAN. The `terra` and `sf` packages are the current replacements.
- The GEE scripts may reference Earth Engine assets (such as a study-area boundary) stored in the author's account, which may not be accessible to others. Replace them with your own assets.
- Input data (yield maps, cover crop maps, shapefiles) are not included in this repository.

## Technologies

The project uses or may depend on the following technologies:

- **R** — statistical analysis, data processing, and visualization.
- **Google Earth Engine** — satellite imagery and geospatial analysis.
- **Satellite-derived vegetation indices** — including NDVI and EVI.
- **Agricultural yield and environmental datasets** — depending on the individual script.

Specific package versions and dataset requirements may differ between scripts.

## Author

Kushal KC
