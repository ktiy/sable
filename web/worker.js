const loading = fetch("sbl.wasm")
      .then((response) => response.arrayBuffer())
      .then((bytes) => WebAssembly.instantiate(bytes, {}))
      .then(({ instance }) => instance.exports);

function evaluate(wasm, source, max_steps) {
    const bytes = new TextEncoder().encode(source);

    const ptr = wasm.alloc(bytes.length);
    new Uint8Array(wasm.memory.buffer, ptr, bytes.length).set(bytes);
    const ok = wasm.sbl_eval(ptr, bytes.length, max_steps);
    wasm.free(ptr, bytes.length);

    const res = new Uint8Array(wasm.memory.buffer, wasm.sbl_result_ptr(), wasm.sbl_result_len());
    return { ok: Boolean(ok), text: new TextDecoder().decode(res) }
}

onmessage = async ({ data }) => {
    try {
        const wasm = await loading;
        postMessage(evaluate(wasm, data.source, data.max_steps));
    } catch (err) {
        postMessage({ ok: false, text: "err: " + err.message, crashed: true });
    }
};
