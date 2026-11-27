const $ = id => document.getElementById(id);

const MAX_INTERPRETER_STEPS = 4294967295;
const MAX_TIME_MS = 10000;

const source = $("src");
const result = $("result");
const run_button = $("run");
const status = $("status");

function insert(g) {
  source.setRangeText(g, source.selectionStart, source.selectionEnd, 'end');
  source.dispatchEvent(new Event('input', { bubbles: true }));
}

let glyphs = Array.from("∅.,~⫦⊪+-×÷*|↧↥¬=≠>≥<≤□↓↑Ρ/⊂⌢ιρ⧻△▽ˊ¨:ˋ‿⋄←%");
let keys   = Array.from("n   oO  +-  mM  = > <pdtS ejislrR12 3_;[ ");

const keymap = Object.fromEntries(
  keys
    .map((k,i) => k==' '?null:k=='_'?' ':k)
    .map((k,i) => [k, glyphs[i]])
    .filter(([, g]) => g)
);

const prefix = '\\';
let pending = false;
source.addEventListener("keydown", ev => {
  if (pending) {
    pending = false;
    source.classList.remove("pending");
    if (ev.key === "Escape") {
      ev.preventDefault();
      return;
    }
    if (ev.key === prefix) {
      ev.preventDefault();
      insert(prefix);
      return;
    }

    const g = keymap[ev.key];
    if (g) {
       ev.preventDefault();
       insert(g);
       return;
    }
    insert(prefix);
    return;
  }

  if (ev.key == prefix
      && !ev.ctrlKey
      && !ev.metaKey
      && !ev.altKey) {
      ev.preventDefault();
    pending = true;
    source.classList.add("pending");
  }

  if (ev.key === "Enter" && ev.ctrlKey) {
    ev.preventDefault();
    run();
  }
});
const container = $("glyphs");

glyphs.forEach(g => {
  const a = document.createElement('a');
  a.textContent = g;
  a.href = '#';
  a.title = g;

  a.onmousedown = ev => ev.preventDefault();

  a.onclick = ev => {
    ev.preventDefault();
    insert(g);
    source.focus();
  };

  container.append(a);
});

let worker = new Worker("worker.js");

function restart_worker() {
  worker.terminate();
  worker = new Worker("worker.js");
}

function run_program(text) {
  return new Promise((resolve) => {
    const timer = setTimeout(() => {
      restart_worker();
      resolve({ ok: false, text: "timed out" });
    }, MAX_TIME_MS)

    worker.onmessage = ({ data }) => {
      clearTimeout(timer);
      if (data.crashed) restart_worker();
      resolve(data);
    };

    worker.postMessage({ source: text, max_steps: MAX_INTERPRETER_STEPS });
  });
}

async function run() {
  if (run_button.disabled) return;

  run_button.disabled = true;
  status.textContent = "Running";

  const { ok, text } = await run_program(source.value);

  result.textContent = text;
  result.className = ok ? "" : "err";
  status.textContent = ok ? "OK" : "Error";

  run_button.disabled = false;
}

run_button.onclick = run;
run_button.disabled = false;
status.textContent = "Ready";
