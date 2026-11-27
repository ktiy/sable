bindings: std.ArrayList(Binding) = .empty,
marks: std.ArrayList(Mark) = .empty,
next_slot: u32 = 0,
next_func: u32 = 0,

pub const empty: Scope = .{};

pub const Res = union(enum) {
    none,
    slot: u32,
    func: u32,
    scope: struct { i: u32, j: u32 },
};

pub const Binding = struct {
    sym: Symbol,
    eff: sbl.bc.StackEffect,
    res: Res,
};

/// for recovery
pub const Checkpoint = struct {
    bindings: usize,
    slot: u32,
    func: u32,
};

const Mark = struct {
    bindings: u32,
    slot: u32,
};

pub fn deinit(s: *Scope, gpa: Alloc) void {
    s.bindings.deinit(gpa);
    s.marks.deinit(gpa);
}

pub fn push(s: *Scope, gpa: Alloc) !void {
    try s.marks.append(gpa, .{
        .bindings = @intCast(s.bindings.items.len),
        .slot = s.next_slot,
    });
}

pub fn pop(s: *Scope) Res {
    const m = s.marks.pop().?;
    s.bindings.shrinkRetainingCapacity(m.bindings);
    return .{ .scope = .{ .i = m.slot, .j = s.next_slot } };
}

pub fn alloc_slot(s: *Scope) u32 {
    defer s.next_slot += 1;
    return s.next_slot;
}

pub fn alloc_func(s: *Scope) u32 {
    defer s.next_func += 1;
    return s.next_func;
}

pub fn bind(
    s: *Scope,
    gpa: Alloc,
    sym: Symbol,
    eff: sbl.bc.StackEffect,
    res: Res,
) !void {
    try s.bindings.append(gpa, .{ .sym = sym, .eff = eff, .res = res });
}

pub fn lookup(s: *const Scope, sym: Symbol) ?Binding {
    var i = s.bindings.items.len;
    while (i > 0) : (i -= 1) {
        if (s.bindings.items[i - 1].sym == sym)
            return s.bindings.items[i - 1];
    }
    return null;
}

pub fn checkpoint(s: *const Scope) Checkpoint {
    return .{
        .bindings = s.bindings.items.len,
        .slot = s.next_slot,
        .func = s.next_func,
    };
}

pub fn restore(s: *Scope, c: Checkpoint) void {
    s.bindings.shrinkRetainingCapacity(c.bindings);
    s.marks.clearRetainingCapacity();
    s.next_slot = c.slot;
    s.next_func = c.func;
}

const Scope = @This();
const std = @import("std");
const sbl = @import("sbl");
const Alloc = std.mem.Allocator;
const Symbol = sbl.SymTable.Symbol;
