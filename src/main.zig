const std = @import("std");
const NTop = @import("NTop");
const clap = @import("clap");
const windows = std.os.windows;
const c = @cImport({
    @cInclude("ntop.h");
});

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const params = comptime clap.parseParamsComptime(
        \\-h, --help                               Display this help info.
        \\-C, --monochrome                         Use a monochrome color scheme.
        \\-p, --pids <u32>...                      Show only the given PIDs (comma-separated: PID,PID...).
        \\-n, --names <str>...                     Show only processes containing at least one of the name parts (comma-separated).
        \\-s, --sort <str>                         Sort by this column.
        \\-u, --user <str>                         Display only processes of this user.
        \\-d, --noninteractive                    Do not run in interactive mode.
        \\-v, --version                            Print version.
        \\
    );

    var diag = clap.Diagnostic{};
    var res = clap.parse(clap.Help, &params, clap.parsers.default, .{
        .diagnostic = &diag,
        .allocator = allocator,
    }) catch |err| {
        // try diag.reportToFile(stderr, err);
        return err;
    };
    defer res.deinit();

    var argsArena = std.heap.ArenaAllocator.init(allocator);
    var arenaAllocator = argsArena.allocator();
    var pidFilter: [*c]c_ulong = null;

    if (res.args.pids.len > 0) {
        pidFilter = (try arenaAllocator.alloc(c_ulong, res.args.pids.len)).ptr;
        for (res.args.pids, 0..) |pid, i| {
            pidFilter[i] = pid;
        }
    }

    // if (res.args.pids.len > 0) {
    //     pidFilter = (try arenaAllocator.alloc([*c]c_ulong, res.args.pids.len)).ptr;
    //     for (res.args.pids, 0..) |pid, i| {
    //         pidFilter[i] = arenaAllocator.dupeZ(u8, pid) catch @panic("allocation failed");
    //     }
    // // }
    defer argsArena.deinit();
    var cargs = c.args_t{
        .monochrome = res.args.monochrome,
        .sort_by = if (res.args.sort) |s| arenaAllocator.dupeZ(u8, s) catch null else null,
        .user_name = if (res.args.user) |s| arenaAllocator.dupeZ(u8, s) catch null else null,
        .non_interactive = res.args.noninteractive,
        .print_version = res.args.version,
        .pid_filter = pidFilter,
        .pid_filter_count = res.args.pids.len,
    };

    const result = c.cmain(&cargs);
    std.process.exit(@intCast(result));
}
