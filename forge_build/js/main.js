window.ForgeBuild = {
  bootstrap(payload) {
    document.getElementById('version').textContent = `Version ${payload.version}`;
    this.renderModules(payload.modules);
    this.renderDrawings(payload.drawings || []);
  },
  selectedAssembly: null,
  showInspector() {
    document.getElementById('inspector').scrollIntoView({ behavior: 'smooth', block: 'start' });
  },
  selectionChanged(assembly) {
    this.selectedAssembly = assembly;
    const form = document.getElementById('property-form');
    const empty = document.getElementById('selection-empty');
    const badge = document.getElementById('selection-type');
    form.hidden = !assembly;
    empty.hidden = !!assembly;
    if (!assembly) { badge.textContent = 'Nothing selected'; return; }
    badge.textContent = `${assembly.builder} · ${assembly.object_type.replaceAll('_', ' ')}`;
    const fields = ['assembly', 'material', 'tag', 'finish', 'fire_rating', 'comments'];
    document.getElementById('identity-fields').innerHTML = fields.map(key =>
      `<label class="option-field">${key.replaceAll('_', ' ')}<input data-property="${key}" value="${this.escape(assembly[key] || '')}"></label>`).join('');
    document.getElementById('parameter-fields').innerHTML = Object.entries(assembly.parameters || assembly.dimensions || {})
      .filter(([key, value]) => key !== 'system' && (typeof value === 'number' || typeof value === 'string'))
      .map(([key, value]) => `<label class="option-field">${key.replaceAll('_', ' ')}<input type="${typeof value === 'number' ? 'number' : 'text'}" ${typeof value === 'number' ? 'step="0.125"' : ''} data-parameter="${key}" value="${this.escape(value)}"></label>`).join('');
    document.querySelectorAll('[data-display]').forEach(button => button.classList.toggle('active', button.dataset.display === (assembly.display_mode || 'detailed')));
    document.getElementById('preset-list').innerHTML = '<option value="">Assembly presets</option>' + (assembly.presets || []).map(preset => `<option value="${this.escape(preset.name)}">${this.escape(preset.name)}${preset.default ? ' (Default)' : ''}</option>`).join('');
  },
  escape(value) {
    return String(value).replaceAll('&', '&amp;').replaceAll('"', '&quot;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');
  },
  presetSaved(name) { this.showError(`Preset “${name}” saved.`); },
  renderModules(modules) {
    const container = document.getElementById('modules');
    if (!modules.length) return;
    container.classList.remove('empty');
    container.innerHTML = modules.map(module => `
      <button class="module-button" type="button" data-builder="${module.id}">
        <img src="../icons/${module.icon}.svg" alt=""><span><strong>${module.name}</strong>
        <small>${module.category} · ${module.description}</small></span>
      </button>`).join('');
  },
  optionField(tool, option) {
    const id = `${tool.id}-${option.id}`;
    if (option.type === 'checkbox') {
      return `<label class="option-field"><span><input id="${id}" type="checkbox" data-option="${option.id}" ${option.value ? 'checked' : ''}> ${option.label}</span></label>`;
    }
    if (option.type === 'text') {
      return `<label class="option-field">${option.label}<input id="${id}" type="text" value="${this.escape(option.value || '')}" data-option="${option.id}"></label>`;
    }
    return `<label class="option-field">${option.label}<input id="${id}" type="number" min="${option.min || 0.125}" step="${option.step || 0.125}" value="${option.value}" data-option="${option.id}"><small>${option.unit || ''}</small></label>`;
  },
  openBuilder(builder) {
    document.querySelector('.intro').hidden = true;
    document.getElementById('modules').closest('.card').hidden = true;
    const workspace = document.getElementById('workspace');
    workspace.hidden = false;
    document.getElementById('builder-division').textContent = builder.divisions.length ?
      `CSI Divisions ${builder.divisions.join(', ')}` : builder.category;
    document.getElementById('builder-name').textContent = builder.name;
    document.getElementById('tools').innerHTML = builder.tools.length ? builder.tools.map(tool => `
      <div class="tool-options" data-tool-options="${tool.id}">
        <div><strong>${tool.name}</strong><small>${tool.description}</small></div>
        ${(tool.options || []).map(option => this.optionField(tool, option)).join('')}
        <button class="tool-button" type="button" data-builder="${builder.id}" data-tool="${tool.id}"><strong>Place</strong></button>
      </div>`).join('') : '<p class="empty-state">This builder is registered. Modeling tools are scheduled for the next milestone.</p>';
  },
  showError(message) {
    const toast = document.getElementById('toast');
    toast.textContent = message;
    toast.hidden = false;
  },
  updateResult(result) {
    const button = document.getElementById('update-button');
    const status = document.getElementById('update-status');
    button.disabled = false;
    if (result.status === 'available') {
      status.textContent = `ForgeBuild ${result.version} is available.`;
      button.textContent = `Install v${result.version}`;
      button.dataset.action = 'install';
    } else if (result.status === 'current') {
      status.textContent = `ForgeBuild ${result.version} is up to date.`;
      button.textContent = 'Check Again';
      delete button.dataset.action;
    } else {
      status.textContent = result.message || 'Unable to check for updates.';
      button.textContent = 'Try Again';
      delete button.dataset.action;
    }
  },
  updateInstalling() {
    const button = document.getElementById('update-button');
    button.disabled = true;
    button.textContent = 'Installing…';
    document.getElementById('update-status').textContent = 'Downloading and replacing ForgeBuild…';
  },
  installResult(result) {
    const button = document.getElementById('update-button');
    const status = document.getElementById('update-status');
    status.textContent = result.message;
    button.disabled = result.status === 'installed';
    button.textContent = result.status === 'installed' ? (result.reloaded ? 'Updated & Reloaded' : 'Update Installed') : 'Try Again';
    if (result.status !== 'installed') delete button.dataset.action;
  },
  reportResult(report) {
    const quantityLines = (report.takeoff || []).reduce((sum, row) => sum + Object.keys(row.quantities || {}).length, 0);
    const scheduleRows = Object.values(report.schedules || {}).reduce((sum, rows) => sum + rows.length, 0);
    const warnings = (report.validations || []).length + (report.missing_information || []).length;
    document.getElementById('report-summary').innerHTML = `
      <div class="metric-grid"><div><strong>${report.object_count}</strong><small>assemblies</small></div>
      <div><strong>${quantityLines}</strong><small>quantity lines</small></div>
      <div><strong>${scheduleRows}</strong><small>schedule rows</small></div>
      <div><strong>${warnings}</strong><small>validation items</small></div>
      <div><strong>${(report.clashes || []).length}</strong><small>possible clashes</small></div>
      <div><strong>${(report.materials || []).length}</strong><small>material groups</small></div></div>`;
  },
  exportResult(path) { this.showError(`Commercial delivery package exported to ${path}`); },
  renderDrawings(drawings) {
    const select = document.getElementById('drawing-list');
    select.innerHTML = '<option value="">Registered drawings</option>' + drawings.map(drawing =>
      `<option value="${this.escape(drawing.id)}">${this.escape(drawing.sheet || drawing.filename)} · ${this.escape(drawing.revision || 'original')}</option>`).join('');
  },
  drawingImported(drawing) {
    const select = document.getElementById('drawing-list');
    select.insertAdjacentHTML('beforeend', `<option selected value="${this.escape(drawing.id)}">${this.escape(drawing.sheet || drawing.filename)} · ${this.escape(drawing.revision || 'original')}</option>`);
    this.showError(`Imported ${drawing.filename}. Calibrate it against a known dimension before tracing.`);
  },
  recognitionResult(result) {
    this.recognition = result;
    const items = [
      ['Dimensions', result.dimensions], ['Elevations', result.elevations], ['Rooms', result.rooms],
      ['Wall types', result.wall_types], ['Details', result.details], ['Assembly tags', result.assembly_tags],
      ['Suggestions requiring confirmation', result.suggestions]
    ];
    document.getElementById('recognition-summary').innerHTML = items.map(([label, values]) =>
      `<div class="recognition-row"><strong>${label}</strong><span>${(values || []).length}</span></div>`).join('');
  },
  comparisonResult(result) {
    document.getElementById('recognition-summary').innerHTML += `<div class="comparison"><strong>Model comparison</strong><p>${result.matched_count} matched · ${result.unresolved_count} drawing-only · ${(result.model_only || []).length} model-only</p></div>`;
  }
};

document.addEventListener('DOMContentLoaded', () => {
  document.getElementById('modules').addEventListener('click', event => {
    const button = event.target.closest('[data-builder]');
    if (button) window.sketchup.open_builder(button.dataset.builder);
  });
  document.getElementById('tools').addEventListener('click', event => {
    const button = event.target.closest('[data-tool]');
    if (!button) return;
    const container = button.closest('[data-tool-options]');
    const options = {};
    container.querySelectorAll('[data-option]').forEach(input => {
      options[input.dataset.option] = input.type === 'checkbox' ? input.checked : input.value;
    });
    window.sketchup.activate_tool(button.dataset.builder, button.dataset.tool, options);
  });
  document.getElementById('tool-search').addEventListener('input', event => {
    const query = event.target.value.trim().toLowerCase();
    document.querySelectorAll('[data-tool-options]').forEach(card => {
      card.hidden = query && !card.textContent.toLowerCase().includes(query);
    });
  });
  document.getElementById('back-button').addEventListener('click', () => {
    document.querySelector('.intro').hidden = false;
    document.getElementById('modules').closest('.card').hidden = false;
    document.getElementById('workspace').hidden = true;
  });
  document.getElementById('update-button').addEventListener('click', event => {
    if (event.currentTarget.dataset.action === 'install') {
      window.sketchup.install_update();
      return;
    }
    event.currentTarget.disabled = true;
    event.currentTarget.textContent = 'Checking…';
    document.getElementById('update-status').textContent = 'Checking GitHub Releases…';
    window.sketchup.check_for_updates();
  });
  document.getElementById('property-form').addEventListener('submit', event => {
    event.preventDefault();
    const changes = { parameters: {} };
    event.currentTarget.querySelectorAll('[data-property]').forEach(input => { changes[input.dataset.property] = input.value; });
    event.currentTarget.querySelectorAll('[data-parameter]').forEach(input => { changes.parameters[input.dataset.parameter] = input.value; });
    window.sketchup.save_assembly(changes);
  });
  document.getElementById('property-form').addEventListener('click', event => {
    const display = event.target.closest('[data-display]');
    if (display) window.sketchup.set_display_mode(display.dataset.display);
    const command = event.target.closest('[data-command]');
    if (command) window.sketchup[`${command.dataset.command}_assembly`]();
  });
  document.getElementById('save-preset').addEventListener('click', () => {
    const parameters = {};
    document.querySelectorAll('[data-parameter]').forEach(input => { parameters[input.dataset.parameter] = input.value; });
    window.sketchup.save_preset(document.getElementById('preset-name').value, parameters, document.getElementById('preset-default').checked);
  });
  document.getElementById('apply-preset').addEventListener('click', () => {
    const name = document.getElementById('preset-list').value;
    if (name) window.sketchup.apply_preset(name);
  });
  const reportOptions = () => ({ waste_factors: { default: Number(document.getElementById('waste-factor').value || 0) } });
  document.getElementById('refresh-reports').addEventListener('click', () => window.sketchup.refresh_reports(reportOptions()));
  document.getElementById('export-reports').addEventListener('click', () => window.sketchup.export_reports(reportOptions()));
  document.getElementById('import-drawing').addEventListener('click', () => window.sketchup.import_drawing({
    discipline: document.getElementById('drawing-discipline').value,
    sheet: document.getElementById('drawing-sheet').value,
    revision: document.getElementById('drawing-revision').value,
    page: Number(document.getElementById('drawing-page').value || 1)
  }));
  document.getElementById('calibrate-drawing').addEventListener('click', () => {
    const id = document.getElementById('drawing-list').value;
    if (id) window.sketchup.calibrate_drawing(id);
  });
  document.getElementById('trace-buttons').addEventListener('click', event => {
    const button = event.target.closest('[data-trace]');
    if (button) window.sketchup.trace_drawing(button.dataset.trace);
  });
  document.getElementById('recognize-annotations').addEventListener('click', () => window.sketchup.recognize_annotations(document.getElementById('annotation-text').value));
  document.getElementById('compare-drawing').addEventListener('click', () => window.sketchup.compare_drawing());
  if (window.sketchup && window.sketchup.ready) window.sketchup.ready();
});
