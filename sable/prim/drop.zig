pub fn run(m: *sbl.Machine) void {
    run_e(m) catch m.throw(.oom);
}

fn run_e(m: *sbl.Machine) !void {
    const x = m.pop();
    const a = m.pop();

    defer x.release(m.gpa);
    defer a.release(m.gpa);

    if (x.is_array()) return m.throw(.nyi);
    if (!x.is_num()) return m.throw(.type);

    const n: i64 = @intFromFloat(@trunc(x.into(.num)));

    if (a.empty()) return m.push(.none());
    if (a.atom()) return m.throw(.nyi);

    const arr = a.into(.array);
    const have: usize = @intCast(arr.shape()[0]);

    const drop = @min(@as(usize, @intCast(@abs(n))), have);
    const keep = have - drop;
    if (0 == keep) return m.push(.none());

    var stride: usize = 1;
    for (arr.shape()[1..]) |d| stride *= @intCast(d);

    var dst_sh: [std.math.maxInt(u8)]Dim = undefined;
    const src_sh = arr.shape();
    @memcpy(dst_sh[0..src_sh.len], src_sh);
    dst_sh[0] = @intCast(keep);

    const kind = arr.ty();
    var ret: sbl.Array = try .init(m.gpa, dst_sh[0..src_sh.len], kind);
    switch (kind) {
        inline else => |k| {
            const src_row = if (n >= 0) drop else 0;
            const src_off = src_row * stride;
            const len = keep * stride;
            const src = arr.slice(k)[src_off..][0..len];
            const dst = ret.slice(k)[0..len];
            @memcpy(dst, src);
            if (k == .any) for (dst) |c| c.retain();
        },
    }

    m.push(.array(ret));
}

const Dim = sbl.Array.Dim;
const std = @import("std");
const sbl = @import("sbl");
