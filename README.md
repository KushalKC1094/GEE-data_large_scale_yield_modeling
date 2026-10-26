# GEE Data: Large-Scale Yield Modeling

Research code for agricultural yield analysis using Google Earth Engine (GEE) and R.

This repository contains the code behind the following paper:

> KC, K., & Khanal, S. (2023). Agricultural productivity and water quality tradeoffs of winter cover crops at a landscape scale through the lens of remote sensing. *Journal of Environmental Management*, 330, 117212. https://doi.org/10.1016/j.jenvman.2022.117212

The scripts estimate corn and soybean yields at 30-m resolution across the Maumee River Watershed (Ohio, Indiana, and Michigan) from satellite vegetation indices and weather data, using **county-level yield statistics from USDA NASS** to train the models. It then compares the predicted yields on fields with and without winter cover crops. The repository is preserved as a reference resource for students and researchers who wish to understand, reuse, or extend the existing workflows.

> **Repository status: Historical research code.** The scripts are preserved for future reference and are not actively maintained. Compatibility with current software, datasets, and Google Earth Engine assets has not necessarily been verified.

## Start Here

1. **Read the paper.** It explains the study area, data, methods, and results in detail; the code does not repeat them. Use the DOI above.
2. **Follow the [Workflow](#workflow)** below to see which script carries out each step of the analysis.
3. **To run the analysis yourself**, use the updated scripts: the two Earth Engine scripts to [download the data](#running-the-earth-engine-scripts), then `Yield_modeling_updated.R` to [fit the models and map yield on your computer](#running-the-yield-model-locally).
4. **See the companion repository** [Winter-cover-crop-mapping](https://github.com/KushalKC1094/Winter-cover-crop-mapping) for code related to the winter cover crop maps used in the final step.

## Study Summary

| | |
|---|---|
| **Study area** | Maumee River Watershed (MRW), the largest watershed in the Lake Erie region; about 80% agricultural, mainly corn–soybean rotation. |
| **Period** | 2009–2019 growing seasons. |
| **Training data** | County-level corn and soybean yields from USDA NASS for 14 counties with more than 50% of their area in the watershed: Adams, Allen, and DeKalb (Indiana); Hillsdale (Michigan); Allen, Auglaize, Defiance, Fulton, Hancock, Henry, Paulding, Putnam, Van Wert, and Williams (Ohio). This gave 149 corn and 153 soybean county-year observations. |
| **Predictors** | Mean NDVI and EVI2 for July–August from 30-m monthly Landsat–MODIS fused imagery (HISTARFM; Moreno-Martínez et al., 2020), and August mean temperature and total precipitation from PRISM (4 km, rescaled to 30 m with bilinear interpolation). |
| **Models** | Multiple linear regression (MLR), random forest (RF), and support vector machine (SVM), trained on a 4:1 train–test split with hyperparameters tuned by 10-fold cross-validation in `caret`. |
| **Independent validation** | Yield monitor data from 19 fields in corn–soybean rotation, 2014–2019 (55 corn and 45 soybean field-years), averaged per field and compared with predicted yields. |
| **Yield maps** | Covariates at 30-m resolution were fed into the best-performing model to map yield for every corn and soybean pixel. |
| **Cover crop maps** | 30-m cover crop maps for 2008–2019 from earlier work (KC et al., 2021), aggregated into cover crop vs. no cover crop. |

## Workflow

The scripts run in four steps. Steps 1–3 estimate yield; step 4 links yield to cover crops.

```
1. Predictors (GEE)          2. Yield model (R)           3. Yield maps (R)           4. Cover crop effects (R)
   NDVI, EVI2 (Jul-Aug)  -->    train on county-level  -->    apply model to     -->     compare yield with vs.
   PRISM weather (Aug)          NASS yields; validate         every 30-m pixel           without cover crops
   corn/soybean masks           with yield monitor data                                  (needs cover crop maps)
```

### 1. Build predictors in Google Earth Engine

| Script | What it does |
|---|---|
| `NDVI_EVI_HISTARFM.js` | July–August mean NDVI and EVI2 from HISTARFM, masked to corn or soybean fields with the USDA NASS Cropland Data Layer (CDL). Exports one 30-m GeoTIFF per year and one CSV of county-year means. |
| `Weather variables.js` | August mean temperature and total precipitation from PRISM daily data. Exports two GeoTIFFs per year (~4 km) and one CSV of county-year means. |
| `corn_soybean_masked.js` | *Earlier, alternative approach, not used for the paper's models.* Maximum May–October NDVI and EVI2 from harmonized Landsat 5/7/8, masked to corn or soybean. Not updated: it uses Landsat Collection 1 and private boundary assets (see [Notes for Reuse](#notes-for-reuse)). |

See [Running the Earth Engine scripts](#running-the-earth-engine-scripts) for how to run them and what they export.

### 2. Train and validate the yield model

| Script | What it does |
|---|---|
| `Yield_modeling_updated.R` | **Recommended for new users.** Updated version of the original script that runs as is on your computer, using the data downloaded by the Earth Engine scripts. Builds the training table, compares MLR, RF, and SVM, maps yield (step 3), and validates the maps against field yield data. See [Running the yield model locally](#running-the-yield-model-locally). |
| `Yield_modeling_field_scale.R` | *Original script used for the paper, kept for reference.* Trains corn and soybean models predicting county yield (t/ha) from mean NDVI, mean EVI2, August temperature, and August precipitation. Compares MLR, RF, and SVM with a 4:1 train–test split and 10-fold cross-validation for tuning. Requires manual input preparation; see [Using the original modeling script](#using-the-original-modeling-script). |
| `Plotting_yield_data.R` | Plots observed vs. predicted yields from a model's output table and calculates R², RMSE, and MAE. |

### 3. Map predicted yield

| Script | What it does |
|---|---|
| `Yield_modeling_updated.R` | Applies the selected model to the 30-m vegetation index and weather rasters to produce yield maps for every year (`<year>_corn_yield.tif`, `<year>_soybean_yield.tif`). |
| `Yield_modeling_field_scale.R` (final section) | Original version: maps one year at a time. |
| `plot_corn_yield.R`, `plot_soybean_yield.R` | Map the predicted yield rasters for the watershed. |

### 4. Compare yield with and without cover crops

These scripts need the yearly cover crop maps. The paper used two approaches:

| Script | What it does |
|---|---|
| `yearly_boxplot_yield.R` | **Approach 1 (corn):** yearly yield on fields with vs. without a cover crop in the preceding winter, 2009–2019. |
| `yearly_yield_soybean.R` | **Approach 1 (soybean):** same comparison for soybean. |
| `Plot_yield_vs_cover_cropping_years.R` | **Approach 2:** yield by cover crop history (number of years a pixel was cover cropped) for five years with contrasting weather (2012, 2015, 2016, 2018, and 2019), plus histograms of cover cropping frequency. |

The water quality analysis in the paper (cover crop area vs. nutrient loads at the watershed outlet and tributaries) is not included in this repository.

Please inspect each script to understand its specific inputs, assumptions, dependencies, and expected outputs before using it.

## Running the Earth Engine Scripts

`NDVI_EVI_HISTARFM.js` and `Weather variables.js` have been updated to run as they are, using public datasets only.

**Before you start**

1. Register for [Google Earth Engine](https://code.earthengine.google.com/) with a Google Cloud project (free for noncommercial research).
2. Request access to HISTARFM: join the **"HISTARFM collection"** Google group with the same Google account. Without it, the collection does not load. HISTARFM covers the contiguous U.S. from January 2009 to October 2021 and is licensed CC BY-NC 4.0.

**Steps**

1. In the Code Editor, create a new script, paste in the file, and edit the **SETTINGS** block at the top (crop, years, Google Drive folder).
2. Click **Run** and check the **Console**: it should report **14 counties**, plus **2** HISTARFM images (vegetation script) or **31** daily PRISM images (weather script) for the first year. The map shows a preview.
3. Open the **Tasks** tab and click **Run** on each export. Earth Engine does not start exports automatically.
4. Run `NDVI_EVI_HISTARFM.js` once with `CROP = 'corn'` and once with `CROP = 'soybean'`. Run `Weather variables.js` once; weather is the same for both crops.

**Outputs** (saved to the `GEE_yield_modeling` folder in Google Drive)

| File | Contents |
|---|---|
| `<crop>_veg_index_<year>.tif` | 30-m raster; band 1 `NDVI_mean`, band 2 `EVI2_mean`; crop fields only. |
| `<crop>_veg_index_by_county.csv` | `GEOID, NAME, STATEFP, year, NDVI_mean, EVI2_mean` |
| `<year>_temp_aug.tif`, `<year>_ppt_aug.tif` | ~4-km rasters of August mean temperature (°C) and total precipitation (mm). |
| `weather_aug_by_county.csv` | `GEOID, NAME, STATEFP, year, mean_aug_temp, mean_aug_ppt` (precipitation is the August total, named to match the model formula). |

All rasters are exported in geographic coordinates (EPSG:4326), so the weather and vegetation index rasters can be aligned with `resample()` in R. Large exports may be split into several tiles (e.g. `corn_veg_index_2019-0000000000-0000000000.tif`); `Yield_modeling_updated.R` merges them automatically.

## Running the Yield Model Locally

`Yield_modeling_updated.R` runs on your own computer (Windows, macOS, or Linux) with R, using the files downloaded from Earth Engine. It needs no manual data preparation and no edits to file paths in the code.

**1. Install R and the packages** (once). Install [R](https://cran.r-project.org/) (and optionally [RStudio](https://posit.co/download/rstudio-desktop/)), then in R:

```r
install.packages(c("caret", "randomForest", "kernlab", "terra", "dplyr", "readr", "ggplot2"))
```

**2. Put the input files in one folder** (e.g. `data/`):

| File | Source |
|---|---|
| `<crop>_veg_index_<year>.tif`, `<crop>_veg_index_by_county.csv` | `NDVI_EVI_HISTARFM.js` (corn and soybean) |
| `<year>_temp_aug.tif`, `<year>_ppt_aug.tif`, `weather_aug_by_county.csv` | `Weather variables.js` |
| `nass_corn_yield.csv`, `nass_soybean_yield.csv` | [USDA NASS Quick Stats](https://quickstats.nass.usda.gov/): county-level `YIELD, MEASURED IN BU / ACRE` for the 14 study counties, 2009–2019, downloaded as CSV. The script converts bu/acre to t/ha. |
| `field_boundaries.gpkg` (or `.shp`) and `field_yield.csv` | *Optional*, for the independent field validation (see below). |

**3. Run the script**, either from RStudio (set `data_dir` at the top of the script, then click **Source**) or from a terminal:

```bash
Rscript Yield_modeling_updated.R path/to/data path/to/output
```

**Settings** at the top of the script include the crops and years to map, and the model used for the maps (`selected_model`; MLR by default, as in the original script, or `"RF"`, `"SVM"`, or `"auto"` for the lowest cross-validation error).

**Outputs** (in the output folder)

| File | Contents |
|---|---|
| `model_accuracy.csv` | Cross-validation and test-set R², RMSE, MAE, and MAPE for MLR, RF, and SVM. |
| `training_table_<crop>.csv` | County-year data used to fit the models. |
| `obs_vs_pred_test_<crop>.png` | Observed vs. predicted county yields (test set). |
| `models/<crop>_<model>.rds` | Fitted models. |
| `yield_maps/<year>_<crop>_yield.tif` | Predicted yield (t/ha) for each crop and year. |
| `field_validation.csv`, `field_validation_accuracy.csv`, `field_validation_<crop>.png` | Independent validation results, if field data are provided. |

**Spatial consistency.** The yield maps are written on the same grid as the vegetation index rasters from Earth Engine: EPSG:4326, about 30 m, crop pixels only. The weather rasters (about 4 km) are resampled onto that grid with bilinear interpolation, as in the paper. The script stops with a message if a raster is in a different projection (for example, one exported with an older version of the Earth Engine scripts).

**Independent field validation (optional).** Provide yield monitor data averaged per field and year:

- `field_boundaries.gpkg` (or `.shp`): field polygons with a `field_id` column, in any projection.
- `field_yield.csv`: columns `field_id`, `year`, `crop` (`corn` or `soybean`), and `yield_t_ha` (observed yield in t/ha).

The script calculates the area-weighted mean predicted yield within each field and compares it with the observed yield. Fields with fewer than 10 predicted crop pixels are excluded. Without these files, the validation step is skipped.

**Run time.** Mapping all 14 counties takes a few minutes per crop and year with MLR; RF and SVM take considerably longer.

## Using the Original Modeling Script

`Yield_modeling_field_scale.R` is the script used for the paper. It does not read the Earth Engine downloads directly: it reads a training table per crop (`regression_in_R_corn.csv`, `regression_in_R_soybean.csv`) and, for mapping, rasters with specific names. Set the working directory at the top of the script to your data folder.

**1. Training table.** Download county-level yields (`YIELD, MEASURED IN BU / ACRE`) for the 14 study counties and 2009–2019 from [USDA NASS Quick Stats](https://quickstats.nass.usda.gov/) as a CSV (e.g. `nass_corn_yield.csv`), then join them with the two county CSVs:

```r
library(dplyr)

crop <- "corn"                                    # "corn" or "soybean"
bu_to_t <- c(corn = 0.06277, soybean = 0.06725)   # bu/acre -> t/ha

nass <- read.csv(paste0("nass_", crop, "_yield.csv"), colClasses = "character", check.names = FALSE) %>%
  filter(grepl("YIELD, MEASURED IN BU / ACRE", `Data Item`), !grepl("\\(", Value)) %>%   # drop withheld "(D)" values
  transmute(GEOID = sprintf("%02d%03d", as.integer(`State ANSI`), as.integer(`County ANSI`)),
            year  = as.integer(Year),
            Value_ton_ha = as.numeric(gsub(",", "", Value)) * bu_to_t[[crop]])

veg <- read.csv(paste0(crop, "_veg_index_by_county.csv")) %>%
  transmute(GEOID = sprintf("%05d", GEOID), year, mean.NDVI = NDVI_mean, mean.EVI2 = EVI2_mean)

weather <- read.csv("weather_aug_by_county.csv") %>%
  transmute(GEOID = sprintf("%05d", GEOID), year, mean_aug_temp, mean_aug_ppt)

training <- nass %>%
  inner_join(veg, by = c("GEOID", "year")) %>%
  inner_join(weather, by = c("GEOID", "year"))
write.csv(training, paste0("regression_in_R_", crop, ".csv"), row.names = FALSE)
```

This gives the columns used in the model formula: `Value_ton_ha`, `mean.NDVI`, `mean.EVI2`, `mean_aug_temp`, and `mean_aug_ppt`.

**2. Rasters for the yield maps.** The weather rasters already have the expected names (`2019_temp_aug.tif`, `2019_ppt_aug.tif`). Rename each vegetation index raster to the name the script reads, e.g. `corn_veg_index_2019.tif` → `corn_meanNDVIEVI_2019.tif` (band 1 is NDVI, band 2 is EVI2). The script maps one year at a time; change the year in the file names inside the script for each year.

## Data

Input data are **not included** in this repository.

| Data | Source | Notes |
|---|---|---|
| County-level corn and soybean yields | [USDA NASS Quick Stats](https://quickstats.nass.usda.gov/) | Public. Read directly by `Yield_modeling_updated.R`; see [Running the yield model locally](#running-the-yield-model-locally). |
| HISTARFM, CDL, PRISM | Earth Engine data catalog | Loaded directly by the GEE scripts. HISTARFM requires joining its Google group. |
| Study-area boundaries | Public Earth Engine datasets (TIGER, WBD) | Built into the updated GEE scripts; see [Boundary files](#boundary-files) for the others. |
| Winter cover crop maps (2008–2019) | KC et al. (2021); see the paper | Needed for step 4. |
| Field yield monitor data | Partner farms | Used only for independent validation; not public. Use your own field data in the format described under [Independent field validation](#running-the-yield-model-locally). |

### Boundary files

The original scripts loaded boundaries from the author's private Earth Engine assets (`users/kessi9400/counties_Ohio_WGS84` and `users/kessi9400/Maumee_WGS84`), which are not accessible to other users. **`NDVI_EVI_HISTARFM.js` and `Weather variables.js` already load the study counties from the public TIGER dataset.** For any other script (e.g. `corn_soybean_masked.js`), replace the private asset paths with these public datasets:

```javascript
// Study counties: the 14 counties with more than 50% of their area in the watershed,
// selected by county FIPS code from the U.S. Census TIGER dataset
var counties = ee.FeatureCollection('TIGER/2018/Counties')
  .filter(ee.Filter.inList('GEOID', [
    '18001', '18003', '18033',            // Indiana: Adams, Allen, DeKalb
    '26059',                              // Michigan: Hillsdale
    '39003', '39011', '39039', '39051',   // Ohio: Allen, Auglaize, Defiance, Fulton,
    '39063', '39069', '39125', '39137',   //       Hancock, Henry, Paulding, Putnam,
    '39161', '39171'                      //       Van Wert, Williams
  ]));

// Maumee River Watershed: its seven HUC-8 subbasins from the USGS Watershed Boundary Dataset
var maumee = ee.FeatureCollection('USGS/WBD/2017/HUC08')
  .filter(ee.Filter.inList('huc8', [
    '04100003', '04100004', '04100005', '04100006',
    '04100007', '04100008', '04100009'
  ]));
```

Use `counties` wherever a script reads `ohio_counties`, and `maumee` wherever it reads `roi` or `maumee`. Selecting counties by FIPS code (`GEOID`) avoids confusing the two Allen counties in Indiana and Ohio. Check the selection on the map (`Map.addLayer(counties)`) before exporting.

## Notes for Reuse

- **Local paths:** the original R scripts set a working directory to a local path (e.g., `C:/Users/...`). Change this to the location of your own data before running. `Yield_modeling_updated.R` takes the data folder as a setting or command-line argument instead.
- **Retired R packages:** some R scripts load `rgdal` and `maptools`, which have been retired from CRAN. The `terra` and `sf` packages are the current replacements.
- **Private assets:** `corn_soybean_masked.js` still references boundary assets stored in the author's account (`users/kessi9400/...`). Replace them with the public TIGER and WBD datasets shown under [Boundary files](#boundary-files).
- **Retired datasets:** the updated GEE scripts use current datasets (HISTARFM and `OREGONSTATE/PRISM/ANd`, which replaces the deprecated `OREGONSTATE/PRISM/AN81d`). `corn_soybean_masked.js` still uses Landsat Collection 1 (`LANDSAT/.../C01/T1_SR`), which has been superseded by Collection 2 (e.g. `LANDSAT/LC08/C02/T1_L2`, with different band names and scaling).
- **HISTARFM coverage:** the CONUS collection ends in October 2021, so it cannot be used for later years.
- **Scaling caveat:** the models are trained on county averages and then applied to 30-m pixels. Keep this in mind when interpreting pixel- or field-level predictions; the paper discusses validation against field yield monitor data.

## Technologies

- **Google Earth Engine** — satellite imagery and geospatial analysis.
- **HISTARFM (Landsat–MODIS fusion)** — vegetation indices (NDVI, EVI2).
- **USDA NASS** — county-level yield statistics and the Cropland Data Layer.
- **PRISM** — weather data.
- **R** (`caret`, `randomForest`, `kernlab`, `terra`, `ggplot2`; the original scripts also use `e1071` and `raster`) — modeling, raster processing, and visualization.

Specific package versions and dataset requirements may differ between scripts.

## Citation

If you use or adapt this code, please cite the paper:

```bibtex
@article{KC2023covercrops,
  author  = {KC, Kushal and Khanal, Sami},
  title   = {Agricultural productivity and water quality tradeoffs of winter cover crops at a landscape scale through the lens of remote sensing},
  journal = {Journal of Environmental Management},
  volume  = {330},
  pages   = {117212},
  year    = {2023},
  doi     = {10.1016/j.jenvman.2022.117212}
}
```

## Author

Kushal KC
