gpa: std.mem.Allocator,
buf: std.ArrayList(u8) = .empty,
strs: std.ArrayList(struct { i: u32, j: u32 }) = .empty,

pub const Symbol = enum(u32) {
    none = std.math.maxInt(u32),
    _,
};

pub fn init(gpa: std.mem.Allocator) !SymTable {
    return .{
        .gpa = gpa,
    };
}

pub fn deinit(self: *SymTable) void {
    self.buf.deinit(self.gpa);
    self.strs.deinit(self.gpa);
}

pub fn intern(self: *SymTable, id: []const u8) !Symbol {
    if (id.len == 0) return .none;

    for (self.strs.items, 0..) |str, i| {
        if (std.mem.eql(u8, id, self.buf.items[str.i..str.j])) {
            return @fromBackingInt(@truncate(i));
        }
    }

    const sym = @as(u32, @truncate(self.strs.items.len));
    const i: u32 = @truncate(self.buf.items.len);
    const len: u32 = @truncate(id.len);

    try self.buf.appendSlice(self.gpa, id);
    try self.strs.append(self.gpa, .{ .i = i, .j = i + len });

    return @fromBackingInt(sym);
}

pub fn get(self: *SymTable, sym: Symbol) []const u8 {
    if (sym == .none) return "";
    const str = self.strs.items[@backingInt(sym)];
    return self.buf.items[str.i..str.j];
}

test "symbol table" {
    const gpa = std.testing.allocator;

    var st: SymTable = try .init(gpa);
    defer st.deinit();

    const avg = try st.intern("avg");

    const avg_str = st.get(avg);
    const x = try st.intern("x");
    const x_str = st.get(x);

    const avg2 = try st.intern("avg");
    const avg2_str = st.get(avg2);

    const x2 = try st.intern("x");
    const x2_str = st.get(x2);

    try std.testing.expectEqual(avg, avg2);
    try std.testing.expectEqualSlices(u8, avg_str, avg2_str);
    try std.testing.expectEqualSlices(u8, "avg", avg2_str);

    try std.testing.expectEqual(x, x2);
    try std.testing.expectEqualSlices(u8, x_str, x2_str);
    try std.testing.expectEqualSlices(u8, "x", x2_str);
}

const SymTable = @This();
const std = @import("std");
