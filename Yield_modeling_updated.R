# =============================================================================
# Yield_modeling_updated.R
#
# Updated version of Yield_modeling_field_scale.R. Uses the data exported by
# NDVI_EVI_HISTARFM.js and "Weather variables.js" to:
#   1. Build the training table: USDA NASS county yields (t/ha) joined with
#      county-year means of NDVI, EVI2, August temperature and precipitation.
#   2. Fit and compare MLR, random forest and SVM (same settings as the original
#      script) on a 4:1 train/test split with shared 10-fold cross-validation.
#   3. Predict spatially explicit 30-m yield maps for each year with the
#      selected model.
#   4. Validate the yield maps independently against field-level yield monitor
#      data (mean predicted vs. mean observed yield per field-year).
# Used in: KC & Khanal (2023), J. Environ. Manage. 330, 117212.
#
# ---- Spatial consistency ----------------------------------------------------
# Both Earth Engine scripts export rasters in geographic coordinates (EPSG:4326):
#   <crop>_veg_index_<year>.tif   ~30 m (0.00027 deg), clipped to the counties,
#                                 masked to the crop (CDL); bands NDVI_mean, EVI2_mean
#   <year>_temp_aug.tif, <year>_ppt_aug.tif   ~4 km (0.042 deg), county bounding box
# For every year, the weather rasters are resampled (bilinear, as in the paper)
# onto that year's vegetation index grid, and the yield map is written on
# exactly that grid: EPSG:4326, ~30 m, crop pixels only. The script stops if
# the two sources are in different CRSs or a vegetation index raster is not in
# EPSG:4326, rather than silently mixing projections. Field boundaries for the
# validation can be in any CRS; they are reprojected to the yield-map CRS.
#
# ---- Inputs (in `data_dir`) -------------------------------------------------
#   nass_corn_yield.csv, nass_soybean_yield.csv
#       County yields from USDA NASS Quick Stats (https://quickstats.nass.usda.gov/),
#       Data Item "... YIELD, MEASURED IN BU / ACRE", study counties, 2009-2019.
#   corn_veg_index_by_county.csv, soybean_veg_index_by_county.csv,
#   weather_aug_by_county.csv                      (from the GEE scripts)
#   <crop>_veg_index_<year>.tif, <year>_temp_aug.tif, <year>_ppt_aug.tif
#                                                  (from the GEE scripts; tiled
#                                                   exports are mosaicked)
#   Optional, for the independent validation, one layer per crop:
#     Field_yield_corn.gpkg, Field_yield_soybean.gpkg   (preferred), or
#     Field_yield_<crop>_shapefile.zip, or Field_yield_<crop>.shp
#   Field polygons (any CRS) with a `Field` name column and yield monitor data
#   averaged per field and year, in t/ha, in columns tha_<year> (e.g. tha_2019).
#   NULL/NA means no data for that crop and year. (Shapefiles cannot store
#   true NULLs and ArcGIS shows them as 0, so 0 is also treated as no data.)
#   A ready-made training table regression_in_R_<crop>.csv (columns
#   Value_ton_ha, mean.NDVI, mean.EVI2, mean_aug_temp, mean_aug_ppt) is used
#   instead of the three CSVs if present.
#
# ---- Outputs (in `output_dir`) ----------------------------------------------
#   training_table_<crop>.csv            data used to fit the models
#   model_accuracy.csv                   CV and test-set accuracy of all models
#   obs_vs_pred_test_<crop>.png          county test set, selected model
#   models/<crop>_<MLR|RF|SVM>.rds       fitted models
#   yield_maps/<year>_<crop>_yield.tif   predicted yield (t/ha), EPSG:4326, 30 m
#   field_validation.csv                 per field-year observed vs. predicted
#                                        (with the number of predicted pixels)
#   field_validation_accuracy.csv        R2, RMSE, MAE per crop
#   field_validation_<crop>.png          observed vs. predicted per field-year
#
# ---- How to run -------------------------------------------------------------
#   R/RStudio: set `data_dir` below, then source("Yield_modeling_updated.R")
#   Terminal:  Rscript Yield_modeling_updated.R path/to/data [path/to/output]
#
# Packages: caret, randomForest, kernlab, terra, dplyr, tidyr, readr, ggplot2
#   install.packages(c("caret", "randomForest", "kernlab", "terra", "tidyr",
#                      "dplyr", "readr", "ggplot2"))
# =============================================================================

suppressPackageStartupMessages({
  library(caret)
  library(terra)
  library(dplyr)
  library(readr)
  library(ggplot2)
})

# ---- CONFIG -----------------------------------------------------------------

args <- commandArgs(trailingOnly = TRUE)
data_dir   <- if (length(args) >= 1) args[1] else "data"
output_dir <- if (length(args) >= 2) args[2] else "output"

crops       <- c("corn", "soybean")
map_years   <- 2009:2019      # years to map; years without rasters are skipped
random_seed <- 123            # as in the original script
test_share  <- 0.2            # 4:1 train/test split

# Model used for the yield maps. The original script mapped yield with the
# linear regression (MLR) models; set "RF" or "SVM" per crop to use another,
# or "auto" to pick the lowest cross-validation RMSE.
selected_model <- c(corn = "MLR", soybean = "MLR")

# Random forest settings tuned in the original script.
# (The original soybean mtry = 6 exceeds the 4 predictors; randomForest resets
#  it to 4, so 4 is used here and the result is the same.)
rf_settings <- list(corn    = list(mtry = 2, ntree = 800, maxnodes = 14),
                    soybean = list(mtry = 4, ntree = 300, maxnodes = 14))

# Independent field validation (skipped for a crop if its layer is missing).
# One GeoPackage or shapefile per crop; yields in t/ha in columns tha_<year>.
field_layers <- c(corn = "Field_yield_corn", soybean = "Field_yield_soybean")
field_name_column <- "Field"
min_field_pixels  <- 10   # ignore field-years with fewer predicted crop pixels

expected_crs <- "EPSG:4326"   # CRS of the GEE raster exports

predictors    <- c("mean.NDVI", "mean.EVI2", "mean_aug_temp", "mean_aug_ppt")
model_formula <- reformulate(predictors, response = "Value_ton_ha")

# Bushels per acre -> metric tons per hectare
# (corn 56 lb/bu, soybean 60 lb/bu; 1 lb = 0.45359237 kg; 1 acre = 0.40468564 ha)
bu_ac_to_t_ha <- c(corn    = 56 * 0.45359237 / 0.40468564 / 1000,
                   soybean = 60 * 0.45359237 / 0.40468564 / 1000)

# ---- HELPERS ----------------------------------------------------------------

fips <- function(x) sprintf("%05d", as.integer(x))

accuracy <- function(obs, pred) {
  c(n       = length(obs),
    R2      = cor(obs, pred)^2,                                   # squared correlation
    R2_1to1 = 1 - sum((obs - pred)^2) / sum((obs - mean(obs))^2), # fit to the 1:1 line
    RMSE    = sqrt(mean((obs - pred)^2)),
    MAE     = mean(abs(obs - pred)),
    MAPE    = 100 * mean(abs((obs - pred) / obs)))
}

obs_pred_plot <- function(obs, pred, title, file) {
  lims <- range(c(obs, pred))                       # same range on both axes
  p <- ggplot(data.frame(obs, pred), aes(obs, pred)) +
    geom_abline(linetype = 2, color = "red3") +
    geom_point(color = "chartreuse4", size = 2.5) +
    coord_equal(xlim = lims, ylim = lims) +
    labs(title = title, x = "Observed yield (t/ha)", y = "Predicted yield (t/ha)") +
    theme_bw() +
    theme(panel.grid = element_blank(), axis.text = element_text(size = 14),
          axis.title = element_text(size = 14))
  ggsave(file, p, width = 6, height = 6, dpi = 300)
}

# Earth Engine splits large exports into tiles (name-0000000000-0000000000.tif);
# mosaic them into one raster if so.
read_export <- function(prefix) {
  files <- list.files(data_dir, pattern = paste0("^", prefix, "(-\\d+-\\d+)?\\.tif$"),
                      full.names = TRUE)
  if (length(files) == 0) return(NULL)
  if (length(files) == 1) return(rast(files))
  mosaic <- vrt(files)
  names(mosaic) <- names(rast(files[1]))            # vrt() drops band names
  mosaic
}

# ---- STEP 1: TRAINING TABLE -------------------------------------------------

read_nass_yield <- function(crop) {
  path <- file.path(data_dir, paste0("nass_", crop, "_yield.csv"))
  if (!file.exists(path)) stop("Missing NASS yield file: ", path)
  read_csv(path, show_col_types = FALSE, col_types = cols(.default = "c")) %>%
    filter(grepl("YIELD, MEASURED IN BU / ACRE", `Data Item`),
           !grepl("\\(", Value)) %>%                # drop withheld values, e.g. "(D)"
    transmute(GEOID = sprintf("%02d%03d", as.integer(`State ANSI`), as.integer(`County ANSI`)),
              year  = as.integer(Year),
              Value_ton_ha = as.numeric(gsub(",", "", Value)) * bu_ac_to_t_ha[[crop]])
}

build_training_table <- function(crop) {
  ready_made <- file.path(data_dir, paste0("regression_in_R_", crop, ".csv"))
  if (file.exists(ready_made)) {
    message("  using ready-made training table: ", basename(ready_made))
    return(read_csv(ready_made, show_col_types = FALSE))
  }
  veg <- read_csv(file.path(data_dir, paste0(crop, "_veg_index_by_county.csv")),
                  show_col_types = FALSE) %>%
    transmute(GEOID = fips(GEOID), year = as.integer(year),
              mean.NDVI = NDVI_mean, mean.EVI2 = EVI2_mean)
  weather <- read_csv(file.path(data_dir, "weather_aug_by_county.csv"),
                      show_col_types = FALSE) %>%
    transmute(GEOID = fips(GEOID), year = as.integer(year), mean_aug_temp, mean_aug_ppt)

  read_nass_yield(crop) %>%
    inner_join(veg,     by = c("GEOID", "year")) %>%
    inner_join(weather, by = c("GEOID", "year"))
}

# ---- STEP 2: FIT AND COMPARE MODELS -----------------------------------------

fit_models <- function(train_data, crop) {
  # Same 10 folds for every model, so their CV results are directly comparable
  set.seed(random_seed)
  folds <- createFolds(train_data$Value_ton_ha, k = 10, returnTrain = TRUE)
  ctrl  <- trainControl(method = "cv", number = 10, index = folds,
                        savePredictions = "final")
  rf <- rf_settings[[crop]]

  list(
    MLR = train(model_formula, data = train_data, method = "lm", trControl = ctrl),
    RF  = train(model_formula, data = train_data, method = "rf", trControl = ctrl,
                tuneGrid = data.frame(mtry = rf$mtry),
                ntree = rf$ntree, maxnodes = rf$maxnodes),
    SVM = train(model_formula, data = train_data, method = "svmRadial", trControl = ctrl,
                preProcess = c("center", "scale"))
  )
}

# ---- STEP 3: SPATIALLY EXPLICIT YIELD MAPS ----------------------------------

map_yield <- function(model, crop, year) {
  veg  <- read_export(paste0(crop, "_veg_index_", year))
  temp <- read_export(paste0(year, "_temp_aug"))
  ppt  <- read_export(paste0(year, "_ppt_aug"))
  if (is.null(veg) || is.null(temp) || is.null(ppt)) {
    message("    ", year, ": predictor rasters not found, skipped")
    return(NULL)
  }

  # CRS checks: all inputs must share the vegetation index grid's CRS
  if (!same.crs(veg, expected_crs)) {
    stop(crop, "_veg_index_", year, " is not in ", expected_crs,
         "; re-export it with the current NDVI_EVI_HISTARFM.js.")
  }
  if (!same.crs(temp, veg) || !same.crs(ppt, veg)) {
    stop("Weather rasters for ", year, " are not in the same CRS as the ",
         "vegetation index raster; re-export them with the current Weather variables.js.")
  }

  # Weather (~4 km) onto the 30-m vegetation grid: bilinear, as in the paper
  temp_30m <- resample(temp, veg, method = "bilinear")
  ppt_30m  <- resample(ppt,  veg, method = "bilinear")

  stack <- c(veg[["NDVI_mean"]], veg[["EVI2_mean"]], temp_30m, ppt_30m)
  names(stack) <- predictors
  stack <- mask(stack, veg[["NDVI_mean"]])          # crop pixels only (CDL mask)

  yield <- predict(stack, model, na.rm = TRUE)
  yield <- ifel(yield < 0, 0, yield)                # no negative yields
  names(yield) <- "yield_t_ha"

  out_file <- file.path(output_dir, "yield_maps", paste0(year, "_", crop, "_yield.tif"))
  writeRaster(yield, out_file, overwrite = TRUE, gdal = "COMPRESS=DEFLATE")
  message("    ", year, ": ", basename(out_file))
  out_file
}

# ---- STEP 4: INDEPENDENT FIELD VALIDATION -----------------------------------

# Read a crop's field layer from data_dir, in this order:
#   <name>.gpkg (preferred: stores no-data years as true NULL),
#   <name>_shapefile.zip or <name>.zip (containing <name>.gpkg or <name>.shp;
#   read in place, no need to unzip), or <name>.shp.
read_field_layer <- function(name) {
  gpkg <- file.path(data_dir, paste0(name, ".gpkg"))
  if (file.exists(gpkg)) return(vect(gpkg))
  for (zip in file.path(data_dir, paste0(name, c("_shapefile.zip", ".zip")))) {
    if (file.exists(zip)) {
      inside <- grep(paste0("(^|/)", name, "\\.(gpkg|shp)$"), unzip(zip, list = TRUE)$Name, value = TRUE)
      if (length(inside) == 0) stop(basename(zip), " does not contain ", name, ".gpkg or ", name, ".shp")
      return(vect(paste0("/vsizip/", normalizePath(zip), "/", sort(inside)[1])))   # .gpkg before .shp
    }
  }
  shp <- file.path(data_dir, paste0(name, ".shp"))
  if (file.exists(shp)) return(vect(shp))
  NULL
}

# Field polygons and observed yields (long format) for one crop
read_field_data <- function(crop) {
  fields <- read_field_layer(field_layers[[crop]])
  if (is.null(fields)) return(NULL)
  if (!field_name_column %in% names(fields)) {
    stop(field_layers[[crop]], " needs a '", field_name_column, "' column with field names.")
  }
  fields$field_id <- as.character(fields[[field_name_column]][[1]])
  if (anyDuplicated(fields$field_id)) stop("Duplicate field names in ", field_layers[[crop]])

  yield_cols <- grep("^tha_\\d{4}$", names(fields), value = TRUE)
  if (length(yield_cols) == 0) stop(field_layers[[crop]], " has no tha_<year> yield columns.")
  observed <- as.data.frame(fields)[, c("field_id", yield_cols)] %>%
    tidyr::pivot_longer(-field_id, names_to = "year", values_to = "yield_t_ha") %>%
    mutate(year = as.integer(sub("tha_", "", year)), crop = crop) %>%
    filter(!is.na(yield_t_ha), yield_t_ha > 0)     # NULL = no data; 0 too (ArcGIS shows shapefile NULLs as 0)

  list(fields = fields, observed = observed)
}

validate_with_fields <- function(map_files) {
  message("\n=== FIELD VALIDATION ===")
  field_data <- list()
  for (crop in unique(map_files$crop)) {
    d <- read_field_data(crop)
    if (is.null(d)) {
      message("  ", crop, ": no ", field_layers[[crop]], " layer (.gpkg, .zip or .shp) in ", data_dir, ", skipped")
    } else {
      message("  ", crop, ": ", nrow(d$fields), " fields, ", nrow(d$observed),
              " field-years with observed yield")
      field_data[[crop]] <- d
    }
  }
  if (length(field_data) == 0) return(invisible(NULL))

  results <- list()
  for (i in seq_len(nrow(map_files))) {
    crop <- map_files$crop[i]; year <- map_files$year[i]
    if (is.null(field_data[[crop]])) next
    obs_cy <- filter(field_data[[crop]]$observed, year == !!year)
    if (nrow(obs_cy) == 0) next

    yield_map <- rast(map_files$file[i])
    # Field polygons -> yield-map CRS, so pixels and fields line up
    fields <- field_data[[crop]]$fields
    fields_cy <- project(fields[fields$field_id %in% obs_cy$field_id], yield_map)

    # Area-weighted mean of the predicted pixels inside each field
    px <- extract(yield_map, fields_cy, exact = TRUE)
    names(px) <- c("ID", "yield", "fraction")
    pred <- px %>%
      filter(!is.na(yield)) %>%
      group_by(ID) %>%
      summarise(predicted_t_ha = weighted.mean(yield, fraction),
                n_pixels = n(), .groups = "drop") %>%
      mutate(field_id = as.character(fields_cy$field_id[ID]))

    results[[length(results) + 1]] <- obs_cy %>%
      inner_join(select(pred, field_id, predicted_t_ha, n_pixels), by = "field_id")
  }

  val <- bind_rows(results)
  if (nrow(val) == 0) {
    message("  no field-years overlap the yield maps")
    return(invisible(NULL))
  }
  # Field-years with observed yield but no yield map for that year/crop, or no
  # predicted crop pixels in the field (e.g. the CDL shows another crop there)
  all_obs <- bind_rows(lapply(field_data, `[[`, "observed"))
  missing <- anti_join(all_obs, val, by = c("field_id", "year", "crop"))
  if (nrow(missing) > 0) {
    message("  ", nrow(missing), " field-year(s) not validated (no yield map or no predicted crop pixels): ",
            paste0(missing$field_id, " ", missing$year, collapse = ", "))
  }
  dropped <- filter(val, n_pixels < min_field_pixels)
  if (nrow(dropped) > 0) {
    message("  ", nrow(dropped), " field-year(s) with < ", min_field_pixels,
            " predicted crop pixels excluded: ",
            paste0(dropped$field_id, " ", dropped$year, collapse = ", "))
  }
  val <- filter(val, n_pixels >= min_field_pixels) %>%
    select(field_id, crop, year, yield_t_ha, predicted_t_ha, n_pixels) %>%
    arrange(crop, field_id, year)
  write_csv(val, file.path(output_dir, "field_validation.csv"))

  acc <- val %>%
    group_by(crop) %>%
    group_modify(~ as.data.frame(t(round(accuracy(.x$yield_t_ha, .x$predicted_t_ha), 3)))) %>%
    ungroup()
  write_csv(acc, file.path(output_dir, "field_validation_accuracy.csv"))
  print(as.data.frame(acc))

  for (crop in unique(val$crop)) {
    v <- filter(val, crop == !!crop)
    obs_pred_plot(v$yield_t_ha, v$predicted_t_ha,
                  paste0(tools::toTitleCase(crop), ": field validation (", nrow(v), " field-years)"),
                  file.path(output_dir, paste0("field_validation_", crop, ".png")))
  }
}

# ---- MAIN -------------------------------------------------------------------

dir.create(file.path(output_dir, "models"),     recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(output_dir, "yield_maps"), recursive = TRUE, showWarnings = FALSE)

all_accuracy <- list()
map_files    <- list()

for (crop in crops) {
  message("\n=== ", toupper(crop), " ===")

  data <- build_training_table(crop) %>%
    select(any_of(c("GEOID", "year")), Value_ton_ha, all_of(predictors)) %>%
    na.omit()
  write_csv(data, file.path(output_dir, paste0("training_table_", crop, ".csv")))
  message("  ", nrow(data), " county-year observations")

  # 4:1 train/test split
  set.seed(random_seed)
  train_idx  <- createDataPartition(data$Value_ton_ha, p = 1 - test_share, list = FALSE)
  train_data <- data[train_idx, ]
  test_data  <- data[-train_idx, ]

  models <- fit_models(train_data, crop)

  # Accuracy: 10-fold CV on the training set, and the held-out test set
  acc <- bind_rows(lapply(names(models), function(m) {
    cv   <- models[[m]]$pred
    test <- predict(models[[m]], test_data)
    bind_rows(
      c(crop = crop, model = m, set = "cv",   round(accuracy(cv$obs, cv$pred), 3)),
      c(crop = crop, model = m, set = "test", round(accuracy(test_data$Value_ton_ha, test), 3)))
  }))
  all_accuracy[[crop]] <- acc
  print(as.data.frame(acc))

  for (m in names(models)) {
    saveRDS(models[[m]], file.path(output_dir, "models", paste0(crop, "_", m, ".rds")))
  }

  best <- selected_model[[crop]]
  if (best == "auto") best <- names(which.min(sapply(models, function(x) min(x$results$RMSE))))
  message("  model used for yield maps: ", best)

  obs_pred_plot(test_data$Value_ton_ha, predict(models[[best]], test_data),
                paste0(tools::toTitleCase(crop), " (", best, ", county test set)"),
                file.path(output_dir, paste0("obs_vs_pred_test_", crop, ".png")))

  message("  yield maps:")
  for (year in map_years) {
    f <- map_yield(models[[best]], crop, year)
    if (!is.null(f)) map_files[[length(map_files) + 1]] <- data.frame(crop = crop, year = year, file = f)
  }
}

write_csv(bind_rows(all_accuracy), file.path(output_dir, "model_accuracy.csv"))

if (length(map_files) > 0) validate_with_fields(bind_rows(map_files))

message("\nDone. Results written to: ", normalizePath(output_dir))
