pub fn run(m: *sbl.Machine, f: usize) void {
    const x = m.pop();
    if (x.atom()) {
        m.push(x);
        _ = m.call(f);
        return;
    }

    const arr = x.into(.array);
    defer arr.release(m.gpa);

    const x0 = arr.get(0);
    const p = m.dat_p;
    x0.retain();
    m.push(x0);
    if (!m.call(f)) return;
    const p2 = m.dat_p;

    // nilad
    if (p == p2) {
        for (1..arr.length()) |i| {
            const elem = arr.get(i);
            elem.retain();
            m.push(elem);
            if (!m.call(f)) return;
        }
        return;
    }

    // monad
    const y0 = m.pop();
    const res = sbl.Array.init(m.gpa, arr.shape(), .any) catch {
        y0.release(m.gpa);
        return m.throw(.oom);
    };
    var ok = false;
    defer if (!ok) res.release(m.gpa);

    const xs = res.slice(.any);
    xs[0] = y0;

    for (xs[1..], 1..) |*o, i| {
        const elem = arr.get(i);
        elem.retain();
        m.push(elem);
        if (!m.call(f)) return;
        o.* = m.pop();
    }

    const ret = res.downcast(m.gpa) catch return m.throw(.oom);
    ok = true;
    m.push(.array(ret));
}

const sbl = @import("sbl");
const std = @import("std");
