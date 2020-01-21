const incidentSource = "<ul>" +
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

const swiftFunctionSource = "<table class=\\"table table-sm table-hover table-responsive\\">" +
  "<thead>" +
  "<tr>" +
  "<th scope=\\"col\\">Duration (ms)</th>" +
  "<th scope=\\"col\\">Function</th>" +
  "<th scope=\\"col\\">Line</th>" +
  "<th scope=\\"col\\">Column</th>" +
  "</tr>" +
  "</thead>" +
  "{{#each functions}}" +
  "<tr>" +
  "<th scope=\\"col\\">{{durationMS}}</th>" +
  "<th scope=\\"col\\">{{signature}}</th>" +
  "<th scope=\\"col\\">{{startingLine}}</th>" +
  "<th scope=\\"col\\">{{startingColumn}}</th>" +
  "</tr>" +
  "{{/each}}" +
  "</table>";

const swiftFunctionWarning = "<div class=\\"callout callout-warning\\">" +
"<small class=\\"text-muted\\">Warning: No Swift function compilation times were found.</small>" +
"<br>" +
"Did you compile your project with the flags -Xfrontend -debug-time-function-bodies?" +
"</div>";

const swiftFunctionTemplate = Handlebars.compile(swiftFunctionSource);

const timestampFormat = 'MMMM Do YYYY, h:mm:ss a';

showStep();

$(function () {
  $('[data-toggle="tooltip"]').tooltip()
});

function showStep() {
  const step = loadStep();
  if (step != null) {
    $('#info-title').html(step.title);
    $('#info-cache').html(step.fetchedFromCache);
    $('#info-signature').html(step.signature);
    $('#info-arch').html(step.architecture);
    $('#info-url').html(step.documentURL);
    $('#info-url').attr("href", step.documentURL);
    $('#info-duration').html(step.duration + ' secs.');
    $('#info-start-time').html(moment(new Date(step.startTimestamp * 1000)).format(timestampFormat));
    $('#info-end-time').html(moment(new Date(step.endTimestamp * 1000)).format(timestampFormat));
    showStepErrors(step);
    showStepWarnings(step);
    showSwiftFunctionTimes(step);
  }
}

function loadStep() {
  const stepId = getRequestedStepId();
  if (stepId != null) {
    const steps = buildData.filter(function (step) {
      return stepId == step.identifier;
    });
    return steps[0];
  }
  return null;
}

function getRequestedStepId() {
  let name = "step"
  if (name = (new RegExp('[?&]' + encodeURIComponent(name) + '=([^&]*)')).exec(location.search)) {
    return decodeURIComponent(name[1]);
  } else {
    return null;
  }
}

function showStepErrors(step) {
  const errorLegend = step.errorCount > 1 ? " errors in " : " error in ";
  const summaries = incidentTemplate({ "count": step.errorCount + errorLegend, "summary": step.signature, "details": step.errors });
  $('#errors-count').html(step.errorCount);
  $('#errors-summary').html(summaries);
}

function showStepWarnings(step) {
  const warningLegend = step.warningCount > 1 ? " warnings in " : " warning in ";
  const summaries = incidentTemplate({ "count": step.warningCount + warningLegend, "summary": step.signature, "details": step.warnings });
  $('#warnings-count').html(step.warningCount);
  $('#warnings-summary').html(summaries);
}

function showSwiftFunctionTimes(step) {
  if (step.detailStepType === 'swiftCompilation') {
    $('#functions-row').show();
    if (step.swiftFunctionTimes && step.swiftFunctionTimes.length > 0) {
      const functions = swiftFunctionTemplate({"functions": step.swiftFunctionTimes});
      $('#functions-summary').html(functions);
    } else {
      $('#functions-summary').html(swiftFunctionWarning);
    }

  } else {
    $('#functions-row').hide();
  }
}
