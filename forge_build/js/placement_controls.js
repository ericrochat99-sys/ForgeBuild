(() => {
  const SHAPES = {
    floor: [
      ['polygon', 'Polygon', 'Esc'],
      ['arc', 'Arc', 'A'],
      ['rectangle', 'Rectangle', 'R'],
      ['circle', 'Circle', 'C']
    ],
    wall: [
      ['line', 'Line', 'Esc'],
      ['polygon', 'Polyline', 'P'],
      ['rectangle', 'Rectangle', 'R'],
      ['arc', 'Arc', 'A']
    ]
  };

  const DEFAULTS = {
    snap_to_angle: 'true',
    snap_angle: '45',
    snap_to_distance: 'false',
    snap_distance: '12',
    snap_alignment: 'automatic'
  };

  function boolChecked(value) {
    return String(value) === 'true' || value === true;
  }

  function hiddenOption(name, value) {
    return `<input class="hidden-inputs" type="hidden" data-option="${name}" value="${value}">`;
  }

  function renderControls(builderId) {
    const shapeChoices = SHAPES[builderId];
    if (!shapeChoices) return '';

    const shape = builderId === 'wall' ? 'line' : 'polygon';
    return `
      <section class="placement-panel" data-placement-panel data-builder="${builderId}">
        <div class="placement-toolbar" role="toolbar" aria-label="${builderId} drawing tools">
          ${shapeChoices.map(([id, label, key]) => `
            <button type="button" class="placement-tool ${id === shape ? 'is-active' : ''}" data-placement-shape="${id}" title="${label}${key ? ` (${key})` : ''}">
              <span class="placement-icon ${id}"></span><span>${label}</span>${key ? `<small>${key}</small>` : ''}
            </button>
          `).join('')}
        </div>
        <div class="placement-control-strip">
          <label class="placement-pill"><input type="checkbox" data-snap-check="snap_to_angle" ${boolChecked(DEFAULTS.snap_to_angle) ? 'checked' : ''}> Snap to angle</label>
          <label class="placement-pill">Angle
            <select data-snap-value="snap_angle">
              ${[15, 30, 45, 90].map(v => `<option value="${v}" ${String(v) === DEFAULTS.snap_angle ? 'selected' : ''}>${v}</option>`).join('')}
            </select>
          </label>
          <label class="placement-pill"><input type="checkbox" data-snap-check="snap_to_distance" ${boolChecked(DEFAULTS.snap_to_distance) ? 'checked' : ''}> Snap to distance</label>
          <label class="placement-pill">Distance <input type="number" min="0" step="1" data-snap-value="snap_distance" value="${DEFAULTS.snap_distance}"></label>
          <label class="placement-pill">Alignment
            <select data-snap-value="snap_alignment">
              <option value="automatic">Automatic</option>
              <option value="center">Center</option>
              <option value="left">Left</option>
              <option value="right">Right</option>
            </select>
          </label>
          <button type="button" class="placement-pill" data-snap-menu>Snap settings</button>
          <div class="snap-popover" data-snap-popover hidden>
            <div class="snap-row"><span>Snap to angle</span><label><input type="checkbox" data-snap-check="snap_to_angle" checked></label></div>
            <div class="snap-row"><span>Angle</span><span class="snap-step"><button type="button" data-angle-step="-15">‹</button><strong data-angle-label>45</strong><button type="button" data-angle-step="15">›</button></span></div>
            <div class="snap-row"><span>Snap to distance</span><label><input type="checkbox" data-snap-check="snap_to_distance"></label></div>
            <div class="snap-row"><span>Distance</span><input class="snap-distance-field" type="number" min="0" step="1" data-snap-value="snap_distance" value="12"></div>
          </div>
        </div>
        <p class="placement-help">These controls apply when you start drawing the selected floor or wall assembly. Tap Shift in SketchUp to cycle wall placement side while drawing.</p>
        ${hiddenOption('placement_shape', shape)}
        ${hiddenOption('snap_to_angle', DEFAULTS.snap_to_angle)}
        ${hiddenOption('snap_angle', DEFAULTS.snap_angle)}
        ${hiddenOption('snap_to_distance', DEFAULTS.snap_to_distance)}
        ${hiddenOption('snap_distance', DEFAULTS.snap_distance)}
        ${hiddenOption('snap_alignment', DEFAULTS.snap_alignment)}
      </section>`;
  }

  function setOption(panel, name, value) {
    panel.querySelectorAll(`[data-option="${name}"]`).forEach(input => { input.value = value; });
    panel.querySelectorAll(`[data-snap-check="${name}"]`).forEach(input => { input.checked = boolChecked(value); });
    panel.querySelectorAll(`[data-snap-value="${name}"]`).forEach(input => { input.value = value; });
    if (name === 'snap_angle') {
      panel.querySelectorAll('[data-angle-label]').forEach(label => { label.textContent = value; });
    }
  }

  function initPlacementPanel(panel) {
    if (!panel || panel.dataset.ready === '1') return;
    panel.dataset.ready = '1';
    panel.addEventListener('click', event => {
      const shapeButton = event.target.closest('[data-placement-shape]');
      if (shapeButton) {
        panel.querySelectorAll('[data-placement-shape]').forEach(button => button.classList.toggle('is-active', button === shapeButton));
        setOption(panel, 'placement_shape', shapeButton.dataset.placementShape);
        return;
      }
      const menu = event.target.closest('[data-snap-menu]');
      if (menu) {
        const popover = panel.querySelector('[data-snap-popover]');
        popover.hidden = !popover.hidden;
        return;
      }
      const step = event.target.closest('[data-angle-step]');
      if (step) {
        const current = Number(panel.querySelector('[data-option="snap_angle"]').value || 45);
        const next = Math.min(180, Math.max(1, current + Number(step.dataset.angleStep || 0)));
        setOption(panel, 'snap_angle', String(next));
      }
    });
    panel.addEventListener('change', event => {
      const check = event.target.closest('[data-snap-check]');
      if (check) {
        setOption(panel, check.dataset.snapCheck, check.checked ? 'true' : 'false');
        return;
      }
      const value = event.target.closest('[data-snap-value]');
      if (value) setOption(panel, value.dataset.snapValue, value.value);
    });
  }

  function install() {
    if (!window.ForgeBuild || window.ForgeBuild.__placementControlsInstalled) return;
    window.ForgeBuild.__placementControlsInstalled = true;
    const original = window.ForgeBuild.renderAssemblyDetails;
    window.ForgeBuild.renderAssemblyDetails = function renderAssemblyDetailsWithControls(builder, tool) {
      original.call(this, builder, tool);
      if (!['floor', 'wall'].includes(builder.id)) return;
      const detail = document.getElementById('assembly-details');
      if (!detail || detail.querySelector('[data-placement-panel]')) return;
      const footer = detail.querySelector('.draw-footer');
      const template = document.createElement('template');
      template.innerHTML = renderControls(builder.id).trim();
      const panel = template.content.firstElementChild;
      detail.insertBefore(panel, footer || null);
      initPlacementPanel(panel);
    };
  }

  install();
})();
