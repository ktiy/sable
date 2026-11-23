pub fn run(m: *sbl.Machine) void {
    run_e(m) catch |e| switch (e) {
        E.OutOfMemory => m.throw(.oom),
    };
}

const E = error{
    OutOfMemory,
};

// (a x -- a')
fn run_e(m: *sbl.Machine) E!void {
    const x = m.pop();
    const a = m.pop();

    defer x.release(m.gpa);
    defer a.release(m.gpa);

    if (a.empty()) return m.push(.none());
    if (a.atom() or x.atom()) return m.throw(.domain);

    const arr = a.into(.array);
    const xs = x.into(.array);

    if (arr.ra() != 1 or xs.ra() != 1) return m.throw(.rank);
    if (xs.shape()[0] != arr.shape()[0]) return m.throw(.domain);
    if (xs.ty() != .num) return m.throw(.type);

    const mask = xs.num_slice();

    var cnt: usize = 0;
    var prev: f64 = 0;
    for (mask) |v| {
        const n = @trunc(v);
        if (n < 0) return m.throw(.domain);
        if (n > prev) cnt += 1;
        prev = n;
    }

    var out: sbl.Array = try .init(m.gpa, &.{@intCast(cnt)}, .any);
    const out_any = out.any_slice();

    prev = 0;
    var p: usize = 0;
    var i: usize = 0;
    while (i < mask.len) {
        const n = @trunc(mask[i]);
        if (n == 0) {
            prev = 0;
            i += 1;
            continue;
        }

        const start = i;
        var cur = n;
        i += 1;
        while (i < mask.len) : (i += 1) {
            const w = @trunc(mask[i]);
            if (w == 0 or w > cur) {
                // a new partition begins
                break;
            }
            cur = w;
        }
        const len = i - start;

        var inner: sbl.Array = try .init(m.gpa, &.{@intCast(len)}, .any);
        for (inner.any_slice(), 0..) |*elem, j| {
            const w = arr.get(start + j);
            w.retain();
            elem.* = w;
        }

        out_any[p] = .array(try inner.downcast(m.gpa));
        p += 1;
        prev = cur;
    }

    m.push(.array(out));
}

const Dim = sbl.Array.Dim;
const sbl = @import("sbl");
const std = @import("std");
