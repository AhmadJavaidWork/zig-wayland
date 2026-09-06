const std = @import("std");
const WlRegistry = @import("client/WlRegistry.zig");

const net = std.Io.net;

pub fn getDisplay(allocator: std.mem.Allocator, init: std.process.Init) ![]u8 {
    const args = try init.minimal.args.toSlice(allocator);
    defer allocator.free(args);

    if (args.len == 1) {
        const dir = init.environ_map.get("XDG_RUNTIME_DIR") orelse return error.NoXdgRuntimeDir;
        const display = init.environ_map.get("WAYLAND_DISPLAY") orelse return error.NoDisplay;
        return try std.fmt.allocPrint(allocator, "{s}/{s}", .{ dir, display });
    } else {
        return try allocator.dupe(u8, args[1]);
    }
}

pub fn setupStream(io: std.Io, display: []const u8) !net.Stream {
    const address = try net.UnixAddress.init(display);
    return try address.connect(io);
}

pub fn takeString(bytes: []u8, length: u32, offset: *u32) []u8 {
    const s: []u8 = bytes[offset.* .. offset.* + length];
    const pad = std.mem.alignForward(u32, length, @sizeOf(u32));
    offset.* += @intCast(pad);
    return s;
}

pub fn nameToGlobal(name: []const u8, value: WlRegistry.Global) WlRegistry.GlobalEvent {
    inline for (@typeInfo(WlRegistry.GlobalEvent).@"union".fields) |f| {
        if (std.mem.eql(u8, name, f.name)) {
            return @unionInit(WlRegistry.GlobalEvent, f.name, value);
        }
    }

    return WlRegistry.GlobalEvent{ .unknown_global = value };
}
