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
  drawTimeline(target);
  drawSlowestTargets(target);

  if (target === 'main') {
    document.getElementById('files-row').style.display = 'flex';
    drawSlowestFiles(cFiles, '#top_cfiles');
    drawSlowestFiles(swiftFiles, '#top_swiftfiles');
  } else {
    document.getElementById('files-row').style.display = 'none';
  }
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
  durationText += duration.seconds() + ' secs';
  document.getElementById('build-time').innerHTML = durationText;
  document.getElementById('targets').innerHTML = targets.length.toLocaleString('en');
  document.getElementById('c-files').innerHTML = cFiles.length.toLocaleString('en');
  document.getElementById('swift-files').innerHTML = swiftFiles.length.toLocaleString('en');

}

function setBuildStatus() {
  const infoData = buildData[0];
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
    return step.type === 'target';
  });
  cFiles = buildData.filter(function (step) {
    return step.type === 'detail' && step.detailStepType === cCompilation;
  });
  swiftFiles = buildData.filter(function (step) {
    return step.type === 'detail' && step.detailStepType === swiftCompilation;
  });
}

function loadTargetData(target) {
  mainStep = buildData.find(function (element) {
    return element.type === 'target' && element.identifier === target
  });
  targets = buildData.filter(function (element) {
    return element.parentIdentifier === target;
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

function drawTimeline(target) {
  const dataSeries = targets.map(function (target) {
    const title = getShortFilename(target.title, target.architecture);
    var targetStartTimestamp = target.startTimestamp;
    var targetEndTimestamp = target.endTimestamp;
    if (targetStartTimestamp < mainStep.startTimestamp) {
      targetStartTimestamp = mainStep.startTimestamp;
      targetEndTimestamp = mainStep.startTimestamp;
    }
    var start = targetStartTimestamp;
    var end = targetEndTimestamp === targetStartTimestamp ? targetEndTimestamp + 1 : targetEndTimestamp;

    return {
      x: title,
      y: [new Date(start * 1000).getTime(),
      new Date(end * 1000).getTime()],
      start: targetStartTimestamp,
      end: targetEndTimestamp
    };
  });
  const options = {
    chart: {
      height: dataSeries.length * rowHeight,
      type: 'rangeBar',
      events: {
        dataPointSelection: function (event, chartContext, config) {
          const selectedItem = targets[config.dataPointIndex];
          itemSelected(selectedItem);
        }
      }
    },
    title: {
      text: "Build times"
    },
    theme: {
      mode: 'light',
      palette: 'palette3'
    },
    plotOptions: {
      bar: {
        horizontal: true
      }
    },
    series: [{ data: dataSeries }],
    yaxis: {
      min: new Date(mainStep.startTimestamp * 1000).getTime(),
      max: new Date(mainStep.endTimestamp * 1000).getTime(),
      tooltip: {
        enabled: true,
        offsetX: 0,
      },
      labels: {
        show: true,
        align: 'right',
        minWidth: 0,
        maxWidth: 300,
        style: {
          color: undefined,
          fontSize: '12px',
          fontFamily: 'Helvetica, Arial, sans-serif',
          cssClass: 'apexcharts-yaxis-label',
        }
      }
    },

    tooltip: {
      enabled: true,
      custom: function ({ series, seriesIndex, dataPointIndex, w }) {
        const serie = dataSeries[dataPointIndex];
        const start = serie.start;
        const end = serie.end;
        const duration = end - start;
        const seconds = duration === 1 ? " second" : " seconds";
        return '<div class="arrow_box">' +
          '<span>' + serie.x + ' </span><br>' +
          '<span>' + duration + seconds + '</span>' +
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

    },
    xaxis: {
      type: 'datetime',

      labels: {
        formatter: function (value, timestamp, index) {
          return moment(new Date(value)).format("H:mm:ss");
        }
      }
    },
  }

  var chart = new ApexCharts(
    document.querySelector("#timeline"),
    options
  );
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
    return target.duration;
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
    theme: {
      mode: 'light',
      palette: 'palette3'
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
    return target.duration;
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
    theme: {
      mode: 'light',
      palette: 'palette3'
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
