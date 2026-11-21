const std = @import("std");
const sbl = @import("sbl");
const Dim = sbl.Array.Dim;
const E = error{
    OutOfMemory,
};

pub fn run(m: *sbl.Machine) void {
    run_e(m) catch |e| switch (e) {
        E.OutOfMemory => m.throw(.oom),
    };
}

// a x -- a[x]
fn run_e(m: *sbl.Machine) !void {
    const x = m.pop();
    const a = m.top();

    if (x.empty()) {
        a.release(m.gpa);
        a.* = x;
        return;
    }

    const as = a.into(.array);
    if (x.atom()) {
        if (as.header.rank != 1) {
            const sh = as.shape();

            // TODO: avoiding temporary allocation here?
            var start: []usize = try m.gpa.alloc(usize, sh.len);
            defer m.gpa.free(start);
            @memset(start, 0);

            start[0] = x.coerce(.char);
            if (start[0] >= @as(usize, @intCast(sh[0])))
                return m.throw(.bounds);

            const start_idx = as.flat_index(start[0..sh.len]);

            var end: []usize = try m.gpa.alloc(usize, sh.len);
            defer m.gpa.free(end);
            end[0] = x.coerce(.char) + 1;
            const end_idx = as.flat_index(start[0..sh.len]);

            // TODO: array slice views without copying?
            var res = try sbl.Array.init(m.gpa, sh[1..], .any);

            for (res.any_slice(), 0..) |*elem, i| {
                elem.* = as.get(start_idx + i);
                elem.retain();
            }

            _ = end_idx;

            a.* = .array(res);
            as.release(m.gpa);

            return;
        }

        const i = x.coerce(.char);
        if (i >= as.length()) return m.throw(.bounds);

        const elem = as.get(i);
        elem.retain();
        a.* = elem;

        as.release(m.gpa);
        return;
    }

    // TODO: multi-dimensional indexes
    return m.throw(.nyi);
}
