const std = @import("std");
const sbl = @import("sbl");

pub fn run(m: *sbl.Machine) void {
    const c = m.top();

    switch (c.k) {
        .num => {
            const arr = array(m, @intFromFloat(c.x.num), .num) orelse return;
            _ = m.pop();
            for (arr.num_slice(), 0..) |*v, i| {
                v.* = @floatFromInt(i);
            }
            m.push(.array(arr));
        },
        .byte => {
            const arr = array(m, @intCast(c.x.byte), .byte) orelse return;
            _ = m.pop();
            for (arr.byte_slice(), 0..) |*v, i| {
                v.* = @intCast(i);
            }
            m.push(.array(arr));
        },
        .char => {
            const arr = array(m, @intCast(c.x.char), .char) orelse return;
            _ = m.pop();
            for (arr.char_slice(), 0..) |*v, i| {
                if (i >= std.math.maxInt(u32)) unreachable;
                v.* = @intCast(i);
            }
            m.push(.array(arr));
        },
        .array => m.throw(.nyi),
        else => m.throw(.type),
    }
}

fn array(m: *sbl.Machine, len: isize, comptime ty: sbl.Array.Kind) ?sbl.Array {
    return sbl.Array.init(m.gpa, &[_]sbl.Array.Dim{len}, ty) catch {
        m.throw(.oom);
        return null;
    };
}
