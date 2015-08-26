var DATASET_URI = "../summary-data_austintexas_gov-LATEST.json";

var DAYS = (24*60*60);
var NOW = Math.floor((new Date()).getTime() / 1000);

var Age_Buckets = [
  {'age': 31*DAYS,	'description': '0-30 days'},
  {'age': 91*DAYS,	'description': '31-90 days'},
  {'age': 366*DAYS,	'description': '91-365 days'},
  {'age': 0,		'description': '>365 days'},
];

var Chart_Type = "created";
//var Chart_Type = "updated";

var Breakdown_By = {
  "created" : "date created",
  "updated" : "date last changed or updated",
};

function age_bucket_id(age) {
  for (var i = 0 ; i < Age_Buckets.length ; ++i) {
    if (age <= Age_Buckets[i].age || Age_Buckets[i].age == 0) {
      return i;
    }
  }
  throw new Error("age_bucket_id() failed for age: " + age);
}


/*
 * The City of Austin has a "Department" field in some datasets
 * that we will prefer for categorizing the dataset. I don't know
 * if that's a general Socrata practice, or just something Austin
 * does.
 */
var Category_Fields = [

  /*
   * This is how "Department" appears in the "summary" dataset, as
   * produced by "summarize-catalog.rb".
   */
  ['customFields', 'Additional Information', 'Department'],

  /*
   * This is how "Department" appears in the "catalog" dataset, as pulled
   * from Socrata.
   */
  ['view', 'metadata', 'custom_fields', 'Additional Information', 'Department'],

  /*
   * If there isn't a "Department" defined, then we'll fall back
   * to "category" which is part of the standard metadata schema.
   */
  ['category'],
];

function categorize_dataset(dataset) {

  for (var i = 0 ; i < Category_Fields.length ; ++i) {
    var fields = Category_Fields[i];
    var a = dataset;
    for (j = 0 ; a != null && j < fields.length ; ++j) {
        console.log(a);
      a = a[fields[j]];
    }
    if (a != null) {
      return a;
    }
  }

  //console.log(dataset);
  return "Undefined";
}


function summarize_by_department(data) {

  var categories = {};

  data.datasets.forEach(function(dataset) {

    switch (Chart_Type) {
    case 'created':
      dataset.age = NOW - dataset.createdAt;
      break;
    case 'updated':
      dataset.age = NOW - Math.max(dataset.rowsUpdatedAt, dataset.viewLastModified);
      break;
    default:
      throw new Error("bad value chart type \"" + Chart_Type + "\"");
    }

    var c = categorize_dataset(dataset);

    // initialize a categories[] entry if this is a new category
    if (categories[c] == null) {
      categories[c] = {
        'all': new Array(),
	'by_age': new Array(Age_Buckets.length),
      };
      for (var i = 0 ; i < Age_Buckets.length ; ++i) {
        categories[c]['by_age'][i] = new Array();
      }
    }

    // record this dataset in the category
    categories[c]['all'].push(dataset);
    categories[c]['by_age'][age_bucket_id(dataset.age)].push(dataset);

  });

  var sorted_category_names = Object.keys(categories).sort(function(a, b) {
    return categories[b]['all'].length - categories[a]['all'].length;
  });

  var table_columns = new Array();
  table_columns.push({"sTitle": "Department or Category", "sClass" : "center"});
  Age_Buckets.forEach(function(bucket) {
    table_columns.push({"sTitle": bucket.description, "sClass" : "right"});
  });
  table_columns.push({"sTitle": "Total Datasets", "sClass" : "right"});

  var table_data = new Array();
  sorted_category_names.forEach(function(c) {
    var cat = categories[c];
    var row = new Array();
    row.push(c);
    for (var i = 0 ; i < cat.by_age.length ; ++i) {
      var n = cat.by_age[i].length
      row.push(n);
    }
    row.push(cat.all.length);
    table_data.push(row);
  });

  var column_totals = new Array(table_data[0].length);
  for (var j = 0 ; j < column_totals.length ; ++j) {
    column_totals[j] = 0;
  }
  for (var i = 0 ; i < table_data.length ; ++i) {
    for (var j = 1 ; j < table_data[i].length ; ++j) {
      column_totals[j] += table_data[i][j];
    }
  }

  $('#table').dataTable({
    'bPaginate': false,
    "aaData": table_data,
    "aoColumns": table_columns,
    "aaSorting": [[table_columns.length-1, 'desc']],
  });

  var tr = $("<tr />");
  tr.append($("<th />").text("TOTAL"));
  for (var i = 1 ; i < column_totals.length ; ++i) {
    tr.append($("<th />").addClass("right").text(column_totals[i]));
  }
  $("#table tfoot").html(tr);

  $('#host').text(data.host);
  $('#portal_url').attr("href", "https://" + data.host + "/");
  $('#timestamp').text(new Date(data.timestamp*1000));
  $('#breakdown_by').text(Breakdown_By[Chart_Type]);

}

function start(process_function) {
  $.getJSON(DATASET_URI, summarize_by_department)
  .fail(function(jqXHR, textStatus, errorThrown) {
  console.log(jqXHR);
    alert("Failed to load dataset. [" + textStatus + "]\n\nURI = " + DATASET_URI);
  });
}

