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
        <small>CSI Division ${module.division} · ${module.description}</small>
      </button>`).join('');
  },
  openBuilder(builder) {
    document.querySelector('.intro').hidden = true;
    document.getElementById('modules').closest('.card').hidden = true;
    const workspace = document.getElementById('workspace');
    workspace.hidden = false;
    document.getElementById('builder-division').textContent = `CSI Division ${builder.division}`;
    document.getElementById('builder-name').textContent = builder.name;
    document.getElementById('tools').innerHTML = builder.tools.map(tool => `
      <div class="tool-options">
        <label>${tool.name}<input type="number" min="0.125" step="0.125" value="${tool.id === 'equipment_pad' ? 4 : 6}" data-thickness="${tool.id}"><small>${tool.description} Thickness (inches)</small></label>
        <button class="tool-button" type="button" data-builder="${builder.id}" data-tool="${tool.id}"><strong>Place</strong></button>
      </div>`).join('');
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
      button.textContent = `Download v${result.version}`;
      button.dataset.action = 'download';
    } else if (result.status === 'current') {
      status.textContent = `ForgeBuild ${result.version} is up to date.`;
      button.textContent = 'Check Again';
      delete button.dataset.action;
    } else {
      status.textContent = result.message || 'Unable to check for updates.';
      button.textContent = 'Try Again';
      delete button.dataset.action;
    }
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
    const input = document.querySelector(`[data-thickness="${button.dataset.tool}"]`);
    window.sketchup.activate_tool(button.dataset.builder, button.dataset.tool, { thickness: input.value });
  });
  document.getElementById('back-button').addEventListener('click', () => {
    document.querySelector('.intro').hidden = false;
    document.getElementById('modules').closest('.card').hidden = false;
    document.getElementById('workspace').hidden = true;
  });
  document.getElementById('update-button').addEventListener('click', (event) => {
    if (event.currentTarget.dataset.action === 'download') {
      window.sketchup.download_update();
      return;
    }
    event.currentTarget.disabled = true;
    event.currentTarget.textContent = 'Checking…';
    document.getElementById('update-status').textContent = 'Checking GitHub Releases…';
    window.sketchup.check_for_updates();
  });
  if (window.sketchup && window.sketchup.ready) window.sketchup.ready();
});
