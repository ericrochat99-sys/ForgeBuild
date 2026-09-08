window.ForgeBuild = {
  bootstrap(payload) {
    document.getElementById('version').textContent = `Version ${payload.version}`;
    this.renderModules(payload.modules);
  },
  renderModules(modules) {
    const container = document.getElementById('modules');
    if (!modules.length) return;
    container.classList.remove('empty');
    container.innerHTML = modules.map(module => `
      <button class="module-button" type="button" data-builder="${module.id}">
        <strong>${module.name}</strong>
        <small>${module.category} · ${module.description}</small>
      </button>`).join('');
  },
  optionField(tool, option) {
    const id = `${tool.id}-${option.id}`;
    if (option.type === 'checkbox') {
      return `<label class="option-field"><span><input id="${id}" type="checkbox" data-option="${option.id}" ${option.value ? 'checked' : ''}> ${option.label}</span></label>`;
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
  if (window.sketchup && window.sketchup.ready) window.sketchup.ready();
});
