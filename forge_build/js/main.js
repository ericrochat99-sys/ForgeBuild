window.ForgeBuild = {
  bootstrap(payload) {
    document.getElementById('version').textContent = `Version ${payload.version}`;
    if (payload.modules.length) {
      document.getElementById('modules').textContent = payload.modules.join(', ');
    }
  }
};

document.addEventListener('DOMContentLoaded', () => {
  if (window.sketchup && window.sketchup.ready) window.sketchup.ready();
});
