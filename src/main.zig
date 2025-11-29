const std = @import("std");
const NTop = @import("NTop");
const clap = @import("clap");
const windows = std.os.windows;

pub extern fn cmain(windows.BOOL) c_int;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const params = comptime clap.parseParamsComptime(
        \\-h, --help                               Display this help info.
        \\-C, --monochrome                         Use a monochrome color scheme.
        \\-p, --pids <str>...                      Show only the given PIDs (comma-separated: PID,PID...).
        \\-n, --names <str>...                     Show only processes containing at least one of the name parts (comma-separated).
        \\-s, --sort <str>                         Sort by this column.
        \\-u, --user <str>                         Display only processes of this user.
        \\-d, --non-interactive                    Do not run in interactive mode.
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

    const result = cmain(res.args.monochrome);
    std.process.exit(@intCast(result));
}
