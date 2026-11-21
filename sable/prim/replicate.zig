pub fn run(m: *sbl.Machine) void {
    const x = m.pop();
    const a = m.pop();

    defer x.release(m.gpa);
    defer a.release(m.gpa);

    if (a.empty()) return m.push(.none());

    if (a.atom()) return m.throw(.nyi);
    const arr = a.into(.array);

    if (arr.ra() != 1) return m.throw(.nyi);

    if (x.atom()) {
        if (!x.is_num()) return m.throw(.type);
        const n: u64 = @trunc(x.into(.num));
        const len = arr.length() * n;
        const len_dim: i64 = @intCast(len);

        var out = sbl.Array.init(m.gpa, &.{len_dim}, .any) catch return m.throw(.oom);
        var out_any = out.any_slice();
        for (0..arr.length()) |i| {
            @memset(out_any[i * n ..][0..n], arr.get(i));
        }

        const ret = out.downcast(m.gpa) catch return m.throw(.oom);
        return m.push(.array(ret));
    }

    const xs = x.into(.array);
    if (xs.ra() != arr.ra()) return m.throw(.rank);
    if (xs.shape()[0] != arr.shape()[0]) return m.throw(.shape);
    if (xs.ty() != .num) return m.throw(.type);

    var len: i64 = 0;
    for (xs.num_slice()) |n| len += @trunc(n);

    var out = sbl.Array.init(m.gpa, &.{len}, .any) catch return m.throw(.oom);
    var out_any = out.any_slice();
    var cnt: u64 = 0;
    for (xs.num_slice(), 0..) |num, i| {
        const n: u64 = @trunc(num);
        @memset(out_any[cnt..][0..n], arr.get(i));
        cnt += n;
    }

    const ret = out.downcast(m.gpa) catch return m.throw(.oom);
    return m.push(.array(ret));
}

const sbl = @import("sbl");
const std = @import("std");
