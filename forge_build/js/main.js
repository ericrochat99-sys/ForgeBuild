window.ForgeBuild = {
  bootstrap(payload) {
    document.getElementById('version').textContent = `Version ${payload.version}`;
    if (payload.modules.length) {
      document.getElementById('modules').textContent = payload.modules.join(', ');
    }
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
