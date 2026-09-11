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

  function formatValue(key, value) {
    if (['fire_rating', 'ul_design', 'ga_design', 'smoke_rating', 'security_class', 'system', 'material', 'finish', 'framing', 'insulation', 'sheathing', 'notes'].includes(key)) return value;
    const n = Number(value);
    if (!Number.isFinite(n)) return value;
    if (['pitch', 'slope', 'r_value', 'stc'].includes(key)) return String(n);
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

  function fallbackExtractChanges(text, selection) {
    const lower = text.toLowerCase();
    const parameters = {};
    const attributes = {};
    const warnings = [];
    const actions = [];
    const questions = [];

    const height = lower.match(/(?:height|high|tall|wall height)\D{0,12}(-?\d+(?:\.\d+)?\s*(?:'|ft|feet)?\s*-?\s*\d*(?:\"|in|inch|inches)?)/i)
      || lower.match(/(-?\d+(?:\.\d+)?\s*(?:'|ft|feet))\s*(?:high|tall)/i);
    if (height) parameters.height = String(parseLength(height[1]));

    const thickness = lower.match(/(?:thickness|thick|wall type|cmu|stud)\D{0,18}(\d+(?:\.\d+)?\s*(?:\"|in|inch|inches)?)/i)
      || lower.match(/(\d+(?:\.\d+)?\s*(?:\"|in|inch|inches))\s*(?:thick|cmu|stud)/i);
    if (thickness) parameters.thickness = String(parseLength(thickness[1]));

    const width = lower.match(/(?:width|wide)\D{0,12}(-?\d+(?:\.\d+)?\s*(?:'|ft|feet|\"|in|inch|inches)?)/i);
    if (width) parameters.width = String(parseLength(width[1]));

    const length = lower.match(/(?:length|long)\D{0,12}(-?\d+(?:\.\d+)?\s*(?:'|ft|feet|\"|in|inch|inches)?)/i);
    if (length) parameters.length = String(parseLength(length[1]));

    const elevation = lower.match(/(?:elevation|level)\D{0,12}(-?\d+(?:\.\d+)?\s*(?:'|ft|feet|\"|in|inch|inches)?)/i);
    if (elevation) parameters.elevation = String(parseLength(elevation[1]));

    const fire = lower.match(/(\d+)\s*(?:hr|hour|hours)\s*(?:fire|rated|rating)?/i);
    if (fire) attributes.fire_rating = `${fire[1]} hour`;

    const stc = lower.match(/stc\D{0,8}(\d+)/i);
    if (stc) parameters.stc = stc[1];

    const rValue = lower.match(/r[- ]?value\D{0,8}(\d+)/i) || lower.match(/\br[- ]?(\d{1,3})\b/i);
    if (rValue) parameters.r_value = rValue[1];

    const pitch = lower.match(/(?:pitch|slope)\D{0,10}(\d+(?:\.\d+)?)/i);
    if (pitch) parameters.pitch = pitch[1];

    if (/push|pull|stretch|extend|resize|longer|shorter|taller|higher/i.test(text)) {
      actions.push('Use Push/Pull Assembly after applying parameter changes to preview the geometry edit.');
      questions.push('Which side should remain fixed during push/pull?');
    }
    if (/door|window|opening|louver|storefront|borrowed lite|overhead/i.test(text)) {
      warnings.push('Openings should be created with the wall opening tools instead of only editing wall parameters.');
      actions.push('Use the Opening trace or Wall Builder opening family, then regenerate the wall.');
    }
    if (/fire|rated|stc|acoustic|smoke|security/i.test(text)) {
      actions.push('Verify rating metadata against the assembly type before exporting schedules.');
    }
    if (/apply to similar|all similar|same type/i.test(text)) {
      warnings.push('Apply-to-similar will update matching assemblies with the same builder and object type.');
    }

    Object.keys(parameters).forEach(key => {
      if (parameters[key] == null || parameters[key] === 'NaN') delete parameters[key];
    });

    const changes = { parameters, attributes };
    return {
      object: selection ? `${selection.builder || 'assembly'} / ${selection.object_type || 'selected object'}` : 'No selection',
      changes,
      actions,
      warnings,
      questions,
      safety: warnings.length ? 'review_required' : 'ready',
      apply_to_similar: /apply to similar|all similar|same type/i.test(text),
      prompt: buildPrompt(text, selection, changes, warnings, questions)
    };
  }

  function buildPrompt(text, selection, changes, warnings = [], questions = []) {
    const parameters = currentParameters();
    return [
      'Review this ForgeBuild assembly edit request and return JSON with safe parameter changes, warnings, and follow-up questions.',
      `Selected assembly: ${selection ? `${selection.builder || ''} ${selection.object_type || ''}`.trim() : 'none'}`,
      `Current parameters: ${JSON.stringify(parameters)}`,
      `Requested edit: ${text}`,
      `Heuristic changes: ${JSON.stringify(changes)}`,
      `Warnings: ${JSON.stringify(warnings)}`,
      `Questions: ${JSON.stringify(questions)}`,
      'Do not create openings by changing wall dimensions only; use opening tools when required.'
    ].join('\n');
  }

  function normalizeResult(result) {
    const changes = result.changes || {};
    return {
      ...result,
      changes: {
        parameters: changes.parameters || {},
        attributes: changes.attributes || {}
      },
      warnings: result.warnings || [],
      actions: result.actions || [],
      questions: result.questions || []
    };
  }

  function renderResult(rawResult) {
    const result = normalizeResult(rawResult);
    const output = document.getElementById('assembly-ai-result');
    if (!output) return;
    const parameterRows = Object.entries(result.changes.parameters || {}).map(([key, value]) => `<li><b>${esc(key.replaceAll('_', ' '))}</b>: ${esc(formatValue(key, value))}</li>`).join('');
    const attributeRows = Object.entries(result.changes.attributes || {}).map(([key, value]) => `<li><b>${esc(key.replaceAll('_', ' '))}</b>: ${esc(formatValue(key, value))}</li>`).join('');
    const actionRows = (result.actions || []).map(item => `<li>${esc(item)}</li>`).join('');
    const warningRows = (result.warnings || []).map(item => `<li>${esc(item)}</li>`).join('');
    const questionRows = (result.questions || []).map(item => `<li>${esc(item)}</li>`).join('');
    const status = result.safety === 'review_required' ? 'Review required' : 'Ready to apply';
    output.innerHTML = `
      <div class="assembly-ai-result-card">
        <div class="assembly-ai-status ${result.safety === 'review_required' ? 'warn' : 'ready'}">${esc(status)}</div>
        <b>Suggested parameter changes</b>
        ${parameterRows ? `<ul>${parameterRows}</ul>` : '<p>No direct parameter changes detected.</p>'}
        ${attributeRows ? `<b>Metadata changes</b><ul>${attributeRows}</ul>` : ''}
        ${actionRows ? `<b>Recommended workflow</b><ul>${actionRows}</ul>` : ''}
        ${warningRows ? `<b>Warnings</b><ul class="assembly-ai-warnings">${warningRows}</ul>` : ''}
        ${questionRows ? `<b>Questions before final modeling</b><ul>${questionRows}</ul>` : ''}
        <label class="assembly-ai-similar"><input type="checkbox" id="assembly-ai-similar" ${result.apply_to_similar ? 'checked' : ''}> Apply to all similar assemblies</label>
        <details><summary>AI handoff prompt</summary><textarea readonly rows="9">${esc(result.prompt)}</textarea></details>
      </div>`;
    output.dataset.result = JSON.stringify(result);
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
      <textarea id="assembly-ai-request" rows="4" placeholder="Example: Make this wall 12 ft high, 8 inch CMU, 2 hour rated, and apply it to all similar walls."></textarea>
      <div class="assembly-ai-actions">
        <button type="button" class="primary" id="assembly-ai-analyze">Analyze Edit</button>
        <button type="button" id="assembly-ai-apply">Apply Safe Edit</button>
        <button type="button" data-ai-command="push_pull_assembly">Push/Pull</button>
        <button type="button" data-ai-command="regenerate_assembly">Regenerate</button>
      </div>
      <div class="assembly-ai-workflow">
        <span>1 Analyze</span><span>2 Review warnings</span><span>3 Apply</span><span>4 Regenerate/report</span>
      </div>
      <div id="assembly-ai-result" class="assembly-ai-result"></div>`;
    form.appendChild(panel);
  }

  function requestBackendAnalysis(text) {
    window.sketchup.analyze_assembly_edit({ text, parameters: currentParameters() });
  }

  function install() {
    if (!window.ForgeBuild || window.ForgeBuild.__assemblyAiInstalled) return;
    window.ForgeBuild.__assemblyAiInstalled = true;
    window.ForgeBuild.assemblyEditAnalysis = renderResult;
    window.ForgeBuild.assemblyEditApplied = function assemblyEditApplied(result) {
      const count = result && result.applied_count ? result.applied_count : 1;
      window.ForgeBuild.showError(`Applied assisted edit to ${count} assembly${count === 1 ? '' : 'ies'}.`);
    };

    const original = window.ForgeBuild.selectionChanged;
    window.ForgeBuild.selectionChanged = function selectionChangedWithAi(selection) {
      original.call(this, selection);
      setTimeout(injectPanel, 0);
    };

    document.addEventListener('click', event => {
      const analyze = event.target.closest('#assembly-ai-analyze');
      if (analyze) {
        const text = document.getElementById('assembly-ai-request')?.value || '';
        if (window.sketchup?.analyze_assembly_edit) requestBackendAnalysis(text);
        else renderResult(fallbackExtractChanges(text, window.ForgeBuild.state.selection));
        return;
      }
      const apply = event.target.closest('#assembly-ai-apply');
      if (apply) {
        const resultEl = document.getElementById('assembly-ai-result');
        const result = resultEl?.dataset.result ? JSON.parse(resultEl.dataset.result) : null;
        if (!result) return;
        result.apply_to_similar = document.getElementById('assembly-ai-similar')?.checked || false;
        Object.entries(result.changes.parameters || {}).forEach(([key, value]) => setParameterInput(key, value));
        if (window.sketchup?.apply_assembly_edit) window.sketchup.apply_assembly_edit(result);
        else window.sketchup.save_assembly({ ...(result.changes.attributes || {}), parameters: result.changes.parameters || {} });
        return;
      }
      const command = event.target.closest('[data-ai-command]');
      if (command && window.sketchup?.[command.dataset.aiCommand]) window.sketchup[command.dataset.aiCommand]();
    });
  }

  install();
})();
