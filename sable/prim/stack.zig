const std = @import("std");
const sbl = @import("sbl");

pub fn id(m: *sbl.Machine) void {
    _ = m;
}

pub fn dup(m: *sbl.Machine) void {
    const x = m.top().*;
    x.retain();
    m.push(x);
}

pub fn drop(m: *sbl.Machine) void {
    const x = m.pop();
    x.release(m.gpa);
}

pub fn swap(m: *sbl.Machine) void {
    std.debug.assert(m.dat_p > 1);

    const dat_p = @as(usize, @intCast(m.dat_p));
    const y = &m.dat[dat_p - 1];
    const x = &m.dat[dat_p - 2];

    std.mem.swap(sbl.Cell, x, y);
}

pub fn over(m: *sbl.Machine) void {
    std.debug.assert(m.dat_p > 1);

    const dat_p = @as(usize, @intCast(m.dat_p));
    const x = m.dat[dat_p - 2];

    x.retain();
    m.push(x);
}

pub fn rot(m: *sbl.Machine) void {
    std.debug.assert(m.dat_p > 2);

    const dat_p = @as(usize, @intCast(m.dat_p));
    const z = &m.dat[dat_p - 1];
    const y = &m.dat[dat_p - 2];
    const x = &m.dat[dat_p - 3];

    std.mem.swap(sbl.Cell, x, y);
    std.mem.swap(sbl.Cell, y, z);
}
