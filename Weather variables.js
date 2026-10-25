// =============================================================================
// Weather variables.js
//
// August mean temperature and total precipitation from PRISM daily data, the
// two weather predictors used in the yield models.
// Used in: KC & Khanal (2023), J. Environ. Manage. 330, 117212.
//
// Outputs (saved to Google Drive):
//   1. Two GeoTIFFs per year, at PRISM's native ~4 km resolution:
//        <year>_temp_aug  (mean daily mean temperature, deg C)
//        <year>_ppt_aug   (total precipitation, mm)
//      -> inputs for the 30-m yield maps. The R script resamples them to 30 m
//         (bilinear) to match the vegetation index rasters.
//   2. One CSV: weather_aug_by_county  (county-year means)
//      -> predictors for training the yield model with NASS county yields
//
// How to run:
//   1. Edit the SETTINGS block below if needed, then click Run.
//   2. Check the Console: 14 counties, and 31 daily images for August.
//   3. Open the Tasks tab and click Run on each export. Earth Engine does not
//      start exports automatically.
// =============================================================================

// ---- SETTINGS ---------------------------------------------------------------

var YEARS = [2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019];
var MONTH = 8;                     // August
var DRIVE_FOLDER = 'GEE_yield_modeling';

// Study counties (public U.S. Census TIGER data, selected by FIPS code):
// the 14 counties with >50% of their area in the Maumee River Watershed.
var counties = ee.FeatureCollection('TIGER/2018/Counties')
  .filter(ee.Filter.inList('GEOID', [
    '18001', '18003', '18033',            // Indiana: Adams, Allen, DeKalb
    '26059',                              // Michigan: Hillsdale
    '39003', '39011', '39039', '39051',   // Ohio: Allen, Auglaize, Defiance, Fulton,
    '39063', '39069', '39125', '39137',   //       Hancock, Henry, Paulding, Putnam,
    '39161', '39171'                      //       Van Wert, Williams
  ]));

// ---- DATA -------------------------------------------------------------------

// PRISM daily climate data (replaces the deprecated OREGONSTATE/PRISM/AN81d)
var prism = ee.ImageCollection('OREGONSTATE/PRISM/ANd');
var PRISM_SCALE = 4638.3;          // native resolution, metres

// Daily images for the chosen month of one year
function monthlyDays(year) {
  var start = ee.Date.fromYMD(year, MONTH, 1);
  return prism.filterDate(start, start.advance(1, 'month'));
}

// Mean temperature and total precipitation for the month
function monthlyWeather(year) {
  var days = monthlyDays(year);
  var temp = days.select('tmean').mean().rename('mean_aug_temp');
  // Total (sum) of daily precipitation. The band is named 'mean_aug_ppt' only
  // to match the predictor name used in Yield_modeling_field_scale.R.
  var ppt  = days.select('ppt').sum().rename('mean_aug_ppt');
  return temp.addBands(ppt).set('year', year);
}

// ---- CHECK ------------------------------------------------------------------

print('Counties selected (expect 14):', counties.size());
print('PRISM daily images for first year (expect 31 for August):',
      monthlyDays(YEARS[0]).size());

var preview = monthlyWeather(YEARS[YEARS.length - 1]).clip(counties);
Map.centerObject(counties, 8);
Map.addLayer(preview.select('mean_aug_temp'),
  {min: 18, max: 26, palette: ['2c7bb6', 'ffffbf', 'd7191c']},
  'August mean temperature ' + YEARS[YEARS.length - 1]);
Map.addLayer(preview.select('mean_aug_ppt'),
  {min: 0, max: 200, palette: ['ffffcc', '41b6c4', '253494']},
  'August precipitation ' + YEARS[YEARS.length - 1], false);
Map.addLayer(ee.Image().byte().paint(counties, 1, 2), {palette: '000000'}, 'Counties');

// ---- EXPORTS ----------------------------------------------------------------
// These create tasks in the Tasks tab. Click Run on each one to start it.

// 1. Two GeoTIFFs per year (file names match those read by
//    Yield_modeling_field_scale.R, e.g. 2019_temp_aug.tif, 2019_ppt_aug.tif)
YEARS.forEach(function(year) {
  var weather = monthlyWeather(year);

  Export.image.toDrive({
    image: weather.select('mean_aug_temp').toFloat(),
    description: year + '_temp_aug',
    folder: DRIVE_FOLDER,
    region: counties.geometry().bounds(),
    scale: PRISM_SCALE,
    fileFormat: 'GeoTIFF'
  });

  Export.image.toDrive({
    image: weather.select('mean_aug_ppt').toFloat(),
    description: year + '_ppt_aug',
    folder: DRIVE_FOLDER,
    region: counties.geometry().bounds(),
    scale: PRISM_SCALE,
    fileFormat: 'GeoTIFF'
  });
});

// 2. County-year means, one row per county per year.
//    Column names match the predictors in Yield_modeling_field_scale.R.
var table = ee.FeatureCollection(YEARS.map(function(year) {
  return monthlyWeather(year).reduceRegions({
    collection: counties.select(['GEOID', 'NAME', 'STATEFP']),
    reducer: ee.Reducer.mean(),
    scale: PRISM_SCALE
  }).map(function(f) { return f.set('year', year).setGeometry(null); });
})).flatten();

Export.table.toDrive({
  collection: table,
  description: 'weather_aug_by_county',
  folder: DRIVE_FOLDER,
  fileFormat: 'CSV',
  selectors: ['GEOID', 'NAME', 'STATEFP', 'year', 'mean_aug_temp', 'mean_aug_ppt']
});
