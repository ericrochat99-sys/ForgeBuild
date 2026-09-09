window.ForgeBuild = {
  bootstrap(payload) {
    document.getElementById('version').textContent = `Version ${payload.version}`;
    this.renderModules(payload.modules);
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
    button.textContent = result.status === 'installed' ? 'Update Installed' : 'Try Again';
    if (result.status !== 'installed') delete button.dataset.action;
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
  if (window.sketchup && window.sketchup.ready) window.sketchup.ready();
});
