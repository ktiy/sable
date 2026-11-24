pub fn run(m: *sbl.Machine, f: usize) void {
    const x = m.pop();
    if (x.atom()) return m.push(x);

    const arr = x.into(.array);
    defer arr.release(m.gpa);

    // TODO: maybe runtime error instead lol
    std.debug.assert(arr.length() >= 0);

    const zero = arr.get(0);
    zero.retain();
    m.push(zero);
    for (1..arr.length()) |i| {
        const elem = arr.get(i);
        m.push(elem);
        if (!m.call(f)) return;
    }
}

const std = @import("std");
const sbl = @import("sbl");
