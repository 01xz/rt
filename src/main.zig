const std = @import("std");
const config = @import("config");

pub fn main() !void {
    std.debug.print("hello rt {s}\n", .{config.version});
}
