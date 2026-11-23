pub fn run(m: *sbl.Machine) void {
    run_e(m) catch m.throw(.oom);
}

fn run_e(m: *sbl.Machine) !void {
    const x = m.pop();
    const a = m.top();

    defer x.release(m.gpa);

    if (a.is_array() and a.into(.array).ra() != 1)
        return m.throw(.rank);

    if (x.is_array() and x.into(.array).ra() != 1)
        return m.throw(.rank);

    const kind = result_kind(a.*, x);
    const la = length(a.*);
    const lx = length(x);
    const out: sbl.Array = try .init(m.gpa, &.{@intCast(la + lx)}, kind);
    fill(out, 0, a.*);
    fill(out, la, x);

    a.release(m.gpa);
    a.* = .array(out);
}

fn length(x: sbl.Cell) usize {
    if (x.empty()) return 0;
    if (x.atom()) return 1;
    return x.into(.array).length();
}

fn elem_kind(x: sbl.Cell) sbl.Array.Kind {
    return switch (x.k) {
        .num => .num,
        .byte => .byte,
        .char => .char,
        .none => .any,
        .array => x.into(.array).ty(),
    };
}

fn arr_kind(k: sbl.Array.Kind) sbl.Cell.Kind {
    return switch (k) {
        .num => .num,
        .byte => .byte,
        .char => .char,
        else => unreachable,
    };
}

fn result_kind(a: sbl.Cell, x: sbl.Cell) sbl.Array.Kind {
    if (length(a) == 0) return elem_kind(x);
    if (length(x) == 0) return elem_kind(a);

    const ka = elem_kind(a);
    const kx = elem_kind(x);
    return if (ka == kx) ka else .any;
}

fn fill(dst: sbl.Array, off: usize, src: sbl.Cell) void {
    if (src.empty()) return;

    if (src.atom()) {
        switch (dst.ty()) {
            .any => dst.slice(.any)[off] = src,
            inline else => |k| dst.slice(k)[off] = src.into(arr_kind(k)),
        }
        return;
    }

    const arr = src.into(.array);
    const n = arr.length();
    if (n == 0) return;

    switch (dst.ty()) {
        inline else => |k| @memcpy(dst.slice(k)[off..][0..n], arr.slice(k)),
        .any => for (dst.slice(.any)[off..][0..n], 0..) |*elem, i| {
            const w = arr.get(i);
            w.retain();
            elem.* = w;
        },
    }
}

const std = @import("std");
const sbl = @import("sbl");
