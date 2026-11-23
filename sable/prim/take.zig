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
    const want: usize = @intCast(@abs(n));
    if (0 == want) return m.push(.none());

    if (a.empty()) {
        const ret: sbl.Array = try .init(m.gpa, &.{@intCast(want)}, .num);
        return m.push(.array(ret));
    }

    if (a.atom()) return m.throw(.nyi);
    const arr = a.into(.array);
    const have: usize = @intCast(arr.shape()[0]);
    const keep = @min(want, have);

    var stride: usize = 1;
    for (arr.shape()[1..]) |d| stride *= @intCast(d);

    const src_sh = arr.shape();
    var dst_sh: [std.math.maxInt(u8)]Dim = undefined;
    @memcpy(dst_sh[0..src_sh.len], src_sh);
    dst_sh[0] = @intCast(want);

    const kind = arr.ty();
    const ret: sbl.Array = try .init(m.gpa, dst_sh[0..src_sh.len], kind);
    switch (kind) {
        inline else => |k| {
            // negative n pads the front with default values
            const src_row = if (n >= 0) 0 else have - keep;
            const dst_row = if (n >= 0) 0 else want - keep;
            const src_off = src_row * stride;
            const dst_off = dst_row * stride;
            const len = keep * stride;

            const out = ret.slice(k);
            const src = arr.slice(k)[src_off..][0..len];
            const dst = out[dst_off..][0..len];
            @memcpy(dst, src);
            if (k == .any) for (dst) |c| c.retain();
            if (k == .char) {
                // use space as default value for chars
                @memset(out[0..dst_off], ' ');
                @memset(out[dst_off + len ..], ' ');
            }
        },
    }

    m.push(.array(ret));
}

const Dim = sbl.Array.Dim;
const std = @import("std");
const sbl = @import("sbl");
