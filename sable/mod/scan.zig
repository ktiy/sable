pub fn run(m: *sbl.Machine, f: usize) void {
    const x = m.pop();
    if (x.atom()) return m.push(x);

    const arr = x.into(.array);
    defer arr.release(m.gpa);

    // TODO
    std.debug.assert(arr.length() >= 0);

    const res = sbl.Array.init(m.gpa, arr.shape(), .any) catch return m.throw(.oom);
    var ok = false;
    defer if (!ok) res.release(m.gpa);

    var xs = res.any_slice();
    const zero = arr.get(0);
    zero.retain();
    m.push(zero);
    xs[0] = zero;

    for (xs[1..], 1..) |*o, i| {
        const elem = arr.get(i);
        elem.retain();
        m.push(elem);
        if (!m.call(f)) return;

        const acc = m.top().*;
        acc.retain();
        o.* = acc;
    }

    m.pop().release(m.gpa);

    const ret = res.downcast(m.gpa) catch return m.throw(.oom);
    ok = true;

    m.push(.array(ret));
}

const std = @import("std");
const sbl = @import("sbl");
