// =============================================================================
// NDVI_EVI_HISTARFM.js
//
// July-August mean vegetation indices (NDVI, EVI2) on corn or soybean fields,
// from HISTARFM gap-filled monthly Landsat reflectance (30 m).
// Used in: KC & Khanal (2023), J. Environ. Manage. 330, 117212.
//
// Outputs (Tasks tab -> Run):
//   1. One GeoTIFF per year: <crop>_veg_index_<year>  (30 m, bands NDVI_mean,
//      EVI2_mean)  -> inputs for the 30-m yield maps
//   2. One CSV: <crop>_veg_index_by_county  (county-year means)
//      -> predictors for training the yield model with NASS county yields
//
// Before running:
//   - Join the "HISTARFM collection" Google group, or the collection won't load.
//     HISTARFM CONUS covers Jan 2009 - Oct 2021.
//   - Edit the SETTINGS block below.
//   - After clicking Run, start each export from the Tasks tab.
// =============================================================================

// ---- SETTINGS ---------------------------------------------------------------

var CROP  = 'corn';                // 'corn' or 'soybean'
var YEARS = [2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019];
var MONTHS = [7, 8];               // July-August
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

var CDL_CODES = {corn: 1, soybean: 5};
var cdl = ee.ImageCollection('USDA/NASS/CDL');
var histarfm = ee.ImageCollection('projects/KalmanGFwork/GFLandsat_V1');

// Mask of the chosen crop for one year, from the Cropland Data Layer
function cropMask(year) {
  var cropland = ee.Image(cdl.filter(ee.Filter.eq('system:index', String(year))).first())
    .select('cropland');
  return cropland.eq(CDL_CODES[CROP]).selfMask();
}

// HISTARFM red and near-infrared bands (Landsat TM/ETM+ band numbering).
// Reflectance is stored x10000.
function renameBands(img) {
  return img.select(['B3_mean_post', 'B4_mean_post'], ['Red', 'NIR']);
}

// Vegetation indices used in the paper
//   NDVI = (NIR - Red) / (NIR + Red)
//   EVI2 = 2.5 * (NIR - Red) / (NIR + 2.4 * Red + 1)
function addIndices(img) {
  img = img.multiply(0.0001);
  var ndvi = img.normalizedDifference(['NIR', 'Red']).rename('NDVI');
  var evi2 = img.expression('2.5 * (NIR - RED) / (NIR + 2.4 * RED + 1)',
    {NIR: img.select('NIR'), RED: img.select('Red')}).rename('EVI2');
  return ee.Image.cat([ndvi, evi2]);
}

// July-August mean indices for one year, masked to the crop
function seasonalComposite(year) {
  var monthly = histarfm
    .filter(ee.Filter.eq('year', year))
    .filter(ee.Filter.inList('month', MONTHS));
  return monthly.map(renameBands).map(addIndices)
    .reduce(ee.Reducer.mean())          // bands: NDVI_mean, EVI2_mean
    .updateMask(cropMask(year))
    .clip(counties)
    .toFloat()
    .set('year', year);
}

// ---- CHECK ------------------------------------------------------------------

print('Counties selected (expect 14):', counties.size());
print('HISTARFM images for first year (expect ' + MONTHS.length + '):',
      histarfm.filter(ee.Filter.eq('year', YEARS[0]))
              .filter(ee.Filter.inList('month', MONTHS)).size());

var preview = seasonalComposite(YEARS[YEARS.length - 1]);
Map.centerObject(counties, 8);
Map.addLayer(preview.select('NDVI_mean'),
  {min: 0, max: 1, palette: ['FFFFFF', 'CE7E45', 'FCD163', '99B718', '207401', '011301']},
  CROP + ' NDVI ' + YEARS[YEARS.length - 1]);
Map.addLayer(ee.Image().byte().paint(counties, 1, 2), {palette: '000000'}, 'Counties');

// ---- EXPORTS ----------------------------------------------------------------
// These create tasks in the Tasks tab. Earth Engine does not start them
// automatically: open the Tasks tab and click Run on each one.

// 1. One 30-m GeoTIFF per year
YEARS.forEach(function(year) {
  Export.image.toDrive({
    image: seasonalComposite(year),
    description: CROP + '_veg_index_' + year,
    folder: DRIVE_FOLDER,
    region: counties.geometry(),
    scale: 30,
    crs: 'EPSG:4326',
    fileFormat: 'GeoTIFF',
    maxPixels: 1e10
  });
});

// 2. County-year means, one row per county per year
var table = ee.FeatureCollection(YEARS.map(function(year) {
  return seasonalComposite(year).reduceRegions({
    collection: counties.select(['GEOID', 'NAME', 'STATEFP']),
    reducer: ee.Reducer.mean(),
    scale: 30,
    tileScale: 4
  }).map(function(f) { return f.set('year', year).setGeometry(null); });
})).flatten();

Export.table.toDrive({
  collection: table,
  description: CROP + '_veg_index_by_county',
  folder: DRIVE_FOLDER,
  fileFormat: 'CSV',
  selectors: ['GEOID', 'NAME', 'STATEFP', 'year', 'NDVI_mean', 'EVI2_mean']
});
