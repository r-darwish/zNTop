const std = @import("std");
const NTop = @import("NTop");

pub extern fn cmain(argc: c_int, argv: [*c][*c]u8) c_int;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const arena_allocator = arena.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    const argv = try arena_allocator.alloc([*c]u8, args.len);

    for (args, 0..) |arg, i| {
        const c_arg = try arena_allocator.dupeZ(u8, arg);
        argv[i] = c_arg.ptr;
    }

    const result = cmain(@intCast(args.len), argv.ptr);
    std.process.exit(@intCast(result));
}
