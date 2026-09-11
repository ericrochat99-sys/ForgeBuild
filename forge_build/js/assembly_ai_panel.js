(() => {
  const FEET_INCH_PATTERN = /(-?\d+(?:\.\d+)?)\s*(?:'|ft|feet)(?:\s*-?\s*(\d+(?:\.\d+)?)\s*(?:\"|in|inch|inches)?)?/i;
  const NUMBER_PATTERN = /(-?\d+(?:\.\d+)?)/;

  function esc(value) {
    const div = document.createElement('div');
    div.textContent = value == null ? '' : String(value);
    return div.innerHTML;
  }

  function parseLength(value) {
    if (!value) return null;
    const text = String(value).trim();
    const feet = text.match(FEET_INCH_PATTERN);
    if (feet) return (Number(feet[1]) * 12) + Number(feet[2] || 0);
    const inches = text.match(/(-?\d+(?:\.\d+)?)\s*(?:\"|in|inch|inches)/i);
    if (inches) return Number(inches[1]);
    const number = text.match(NUMBER_PATTERN);
    return number ? Number(number[1]) : null;
  }

  function formatInches(value) {
    const n = Number(value);
    if (!Number.isFinite(n)) return value;
    const feet = Math.floor(Math.abs(n) / 12);
    const inches = Math.round((Math.abs(n) - (feet * 12)) * 100) / 100;
    const sign = n < 0 ? '-' : '';
    if (feet && inches) return `${sign}${feet}'-${inches}"`;
    if (feet) return `${sign}${feet}'-0"`;
    return `${sign}${inches}"`;
  }

  function currentParameters() {
    const form = document.getElementById('property-form');
    const parameters = {};
    if (!form) return parameters;
    form.querySelectorAll('[data-parameter]').forEach(input => { parameters[input.dataset.parameter] = input.value; });
    return parameters;
  }

  function setParameterInput(name, value) {
    const input = document.querySelector(`[data-parameter="${name}"]`);
    if (input) input.value = value;
  }

  function extractChanges(text, selection) {
    const lower = text.toLowerCase();
    const changes = {};
    const warnings = [];
    const actions = [];

    const height = lower.match(/(?:height|high|tall|wall height)\D{0,12}(-?\d+(?:\.\d+)?\s*(?:'|ft|feet)?\s*-?\s*\d*(?:\"|in|inch|inches)?)/i)
      || lower.match(/(-?\d+(?:\.\d+)?\s*(?:'|ft|feet))\s*(?:high|tall)/i);
    if (height) changes.height = String(parseLength(height[1]));

    const thickness = lower.match(/(?:thickness|thick|wall type|cmu|stud)\D{0,18}(\d+(?:\.\d+)?\s*(?:\"|in|inch|inches)?)/i)
      || lower.match(/(\d+(?:\.\d+)?\s*(?:\"|in|inch|inches))\s*(?:thick|cmu|stud)/i);
    if (thickness) changes.thickness = String(parseLength(thickness[1]));

    const width = lower.match(/(?:width|wide)\D{0,12}(-?\d+(?:\.\d+)?\s*(?:'|ft|feet|\"|in|inch|inches)?)/i);
    if (width) changes.width = String(parseLength(width[1]));

    const length = lower.match(/(?:length|long)\D{0,12}(-?\d+(?:\.\d+)?\s*(?:'|ft|feet|\"|in|inch|inches)?)/i);
    if (length) changes.length = String(parseLength(length[1]));

    const elevation = lower.match(/(?:elevation|level)\D{0,12}(-?\d+(?:\.\d+)?\s*(?:'|ft|feet|\"|in|inch|inches)?)/i);
    if (elevation) changes.elevation = String(parseLength(elevation[1]));

    const fire = lower.match(/(\d+)\s*(?:hr|hour|hours)\s*(?:fire|rated|rating)?/i);
    if (fire) changes.fire_rating = `${fire[1]} hour`;

    const stc = lower.match(/stc\D{0,8}(\d+)/i);
    if (stc) changes.stc = stc[1];

    const rValue = lower.match(/r[- ]?value\D{0,8}(\d+)/i) || lower.match(/\br[- ]?(\d{1,3})\b/i);
    if (rValue) changes.r_value = rValue[1];

    const pitch = lower.match(/(?:pitch|slope)\D{0,10}(\d+(?:\.\d+)?)/i);
    if (pitch) changes.pitch = pitch[1];

    if (/push|pull|stretch|extend|resize|longer|shorter|taller|higher/i.test(text)) {
      actions.push('Use Push/Pull Assembly after applying parameter changes to preview the geometry edit.');
    }
    if (/door|window|opening|louver|storefront|borrowed lite|overhead/i.test(text)) {
      warnings.push('Openings should be created with the wall opening tools instead of only editing wall parameters.');
      actions.push('Use the Opening trace or Wall Builder opening family, then regenerate the wall.');
    }
    if (/fire|rated|stc|acoustic|smoke|security/i.test(text)) {
      actions.push('Verify rating metadata against the assembly type before exporting schedules.');
    }
    if (/apply to similar|all similar|same type/i.test(text)) {
      warnings.push('Apply-to-similar is planned for Phase 4; this panel currently applies changes to the selected assembly only.');
    }

    Object.keys(changes).forEach(key => {
      if (changes[key] == null || changes[key] === 'NaN') delete changes[key];
    });

    return {
      object: selection ? `${selection.builder || 'assembly'} / ${selection.object_type || 'selected object'}` : 'No selection',
      changes,
      actions,
      warnings,
      prompt: buildPrompt(text, selection, changes)
    };
  }

  function buildPrompt(text, selection, changes) {
    const parameters = currentParameters();
    return [
      'Review this ForgeBuild assembly edit request and return JSON with safe parameter changes, warnings, and follow-up questions.',
      `Selected assembly: ${selection ? `${selection.builder || ''} ${selection.object_type || ''}`.trim() : 'none'}`,
      `Current parameters: ${JSON.stringify(parameters)}`,
      `Requested edit: ${text}`,
      `Heuristic changes: ${JSON.stringify(changes)}`,
      'Do not create openings by changing wall dimensions only; use opening tools when required.'
    ].join('\n');
  }

  function renderResult(result) {
    const output = document.getElementById('assembly-ai-result');
    if (!output) return;
    const changeRows = Object.entries(result.changes || {}).map(([key, value]) => `<li><b>${esc(key.replaceAll('_', ' '))}</b>: ${esc(formatInches(value))}</li>`).join('');
    const actionRows = (result.actions || []).map(item => `<li>${esc(item)}</li>`).join('');
    const warningRows = (result.warnings || []).map(item => `<li>${esc(item)}</li>`).join('');
    output.innerHTML = `
      <div class="assembly-ai-result-card">
        <b>Suggested edit</b>
        ${changeRows ? `<ul>${changeRows}</ul>` : '<p>No direct parameter changes detected. Use the prompt below or enter clearer dimensions.</p>'}
        ${actionRows ? `<b>Recommended workflow</b><ul>${actionRows}</ul>` : ''}
        ${warningRows ? `<b>Warnings</b><ul class="assembly-ai-warnings">${warningRows}</ul>` : ''}
        <details><summary>AI handoff prompt</summary><textarea readonly rows="7">${esc(result.prompt)}</textarea></details>
      </div>`;
    output.dataset.changes = JSON.stringify(result.changes || {});
  }

  function injectPanel() {
    const form = document.getElementById('property-form');
    if (!form || form.hidden || form.querySelector('[data-assembly-ai-panel]')) return;
    const panel = document.createElement('section');
    panel.className = 'assembly-ai-panel';
    panel.dataset.assemblyAiPanel = '1';
    panel.innerHTML = `
      <div class="assembly-ai-head">
        <div><label>PHASE 4 + PHASE 9</label><h3>AI Edit Assistant</h3></div>
        <span>Selected assembly</span>
      </div>
      <textarea id="assembly-ai-request" rows="4" placeholder="Example: Make this wall 12 ft high, 8 inch CMU, 2 hour rated, then remind me to add door openings."></textarea>
      <div class="assembly-ai-actions">
        <button type="button" class="primary" id="assembly-ai-analyze">Analyze Edit</button>
        <button type="button" id="assembly-ai-apply">Apply Parameters</button>
        <button type="button" data-ai-command="push_pull_assembly">Push/Pull</button>
        <button type="button" data-ai-command="regenerate_assembly">Regenerate</button>
      </div>
      <div id="assembly-ai-result" class="assembly-ai-result"></div>`;
    form.appendChild(panel);
  }

  function install() {
    if (!window.ForgeBuild || window.ForgeBuild.__assemblyAiInstalled) return;
    window.ForgeBuild.__assemblyAiInstalled = true;
    const original = window.ForgeBuild.selectionChanged;
    window.ForgeBuild.selectionChanged = function selectionChangedWithAi(selection) {
      original.call(this, selection);
      setTimeout(injectPanel, 0);
    };

    document.addEventListener('click', event => {
      const analyze = event.target.closest('#assembly-ai-analyze');
      if (analyze) {
        const text = document.getElementById('assembly-ai-request')?.value || '';
        const result = extractChanges(text, window.ForgeBuild.state.selection);
        renderResult(result);
        return;
      }
      const apply = event.target.closest('#assembly-ai-apply');
      if (apply) {
        const result = document.getElementById('assembly-ai-result');
        const changes = result?.dataset.changes ? JSON.parse(result.dataset.changes) : {};
        Object.entries(changes).forEach(([key, value]) => setParameterInput(key, value));
        if (Object.keys(changes).length) window.sketchup.save_assembly({ parameters: changes });
        return;
      }
      const command = event.target.closest('[data-ai-command]');
      if (command && window.sketchup?.[command.dataset.aiCommand]) window.sketchup[command.dataset.aiCommand]();
    });
  }

  install();
})();
