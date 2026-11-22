export fn alloc(len: usize) ?[*]u8 {
    const buf = gpa.alloc(u8, len) catch return null;
    return buf.ptr;
}

export fn free(ptr: [*]u8, len: usize) void {
    gpa.free(ptr[0..len]);
}

export fn sbl_result_ptr() [*]const u8 {
    return result.ptr;
}

export fn sbl_result_len() usize {
    return result.len;
}

export fn sbl_eval(ptr: [*]const u8, len: usize, max_steps: u32) bool {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    const ally = arena.allocator();
    var aw: std.Io.Writer.Allocating = .init(gpa);

    if (result.len > 0) gpa.free(result);
    const ok = run(ally, ptr[0..len], max_steps, &aw.writer) catch |e| {
        aw.writer.print("err: {s}\n", .{@errorName(e)}) catch {};
        result = gpa.dupe(u8, aw.written()) catch &.{};
        return false;
    };

    result = gpa.dupe(u8, aw.written()) catch &.{};
    return ok;
}

fn run(ally: std.mem.Allocator, text: []const u8, max_steps: u32, w: *std.Io.Writer) !bool {
    const content = try ally.dupeSentinel(u8, text, 0);
    defer ally.free(content);

    const src: sbl.SourceFile = .{ .path = "<repl>", .content = content };

    var lex: sbl.Token.Lexer = .init(src.content, 0);
    var tokens = lex.collect(ally) catch |e| {
        const loc: sbl.SourceFile.Position = .cursor(src.content, lex.pos);
        try w.print("{d}:{d}: {s}\n", .{ loc.line, loc.column, @errorName(e) });
        return false;
    };
    defer tokens.deinit(ally);

    var ast: sbl.Syntax = try .parse(ally, tokens);
    defer ast.deinit(ally);
    if (try report(w, src, ast.errors)) return false;

    var st: sbl.SymTable = try .init(ally);
    defer st.deinit();

    const sema = try sbl.Analysis.run(ally, ast, tokens, src.content, &st);
    defer sema.deinit(ally);
    if (try report(w, src, sema.errors)) return false;

    var env: sbl.Compiler.Env = .empty;
    defer env.deinit(ally);

    var prog = try sbl.Compiler.run(ally, ast, tokens, src.content, &st, sema, &env, 0, 0);
    defer prog.deinit(ally);
    if (try report(w, src, prog.errors)) return false;

    var m = sbl.Machine.init(ally, io, prog);
    defer m.deinit();
    m.stdout = w;
    var cnt: u64 = 0;
    while (m.step()) : (cnt += 1) {
        if (cnt >= max_steps) {
            try w.print("sorry\n", .{});
            return false;
        }
    }

    if (m.e.kind != .none) {
        try m.e.report(w, src.content);
        return false;
    }

    const n: usize = @intCast(m.dat_p);
    for (m.dat[0..n]) |c| try w.print("{f}\n", .{c});
    return true;
}

fn report(w: *std.Io.Writer, src: sbl.SourceFile, es: []const sbl.CompileError) !bool {
    for (es) |e| try e.report(w, src);
    return es.len > 0;
}

pub const std_options: std.Options = .{ .logFn = no_log };

fn no_log(
    comptime _: std.log.Level,
    comptime _: @TypeOf(.a),
    comptime _: []const u8,
    _: anytype,
) void {}

var result: []u8 = &.{};

const gpa = std.heap.wasm_allocator;
const io: std.Io = .failing;

const std = @import("std");
const sbl = @import("sbl");
