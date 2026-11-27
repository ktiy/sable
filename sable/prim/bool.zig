pub const eq = prim(Eq);
pub const neq = prim(Neq);
pub const gt = prim(Gt);
pub const gt_eq = prim(Gteq);
pub const lt = prim(Lt);
pub const lt_eq = prim(Lteq);

pub const not = pervasive.arith1(Not);

// zig fmt: off
const Eq   = struct { pub fn cmp(x: anytype, y: anytype) bool { return x == y; } };
const Neq  = struct { pub fn cmp(x: anytype, y: anytype) bool { return x != y; } };
const Gt   = struct { pub fn cmp(x: anytype, y: anytype) bool { return x > y; } };
const Gteq = struct { pub fn cmp(x: anytype, y: anytype) bool { return x >= y; } };
const Lt   = struct { pub fn cmp(x: anytype, y: anytype) bool { return x < y; } };
const Lteq = struct { pub fn cmp(x: anytype, y: anytype) bool { return x <= y; } };

const Not = struct {
    pub fn f(_: M, x: f64) f64 { return 1 - x; }
    pub fn b(_: M, x: u8) u8 { return 1 -% x; }
    pub fn c(_: M, x: u32) u32 { return 1 -% x; }
};

const M = *sbl.Machine;
const std = @import("std");
const sbl = @import("sbl");
const pervasive = @import("pervasive.zig");
const prim = pervasive.cmp;
