
//Cropland Data layer
var cdl = ee.ImageCollection('USDA/NASS/CDL');

var roi = ee.FeatureCollection('users/kessi9400/Maumee_WGS84');

var outline = ee.Image().byte().paint({
  featureCollection: roi,
  color:1,
  width:3
});

//function to generate annual cropland data layer
var annual_cdl = function(year){
  //var cdl = ee.ImageCollection('USDA/NASS/CDL');
  //var corn = 1;
  //var soybean = 5;
  var crop_id = 5;
  var cdl_year = ee.Image(cdl.filter(ee.Filter.eq('system:index', String(year))).first()).select('cropland');
  var cdl_year_crop = cdl_year.eq(crop_id).updateMask(cdl_year.eq(crop_id)).toFloat();
  var cdl_annual_clip = cdl_year_crop.clip(roi);
  return(cdl_annual_clip);
};

//Annual Cropland data layer for corn and soybean
var cdl_2019 = annual_cdl(2019);
var cdl_2018 = annual_cdl(2018);
var cdl_2017 = annual_cdl(2017);
var cdl_2016 = annual_cdl(2016);
var cdl_2015 = annual_cdl(2015);
var cdl_2014 = annual_cdl(2014);
var cdl_2013 = annual_cdl(2013);
var cdl_2012 = annual_cdl(2012);
var cdl_2011 = annual_cdl(2011);
var cdl_2010 = annual_cdl(2010);
var cdl_2009 = annual_cdl(2009);
var cdl_2008 = annual_cdl(2008);
var cdl_2007 = annual_cdl(2007);

//for landsat
var getNDVI7 = function(image) {
  image = image.multiply(0.0001);
  var ndvi = image.normalizedDifference(['NIR', 'Red']).rename("NDVI");
  
  var evi = image.select('NIR').subtract(image.select('Red')).divide(image.select('NIR').add(image.select('Red').multiply(2.4).add(1)));
  var evi2 = evi.multiply(2.5).rename('EVI2');
  var image1 = image.addBands(ndvi);
  var image2 = image1.addBands(evi2);
  
  var image3 = image2.select(['NDVI', 'EVI2']);
  return(image3); 
};

//Coefficients to convert ETM+ to OLI
var coefficients = {itcps: ee.Image.constant([0.0003, 0.0088, 0.0061, 0.0412, 0.0254, 0.0172])
.multiply(10000),
slopes: ee.Image.constant([0.8474, 0.8483, 0.9047, 0.8462, 0.8937, 0.9071])
};


// Function to get and rename bands of interest from OLI.
function renameOli(img) {
  return img.select(
      ['B2', 'B3', 'B4', 'B5', 'B6', 'B7', 'pixel_qa'],
      ['Blue', 'Green', 'Red', 'NIR', 'SWIR1', 'SWIR2', 'pixel_qa']);
}

// Function to get and rename bands of interest from ETM+.
function renameEtm(img) {
  return img.select(
      ['B1', 'B2', 'B3', 'B4', 'B5', 'B7', 'pixel_qa'],
      ['Blue', 'Green', 'Red', 'NIR', 'SWIR1', 'SWIR2', 'pixel_qa']);
}


function etmToOli(img) {
  return img.select(['Blue', 'Green', 'Red', 'NIR', 'SWIR1', 'SWIR2'])
      .multiply(coefficients.slopes)
      .add(coefficients.itcps)
      .round()
      .toShort()
      .addBands(img.select('pixel_qa'));
}

//cloud masking
function fmask(img) {
  var cloudShadowBitMask = 1 << 3;
  var snowBitMask = 1<<4;
  var cloudsBitMask = 1 << 5;
  var qa = img.select('pixel_qa');
  var mask = qa.bitwiseAnd(cloudShadowBitMask).eq(0)
                 .and(qa.bitwiseAnd(cloudsBitMask).eq(0))
                 .and(qa.bitwiseAnd(snowBitMask).eq(0));
  return img.updateMask(mask);
}

//combine functions
// Define function to prepare OLI images.
function prepOli(img) {
  var orig = img;
  img = renameOli(img);
  img = fmask(img);
  //img = calcNbr(img);
  return ee.Image(img.copyProperties(orig, orig.propertyNames()));
}

// Define function to prepare ETM+ images.
function prepEtm(img) {
  var orig = img;
  img = renameEtm(img);
  img = fmask(img);
  img = etmToOli(img);
  //img = calcNbr(img);
  return ee.Image(img.copyProperties(orig, orig.propertyNames()));
}


//Retrieve Landsat sensor collections
var oliCol = ee.ImageCollection('LANDSAT/LC08/C01/T1_SR');
var etmCol = ee.ImageCollection('LANDSAT/LE07/C01/T1_SR');
var tmCol = ee.ImageCollection('LANDSAT/LT05/C01/T1_SR');

//Define image collection fiter

        
//Prepare the collections
// Filter collections and prepare them for merging.
function getComposite(starttime, endtime){
  
var colFilter = ee.Filter.and(
    ee.Filter.bounds(roi), ee.Filter.date(starttime, endtime),
    ee.Filter.lt('CLOUD_COVER', 50),
    ee.Filter.or(
        ee.Filter.eq('IMAGE_QUALITY', 9),
        ee.Filter.eq('IMAGE_QUALITY_OLI', 9)));
  
var oliCol_season = oliCol.filter(colFilter).map(prepOli);

var etmCol_season = etmCol.filter(colFilter).map(prepEtm);
/*.map(function(image){
  var filled = image.focal_mean(2, 'square','pixels',1);
  return filled.blend(image);
});
*/

var tmCol_season = tmCol.filter(colFilter).map(prepEtm);

//print(oliCol18_oct);
//print(etmCol18_oct);

var Landsat = ee.ImageCollection(oliCol_season.merge(etmCol_season).merge(tmCol_season));
//var Landsat = ee.ImageCollection(oliCol_season.merge(tmCol_season));


var Landsat_max = Landsat.map(getNDVI7).reduce(ee.Reducer.max());


var composite_final = Landsat_max.toFloat();
return composite_final;
}

var NDVI_evi_composite = getComposite('2019-05-01', '2019-10-30');
var NDVI_evi_mask = NDVI_evi_composite.updateMask(cdl_2019);
print(NDVI_evi_mask);
var NDVIpalette = ['FFFFFF', 'CE7E45', 'DF923D', 'F1B555', 'FCD163', '99B718',
               '74A901', '056201',
                '011301'];

Map.addLayer(outline);
Map.addLayer(NDVI_evi_mask.select('EVI2_max'),{min:0, max:1, palette: NDVIpalette});

Export.image.toDrive({
  image: NDVI_evi_mask,
  description: 'soybean_NDVI_EVI_2019',
  scale: 30,
  region: roi,
  fileFormat: 'GeoTIFF'
  //Soybean_NDVI_EVI
  //maxPixels: 5000000000,
});
