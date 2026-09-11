(() => {
  function esc(value) {
    const div = document.createElement('div');
    div.textContent = value ?? '';
    return div.innerHTML;
  }

  function selectedDrawing() {
    const select = document.getElementById('drawing-list');
    const id = select && select.value;
    return (window.ForgeBuild?.state?.drawings || []).find(d => d.id === id) || null;
  }

  function setNext(text) {
    const next = document.getElementById('next');
    if (next) next.textContent = text;
  }

  function injectPlanTraceWorkspace() {
    const plans = document.getElementById('plans');
    if (!plans || document.getElementById('plan-trace-workspace')) return;

    const workspace = document.createElement('section');
    workspace.id = 'plan-trace-workspace';
    workspace.className = 'plan-trace-workspace';
    workspace.innerHTML = `
      <div class="trace-card trace-hero">
        <div>
          <label>PHASE 2 WORKFLOW</label>
          <h3>Trace Plan Mode</h3>
          <p>Use this as the step-by-step plan workflow: import, pick sheet, place at elevation, calibrate, then trace assemblies.</p>
        </div>
        <button class="primary" id="trace-mode-start">Start Trace Workflow</button>
      </div>
      <div class="trace-steps" id="trace-steps">
        ${['Import plan','Choose sheet/elevation','Calibrate scale','Trace floor/walls/roof','Review quantities'].map((name, index) => `<div class="trace-step" data-step="${index}"><b>${index + 1}</b><span>${name}</span></div>`).join('')}
      </div>
      <div class="trace-grid">
        <div class="trace-card">
          <label>PLAN LAYERS</label>
          <h3>Selected Plan Controls</h3>
          <p id="trace-selected-plan">Choose an imported plan to manage visibility and tracing.</p>
          <div class="trace-actions">
            <button id="trace-focus-plan">Focus Plan</button>
            <button id="trace-calibrate-plan">Calibrate</button>
            <button id="trace-plan-fade">Fade</button>
            <button id="trace-plan-unfade">Full Opacity</button>
          </div>
          <label class="trace-field">Trace elevation
            <input id="trace-elevation" type="number" step="1" value="0">
          </label>
          <button id="trace-apply-elevation">Apply Elevation</button>
        </div>
        <div class="trace-card">
          <label>TRACE ASSEMBLIES</label>
          <h3>What are you tracing?</h3>
          <div class="trace-assembly-buttons">
            <button data-trace-workflow="floor">Floor Area</button>
            <button data-trace-workflow="wall">Wall Run</button>
            <button data-trace-workflow="roof">Roof Area</button>
            <button data-trace-workflow="opening">Opening</button>
            <button data-trace-workflow="grid">Grid Line</button>
            <button data-trace-workflow="level">Level</button>
          </div>
          <p class="trace-help" id="trace-help">Select an assembly type, then click points on the imported plan in SketchUp.</p>
        </div>
      </div>
      <div class="trace-card trace-review">
        <label>TRACE PREVIEW CHECKLIST</label>
        <div class="trace-checklist">
          <span>☐ Plan calibrated</span>
          <span>☐ Correct elevation selected</span>
          <span>☐ Plan visible/faded for tracing</span>
          <span>☐ Assembly type confirmed</span>
        </div>
      </div>`;

    const traceHeading = plans.querySelector('h3:last-of-type');
    if (traceHeading) {
      plans.insertBefore(workspace, traceHeading);
    } else {
      plans.appendChild(workspace);
    }
  }

  function refreshTracePanel() {
    const drawing = selectedDrawing();
    const label = document.getElementById('trace-selected-plan');
    const elevation = document.getElementById('trace-elevation');
    if (!label || !elevation) return;

    if (!drawing) {
      label.textContent = 'Choose an imported plan to manage visibility and tracing.';
      elevation.value = '0';
      return;
    }

    label.innerHTML = `<strong>${esc(drawing.sheet || drawing.filename)}</strong><br><small>${esc(drawing.discipline || 'drawing')} · page ${esc(drawing.page || 1)} · scale ${Number(drawing.scale || 1).toFixed(4)}</small>`;
    elevation.value = drawing.elevation || 0;
  }

  function markStep(index) {
    document.querySelectorAll('.trace-step').forEach(step => {
      const value = Number(step.dataset.step);
      step.classList.toggle('done', value < index);
      step.classList.toggle('current', value === index);
    });
  }

  function startTrace(kind) {
    const drawing = selectedDrawing();
    if (!drawing) {
      window.ForgeBuild?.showError?.('Choose or import a plan before tracing.');
      window.ForgeBuild?.show?.('plans');
      return;
    }
    markStep(3);
    setNext(`Trace ${kind} from ${drawing.sheet || drawing.filename}`);
    const help = document.getElementById('trace-help');
    if (help) help.textContent = `Trace ${kind}: SketchUp is ready for point selection. Press Esc to finish.`;
    window.sketchup.trace_drawing(kind);
  }

  function installTraceHandlers() {
    if (window.ForgeBuild?.__planTraceInstalled) return;
    window.ForgeBuild.__planTraceInstalled = true;

    const originalRenderDrawings = window.ForgeBuild.renderDrawings;
    window.ForgeBuild.renderDrawings = function renderDrawingsWithTracePanel(drawings) {
      originalRenderDrawings.call(this, drawings);
      injectPlanTraceWorkspace();
      refreshTracePanel();
      markStep(drawings && drawings.length ? 1 : 0);
    };

    document.addEventListener('change', event => {
      if (event.target && event.target.id === 'drawing-list') refreshTracePanel();
    });

    document.addEventListener('click', event => {
      const workflow = event.target.closest('[data-trace-workflow]');
      if (workflow) {
        startTrace(workflow.dataset.traceWorkflow);
        return;
      }

      if (event.target.id === 'trace-mode-start') {
        window.ForgeBuild?.show?.('plans');
        markStep((window.ForgeBuild?.state?.drawings || []).length ? 1 : 0);
        setNext('Import a plan or choose the plan to trace');
      }

      if (event.target.id === 'trace-focus-plan') {
        const drawing = selectedDrawing();
        if (!drawing) return window.ForgeBuild?.showError?.('Choose an imported plan first.');
        window.ForgeBuild?.showError?.(`Selected ${drawing.sheet || drawing.filename}. Use Calibrate or Trace next.`);
      }

      if (event.target.id === 'trace-calibrate-plan') {
        const drawing = selectedDrawing();
        if (!drawing) return window.ForgeBuild?.showError?.('Choose an imported plan first.');
        markStep(2);
        window.sketchup.calibrate_drawing(drawing.id);
      }

      if (event.target.id === 'trace-apply-elevation') {
        const drawing = selectedDrawing();
        if (!drawing) return window.ForgeBuild?.showError?.('Choose an imported plan first.');
        const elevation = Number(document.getElementById('trace-elevation').value || 0);
        window.sketchup.set_drawing_elevation(drawing.id, elevation);
      }

      if (event.target.id === 'trace-plan-fade') {
        const plans = document.getElementById('plans');
        plans.classList.add('trace-faded-ui');
        window.ForgeBuild?.showError?.('Trace UI faded. The imported plan remains selectable in SketchUp.');
      }

      if (event.target.id === 'trace-plan-unfade') {
        document.getElementById('plans').classList.remove('trace-faded-ui');
      }
    });

    injectPlanTraceWorkspace();
    refreshTracePanel();
  }

  document.addEventListener('DOMContentLoaded', installTraceHandlers);
})();
