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

  const STORAGE_PREFIX = 'forgebuild.placement.';

  function boolChecked(value) {
    return String(value) === 'true' || value === true;
  }

  function storageKey(builderId) {
    return `${STORAGE_PREFIX}${builderId}`;
  }

  function readStored(builderId) {
    try {
      return Object.assign({}, DEFAULTS, JSON.parse(localStorage.getItem(storageKey(builderId)) || '{}'));
    } catch (_error) {
      return Object.assign({}, DEFAULTS);
    }
  }

  function writeStored(panel) {
    const builderId = panel.dataset.builder;
    const state = currentOptions(panel);
    try { localStorage.setItem(storageKey(builderId), JSON.stringify(state)); } catch (_error) {}
  }

  function hiddenOption(name, value) {
    return `<input class="hidden-inputs" type="hidden" data-option="${name}" value="${value}">`;
  }

  function renderControls(builderId) {
    const shapeChoices = SHAPES[builderId];
    if (!shapeChoices) return '';

    const saved = readStored(builderId);
    const shape = saved.placement_shape || (builderId === 'wall' ? 'line' : 'polygon');
    return `
      <section class="placement-panel" data-placement-panel data-builder="${builderId}">
        <div class="placement-head">
          <div>
            <strong>${builderId === 'wall' ? 'Wall placement' : 'Floor placement'}</strong>
            <span data-placement-summary></span>
          </div>
          <div class="placement-actions">
            <button type="button" data-finish-drawing>Finish Drawing</button>
            <button type="button" data-cancel-drawing>Cancel</button>
          </div>
        </div>
        <div class="placement-toolbar" role="toolbar" aria-label="${builderId} drawing tools">
          ${shapeChoices.map(([id, label, key]) => `
            <button type="button" class="placement-tool ${id === shape ? 'is-active' : ''}" data-placement-shape="${id}" title="${label}${key ? ` (${key})` : ''}">
              <span class="placement-icon ${id}"></span><span>${label}</span>${key ? `<small>${key}</small>` : ''}
            </button>
          `).join('')}
        </div>
        <div class="placement-control-strip">
          <label class="placement-pill"><input type="checkbox" data-snap-check="snap_to_angle" ${boolChecked(saved.snap_to_angle) ? 'checked' : ''}> Snap to angle</label>
          <label class="placement-pill">Angle
            <select data-snap-value="snap_angle">
              ${[15, 30, 45, 90].map(v => `<option value="${v}" ${String(v) === String(saved.snap_angle) ? 'selected' : ''}>${v}</option>`).join('')}
            </select>
          </label>
          <label class="placement-pill"><input type="checkbox" data-snap-check="snap_to_distance" ${boolChecked(saved.snap_to_distance) ? 'checked' : ''}> Snap to distance</label>
          <label class="placement-pill">Distance <input type="number" min="0" step="1" data-snap-value="snap_distance" value="${saved.snap_distance || DEFAULTS.snap_distance}"></label>
          <label class="placement-pill">Alignment
            <select data-snap-value="snap_alignment">
              ${['automatic', 'center', 'left', 'right'].map(v => `<option value="${v}" ${v === saved.snap_alignment ? 'selected' : ''}>${v[0].toUpperCase() + v.slice(1)}</option>`).join('')}
            </select>
          </label>
          <button type="button" class="placement-pill" data-snap-menu>Snap settings</button>
          <div class="snap-popover" data-snap-popover hidden>
            <div class="snap-row"><span>Snap to angle</span><label><input type="checkbox" data-snap-check="snap_to_angle" ${boolChecked(saved.snap_to_angle) ? 'checked' : ''}></label></div>
            <div class="snap-row"><span>Angle</span><span class="snap-step"><button type="button" data-angle-step="-15">‹</button><strong data-angle-label>${saved.snap_angle || DEFAULTS.snap_angle}</strong><button type="button" data-angle-step="15">›</button></span></div>
            <div class="snap-row"><span>Snap to distance</span><label><input type="checkbox" data-snap-check="snap_to_distance" ${boolChecked(saved.snap_to_distance) ? 'checked' : ''}></label></div>
            <div class="snap-row"><span>Distance</span><input class="snap-distance-field" type="number" min="0" step="1" data-snap-value="snap_distance" value="${saved.snap_distance || DEFAULTS.snap_distance}"></div>
          </div>
        </div>
        <p class="placement-help">Settings are saved for this builder. Watch the SketchUp status bar for current tool, snap, alignment, and live dimensions. Esc cancels the active drawing tool.</p>
        ${hiddenOption('placement_shape', shape)}
        ${hiddenOption('snap_to_angle', saved.snap_to_angle)}
        ${hiddenOption('snap_angle', saved.snap_angle)}
        ${hiddenOption('snap_to_distance', saved.snap_to_distance)}
        ${hiddenOption('snap_distance', saved.snap_distance)}
        ${hiddenOption('snap_alignment', saved.snap_alignment)}
      </section>`;
  }

  function currentOptions(panel) {
    const state = {};
    panel.querySelectorAll('[data-option]').forEach(input => { state[input.dataset.option] = input.value; });
    return state;
  }

  function updateFooterStatus(panel) {
    const state = currentOptions(panel);
    const builderLabel = panel.dataset.builder === 'wall' ? 'Wall Builder' : 'Floor Builder';
    const snap = boolChecked(state.snap_to_angle) ? `${state.snap_angle || 45}°` : 'Free';
    const distance = boolChecked(state.snap_to_distance) ? ` / ${state.snap_distance || 12} in.` : '';
    const summary = `${state.placement_shape || 'line'} · ${snap}${distance} · ${state.snap_alignment || 'automatic'}`;
    panel.querySelectorAll('[data-placement-summary]').forEach(node => { node.textContent = summary; });
    const toolStatus = document.getElementById('status-tool');
    const builderStatus = document.getElementById('status-builder');
    if (toolStatus) toolStatus.textContent = `Tool: ${summary}`;
    if (builderStatus) builderStatus.textContent = `Builder: ${builderLabel}`;
  }

  function setOption(panel, name, value) {
    panel.querySelectorAll(`[data-option="${name}"]`).forEach(input => { input.value = value; });
    panel.querySelectorAll(`[data-snap-check="${name}"]`).forEach(input => { input.checked = boolChecked(value); });
    panel.querySelectorAll(`[data-snap-value="${name}"]`).forEach(input => { input.value = value; });
    if (name === 'snap_angle') {
      panel.querySelectorAll('[data-angle-label]').forEach(label => { label.textContent = value; });
    }
    writeStored(panel);
    updateFooterStatus(panel);
  }

  function clickActiveDrawButton(panel) {
    const detail = panel.closest('#assembly-details') || document;
    const draw = detail.querySelector('[data-action="draw"], .draw-footer .primary, .draw-footer button');
    if (draw) draw.click();
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
      const finish = event.target.closest('[data-finish-drawing]');
      if (finish) {
        clickActiveDrawButton(panel);
        return;
      }
      const cancel = event.target.closest('[data-cancel-drawing]');
      if (cancel) {
        window.ForgeBuild && window.ForgeBuild.showToast && window.ForgeBuild.showToast('Press Esc in SketchUp to cancel the active drawing tool.');
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
    updateFooterStatus(panel);
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
