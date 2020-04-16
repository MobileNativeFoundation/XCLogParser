// Copyright (c) 2019 Spotify AB.
//
// Licensed to the Apache Software Foundation (ASF) under one
// or more contributor license agreements.  See the NOTICE file
// distributed with this work for additional information
// regarding copyright ownership.  The ASF licenses this file
// to you under the Apache License, Version 2.0 (the
// "License"); you may not use this file except in compliance
// with the License.  You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

let mainStep;
let targets;
let cFiles;
let swiftFiles;

const rowHeight = 45;

const swiftAggregatedCompilation = 'swiftAggregatedCompilation';

const swiftCompilation = 'swiftCompilation';

const cCompilation = 'cCompilation'

const incidentSource = "<details>" +
  "<summary><span class='font-weight-bold'>{{count}}</span>{{summary}}</summary>" +
  "<p class='bg-light'>" +
  "<ul>" +
  "{{#each details}}" +
  "{{#if documentURL}}" +
  "<li>{{clangWarning}} {{title}} " +
  "In <a href='{{documentURL}}'>{{documentURL}}</a> Line {{startingLineNumber}} column {{startingColumnNumber}}</li>" +
  "{{else}}" +
  "<li>{{clangWarning}} {{title}}</li>" +
  "{{/if}}" +
  "{{/each}}" +
  "</ul>" +
  "</p>" +
  "</details>";

const incidentTemplate = Handlebars.compile(incidentSource);

const swiftFunctionSource = "<table id='swift-functions-table' class='display table table-sm table-hover table-responsive table-striped'>" +
  "<thead>" +
  "<tr>" +
  "<th scope='col'>Duration (ms)</th>" +
  "<th scope='col'>File</th>" +
  "<th scope='col'>Function</th>" +
  "<th scope='col'>Line</th>" +
  "<th scope='col'>Column</th>" +
  "<th scope='col'>Occurrences</th>" +
  "<th scope='col'>Cumulative (ms)</th>" +
  "</tr>" +
  "</thead>" +
  "{{#each functions}}" +
  "<tr>" +
  "<th scope='col'>{{durationMS}}</th>" +
  "<th scope='col'>{{file}}</th>" +
  "<th scope='col'>{{signature}}</th>" +
  "<th scope='col'>{{startingLine}}</th>" +
  "<th scope='col'>{{startingColumn}}</th>" +
  "<th scope='col'>{{occurrences}}</th>" +
  "<th scope='col'>{{cumulative}}</th>" +
  "</tr>" +
  "{{/each}}" +
  "</table>";

const swiftTypeCheckSource = "<table id='swift-typechecks-table' class='table table-sm table-hover table-responsive table-striped'>" +
  "<thead>" +
  "<tr>" +
  "<th scope='col'>Duration (ms)</th>" +
  "<th scope='col'>File</th>" +
  "<th scope='col'>Line</th>" +
  "<th scope='col'>Column</th>" +
  "<th scope='col'>Occurrences</th>" +
  "<th scope='col'>Cumulative (ms)</th>" +
  "</tr>" +
  "</thead>" +
  "{{#each functions}}" +
  "<tr>" +
  "<th scope='col'>{{durationMS}}</th>" +
  "<th scope='col'>{{file}}</th>" +
  "<th scope='col'>{{startingLine}}</th>" +
  "<th scope='col'>{{startingColumn}}</th>" +
  "<th scope='col'>{{occurrences}}</th>" +
  "<th scope='col'>{{cumulative}}</th>" +
  "</tr>" +
  "{{/each}}" +
  "</table>";

const swiftFunctionWarning = "<div class='callout callout-warning'>" +
"<small class='text-muted'>Warning: No Swift function compilation times were found.</small>" +
"<br>" +
"Did you compile your project with the flags -Xfrontend -debug-time-function-bodies?" +
"</div>";

const swiftTypeCheckWarning = "<div class='callout callout-warning'>" +
"<small class='text-muted'>Warning: No Swiftc type checks times were found.</small>" +
"<br>" +
"Did you compile your project with the flags -Xfrontend -debug-time-expression-type-checking?" +
"</div>";

const swiftFunctionTemplate = Handlebars.compile(swiftFunctionSource);

const swiftTypeCheckTemplate = Handlebars.compile(swiftTypeCheckSource);

drawCharts();

function drawCharts() {
  const target = getRequestedTarget();
  if (target === 'main') {
    loadMainData();
  } else {
    loadTargetData(target);
  }
  drawHeaders(target);
  drawErrors(target);
  drawWarnings(target);
  drawTimeline();
  drawSlowestTargets(target);

  if (target === 'main') {
    document.getElementById('files-row').style.display = 'flex';
    drawSlowestFiles(cFiles, '#top_cfiles');
    drawSlowestFiles(swiftFiles, '#top_swiftfiles');
  } else {
    document.getElementById('files-row').style.display = 'none';
  }
  drawSwiftFunctions(target);
  drawSwiftTypeChecks(target);
}

function drawHeaders(target) {
  setBuildStatus();
  document.getElementById('build-info').innerHTML = getBuildInfo();
  if (target === 'main') {
    document.getElementById('schema-title').innerHTML = 'Schema';
    document.getElementById('schema').innerHTML = mainStep.schema;
    document.getElementById('targets-title').innerHTML = 'Targets';
  } else {
    document.getElementById('schema-title').innerHTML = 'Target';
    document.getElementById('schema').innerHTML = mainStep.title.replace('Build target', '');
    document.getElementById('targets-title').innerHTML = 'Files';
  }
  const status = mainStep.buildStatus.charAt(0).toUpperCase() + mainStep.buildStatus.slice(1);
  document.getElementById('build-status').innerHTML = status;
  const duration = moment.duration(mainStep.duration * 1000);
  var durationText = '';
  if (duration.hours() > 0) {
    durationText += duration.hours() + ' hrs, ';
  }
  if (duration.minutes() > 0) {
    durationText += duration.minutes() + ' mins, ';
  }
  durationText += Math.round(duration.seconds()) + ' secs';
  document.getElementById('build-time').innerHTML = durationText;
  document.getElementById('targets').innerHTML = targets.length.toLocaleString('en');
  const cCompiledFiles = cFiles.filter(function (file) {
    return file.fetchedFromCache == false;
  })
  const swiftCompiledFiles = swiftFiles.filter(function (file) {
    return file.fetchedFromCache == false;
  })
  // document.getElementById('c-files-compiled').innerHTML = cCompiledFiles.length.toLocaleString('en') + ' compiled';
  document.getElementById('c-files-total').innerHTML = cFiles.length.toLocaleString('en') + ' total';
  // document.getElementById('swift-files-compiled').innerHTML = swiftCompiledFiles.length.toLocaleString('en') + ' compiled';
  document.getElementById('swift-files-total').innerHTML = swiftFiles.length.toLocaleString('en') + ' total';

}

function setBuildStatus() {
  const status = mainStep.buildStatus.charAt(0).toUpperCase() + mainStep.buildStatus.slice(1);
  const statusBox = document.getElementById('status-box');
  if (status.toLowerCase() === 'succeeded') {
    statusBox.classList.add('bg-success');
  } else if (status.toLowerCase().includes('failed') || status.toLowerCase().includes('errors')) {
    statusBox.classList.add('bg-danger');
  } else {
    statusBox.classList.add('bg-warning');
  }
}

function getBuildInfo() {
  const infoData = buildData[0];
  const buildDate = new Date(infoData.startTimestamp * 1000);
  let info = infoData.title.replace('Build ', '');
  info += ' Build ' + infoData.identifier + ', generated on ';
  info += buildDate.toLocaleString();
  return info;
}

function loadMainData() {
  mainStep = buildData[0];
  targets = buildData.filter(function (step) {
    return step.type === 'target' && step.fetchedFromCache === false;
  });
  cFiles = buildData.filter(function (step) {
    return step.type === 'detail' && step.detailStepType === cCompilation
    && step.fetchedFromCache === false;
  });
  swiftFiles = buildData.filter(function (step) {
    return step.type === 'detail' && step.detailStepType === swiftCompilation
    && step.fetchedFromCache === false;
  });
}

function loadTargetData(target) {
  mainStep = buildData.find(function (element) {
    return element.type === 'target' && element.identifier === target
    && element.fetchedFromCache === false;
  });
  targets = buildData.filter(function (element) {
    return element.parentIdentifier === target && element.fetchedFromCache === false;
  });

  // In xcodebuild, the swift files compilation are under an Aggregated build step.
  // This code adds them and removes the aggregated steps
  swiftAggregatedBuilds = targets.filter(function (step) {
    return step.detailStepType === swiftAggregatedCompilation;
  });
  const aggregatedSubSteps = swiftAggregatedBuilds.flatMap(function (aggregate) {
    return buildData.filter(function (element) {
      return element.parentIdentifier === aggregate.identifier;
    });
  });
  targets = targets.concat(aggregatedSubSteps).filter(function (step) {
    return step.detailStepType != swiftAggregatedCompilation;
  }).sort(function (lhs, rhs) {
    return lhs.startTimestamp - rhs.startTimestamp;
  });

  cFiles = targets.filter(function (step) {
    return step.detailStepType === cCompilation;
  });
  swiftFiles = targets.filter(function (step) {
    return step.detailStepType === swiftCompilation;
  });
}

function drawTimeline() {
  const dataSeries = targets.map(function (target) {
    const title = getShortFilename(target.title, target.architecture);
    const targetStartTimestamp = target.startTimestamp;
    const targetEndTimestamp = target.endTimestamp;
    const start = targetStartTimestamp;
    const end = targetEndTimestamp === targetStartTimestamp ? targetEndTimestamp + 1 : targetEndTimestamp;

    return {
      x: title,
      y: [new Date(start * 1000).getTime(),
      new Date(end * 1000).getTime()],
      start: targetStartTimestamp,
      end: targetEndTimestamp
    };
  });

  const compilationSeries = targets.map(function (target) {
    const title = getShortFilename(target.title, target.architecture);
    const targetStartTimestamp = target.startTimestamp;
    const targetEndTimestamp = target.compilationEndTimestamp;
    const start = targetStartTimestamp;
    const end = targetEndTimestamp === targetStartTimestamp ? targetEndTimestamp + 1 : targetEndTimestamp;

    return {
      x: title,
      y: [new Date(start * 1000).getTime(),
      new Date(end * 1000).getTime()],
      start: targetStartTimestamp,
      end: targetEndTimestamp
    };
  });


  var options = {
    series: [
    {
      name: 'Build time',
      data: dataSeries
    },
    {
      name: 'Compilation time',
      data: compilationSeries
    }
  ],
    chart: {
      height: dataSeries.length * rowHeight,
      type: 'rangeBar',
      events: {
        dataPointSelection: function (event, chartContext, config) {
          console.log(config);
          const selectedItem = targets[config.dataPointIndex];
          console.log(selectedItem);
          itemSelected(selectedItem);
        }
      }
  },
  plotOptions: {
    bar: {
      horizontal: true,
      barHeight: '80%'
    }
  },
  xaxis: {
    type: 'datetime'
  },
  stroke: {
    width: 1
  },
  fill: {
    type: 'solid',
    opacity: 0.6
  },
  legend: {
    position: 'top',
    horizontalAlign: 'left'
  },
  tooltip: {
    enabled: true,
    custom: function ({ series, seriesIndex, dataPointIndex, w }) {
      const serie = dataSeries[dataPointIndex];
      const start = serie.start;
      const end = serie.end;
      const duration = (end - start).toFixed(3);
      return '<div class="arrow_box">' +
        '<span>' + serie.x + ' </span><br>' +
        '<span>' + duration + ' seconds</span>' +
        '</div>'
    },
    y: {
      enabled: true,
      show: true,
      formatter: undefined,
      title: {
        formatter: (seriesName) => seriesName,
      },
    },

  }
  };

  var chart = new ApexCharts(document.querySelector("#timeline"), options);
  chart.render();
}

function drawSlowestTargets(target) {
  let clone = targets.slice(0);
  const targetsData = clone.sort(function (lhs, rhs) {
    return rhs.duration - lhs.duration
  });
  const top = Math.min(20, targetsData.length);
  const topTargets = targetsData.slice(0, top);
  const durations = topTargets.map(function (target) {
    return target.duration.toFixed(3);
  });
  const names = topTargets.map(function (step) {
    if (target === 'main') {
      return step.title.replace('Build target ', '');
    } else {
      return getShortFilename(step.title, step.architecture);
    }
  });
  const options = {
    chart: {
      height: names.length * rowHeight,
      type: 'bar',
      events: {
        dataPointSelection: function (event, chartContext, config) {
          const selectedItem = topTargets[config.dataPointIndex];
          itemSelected(selectedItem);
        }
      }
    },
    plotOptions: {
      bar: {
        distributed: true,
        horizontal: true
      }
    },
    dataLabels: {
      enabled: false
    },
    series: [{
      data: durations
    }],
    xaxis: {
      categories: names
    },
    legend: {
      show: false
    },
    tooltip: {
      y: {
        title: {
          formatter: function () {
            return 'Seconds'
          }
        }
      }
    }
  }

  var chart = new ApexCharts(
    document.querySelector("#bartargets"),
    options
  );

  chart.render();
}


function drawSlowestFiles(collection, element) {
  const sortedData = collection.sort(function (lhs, rhs) {
    return rhs.duration - lhs.duration;
  });
  const top = Math.min(20, sortedData.length);
  const topTargets = sortedData.slice(0, top);
  const durations = topTargets.map(function (target) {
    return target.duration.toFixed(3);
  });
  const names = topTargets.map(function (step) {
    return getShortFilename(step.title, step.architecture);
  });
  const options = {
    chart: {
      height: names.length * rowHeight,
      type: 'bar',
      events: {
        dataPointSelection: function (event, chartContext, config) {
          const selectedItem = topTargets[config.dataPointIndex];
          itemSelected(selectedItem);
        }
      }
    },
    plotOptions: {
      bar: {
        distributed: true,
        horizontal: true
      }
    },
    dataLabels: {
      enabled: false
    },
    series: [{
      data: durations
    }],
    xaxis: {
      categories: names
    },
    legend: {
      show: false
    },
    tooltip: {
      y: {
        title: {
          formatter: function () {
            return 'Seconds'
          }
        }
      }
    }
  }

  var chart = new ApexCharts(
    document.querySelector(element),
    options
  );

  chart.render();
}

function getRequestedTarget() {
  let name = "target"
  if (name = (new RegExp('[?&]' + encodeURIComponent(name) + '=([^&]*)')).exec(location.search)) {
    return decodeURIComponent(name[1]);
  } else {
    return "main"
  }
}

function getShortFilename(fileName, arch) {
  if (fileName.includes('/')) {
    const components = fileName.replace('Compile ', '').split('/');
    const command = fileName.split(' ')[0]
    const startIndex = Math.max(3, components.length - 3);
    if (arch != '') {
      return command + ' ' + arch + ' ' + components.slice(startIndex, components.length).join('/');
    }
    return command + ' ' + components.slice(startIndex, components.length).join('/');
  } else {
    return fileName
  }
}

function drawErrors(target) {
  $('#errors-count').html(mainStep.errorCount);
  showErrors(target);
}

function drawWarnings(target) {
  $('#warnings-count').html(mainStep.warningCount);
  showWarnings(target);
}

function showErrors(target) {
  const steps = target === 'main' ? buildData : targets;
  const stepsWithErrors = steps.filter(function (step) {
    return step.type != 'main' && step.type != 'target' && step.errorCount > 0;
  }).sort(function (lhs, rhs) {
    return rhs.warningCount - lhs.warningCount;
  });
  var summaries = '';
  stepsWithErrors.forEach(function (step) {
    const errorLegend = step.errorCount > 1 ? " errors in " : " error in ";
    summaries += incidentTemplate({ "count": step.errorCount + errorLegend, "summary": step.signature, "details": step.errors });
  });
  $('#errors-summary').html(summaries);
  if (stepsWithErrors.length > 0) {
    $('#errors').show();
  } else {
    $('#errors').hide();
  }
}

function showWarnings(target) {
  const steps = target === 'main' ? buildData : targets;
  const stepsWithWarnings = steps.filter(function (step) {
    return step.warnings.length > 0;
  }).sort(function (lhs, rhs) {
    return rhs.warningCount - lhs.warningCount;
  });
  var summaries = '';
  stepsWithWarnings.forEach(function (step) {
    if (step.warnings.length > 0) {
      const warningLegend = step.warningCount > 1 ? " warnings in " : " warning in ";
      summaries += incidentTemplate({ "count": step.warningCount + warningLegend, "summary": step.signature, "details": step.warnings });
    }
  });
  $('#warnings-summary').html(summaries);
  if (stepsWithWarnings.length > 0) {
    $('#warnings').show();
  } else {
    $('#warnings').hide();
  }
}

function itemSelected(selectedItem) {
  if (selectedItem.type === 'target') {
    window.location.href = window.location.href + "?target=" + selectedItem.identifier;
  } else if (selectedItem.type === 'detail') {
    const stepUrl = window.location.href.replace('index.html', 'step.html');
    window.location.href =  stepUrl + "?step=" + selectedItem.identifier;
  }
}

function drawSwiftFunctions(target) {
  const steps = target === 'main' ? buildData : targets;
  const swiftFunctions = steps.filter(function (step) {
    return step.swiftFunctionTimes && step.swiftFunctionTimes.length > 0;
  }).flatMap(function (step) {
    return step.swiftFunctionTimes
  }).map(function(f) {
    f.cumulative = Math.round(f.occurrences * f.durationMS * 100) / 100;
    return f;
  }).sort(function (lhs, rhs) {
    return rhs.durationMS - lhs.durationMS;
  });
  if (swiftFunctions.length > 0) {
    const functions = swiftFunctionTemplate({"functions": swiftFunctions});
    $('#swiftfunctions').html(functions);
    $('#swift-functions-table').DataTable({
      "info": false,
      "scrollX": true,
      "order": [[ 0, "desc" ]]
    });
  } else {
    $('#swiftfunctions').html(swiftFunctionWarning);
  }
}

function drawSwiftTypeChecks(target) {
  const steps = target === 'main' ? buildData : targets;
  const swiftTypeCheckTimes = steps.filter(function (step) {
    return step.swiftTypeCheckTimes && step.swiftTypeCheckTimes.length > 0;
  }).flatMap(function (step) {
    return step.swiftTypeCheckTimes
  }).map(function(f) {
    f.cumulative = Math.round(f.occurrences * f.durationMS * 100) / 100;
    return f;
  }).sort(function (lhs, rhs) {
    return rhs.durationMS - lhs.durationMS;
  });
  if (swiftTypeCheckTimes.length > 0) {
    const functions = swiftTypeCheckTemplate({"functions": swiftTypeCheckTimes});
    $('#swifttypechecks').html(functions);
    $('#swift-typechecks-table').DataTable({
      "info": false,
      "scrollX": true,
      "order": [[ 0, "desc" ]]
    });
  } else {
    $('#swifttypechecks').html(swiftTypeCheckWarning);
  }
}
