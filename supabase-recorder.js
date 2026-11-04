// Supabase recorder client for the ML course shell — spike version.
// Browser-safe: uses only the Supabase anon key (designed for browser
// use) and the student name. Never put the service_role key, a teacher
// token, or any password in this file or in the shell page.
// Offline queue: a batch that fails to send stays queued in localStorage
// and is retried on the next flush; it is never lost and never sent
// twice as a new batch, because batch_id is unique in the database
// (a 409 duplicate is treated as already-sent, not as an error).
const ALLOWED_TABLES = ['day_progress', 'events', 'lab_notebooks', 'mistakes', 'teach_backs', 'tour_progress'];
const QUEUE_KEY = 'ml-supabase-queue';

function countRows(tables) {
  let n = 0;
  for (const t of ALLOWED_TABLES) if (Array.isArray(tables[t])) n += tables[t].length;
  return n;
}

function validate(meta, tables) {
  if (!meta || !meta.batchId) return 'missing_batch_id';
  if (!tables || typeof tables !== 'object') return 'missing_tables';
  for (const t of Object.keys(tables)) {
    if (!ALLOWED_TABLES.includes(t) || !Array.isArray(tables[t])) return 'bad_table:' + t;
  }
  return null;
}

function createRecorder(opts) {
  const supabaseUrl = (opts.supabaseUrl || '').replace(/\/$/, '');
  const anonKey = opts.anonKey || '';
  const studentName = opts.studentName || '';
  const fetchImpl = opts.fetchImpl || (typeof fetch !== 'undefined' ? fetch : null);
  const storage = opts.storage || (typeof localStorage !== 'undefined' ? localStorage : null);
  let memQueue = [];
  function loadQueue() {
    try {
      if (storage) return JSON.parse(storage.getItem(QUEUE_KEY) || '[]');
    } catch (_) {}
    return memQueue;
  }
  function saveQueue(q) {
    memQueue = q;
    try { if (storage) storage.setItem(QUEUE_KEY, JSON.stringify(q)); } catch (_) {}
  }
  function toRow(meta, tables) {
    return {
      student_name: studentName,
      batch_id: meta.batchId,
      export_id: meta.exportId || meta.batchId,
      shell_version: meta.shellVersion || '',
      exported_at: meta.exportedAt || new Date().toISOString(),
      tables: tables,
      row_count: countRows(tables),
      source: 'shell',
    };
  }
  async function sendRow(row) {
    if (!fetchImpl) return { ok: false, error: 'no_fetch' };
    const res = await fetchImpl(supabaseUrl + '/rest/v1/shell_batches', {
      method: 'POST',
      headers: {
        'apikey': anonKey,
        'Authorization': 'Bearer ' + anonKey,
        'Content-Type': 'application/json',
        'Prefer': 'return=minimal',
      },
      body: JSON.stringify([row]),
    });
    if (res.status === 409) return { ok: true, deduped: true };
    if (!res.ok) return { ok: false, error: 'http_' + res.status };
    return { ok: true, deduped: false };
  }
  return {
    queueBatch(meta, tables) {
      const err = validate(meta, tables);
      if (err) return { ok: false, error: err };
      const q = loadQueue();
      if (q.some((r) => r.batch_id === meta.batchId)) return { ok: true, deduped: true, queued: q.length };
      q.push(toRow(meta, tables));
      saveQueue(q);
      return { ok: true, queued: q.length };
    },
    getQueue() { return loadQueue(); },
    async flush() {
      const q = loadQueue();
      let sent = 0, deduped = 0;
      const remaining = [];
      for (const row of q) {
        try {
          const r = await sendRow(row);
          if (r.ok) { if (r.deduped) deduped += 1; else sent += 1; }
          else remaining.push(row);
        } catch (_) { remaining.push(row); }
      }
      saveQueue(remaining);
      return { ok: true, sent, deduped, queued: remaining.length };
    },
  };
}

if (typeof module !== 'undefined' && module.exports) {
  module.exports = { createRecorder, ALLOWED_TABLES, countRows, validate };
}
