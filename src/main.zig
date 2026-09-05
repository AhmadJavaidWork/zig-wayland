const std = @import("std");
const utils = @import("utils.zig");
const Connection = @import("Connection.zig");
const client = @import("client/root.zig");

const print = std.debug.print;
const Interfaces = client.common.Interfaces;

pub fn main(init: std.process.Init) !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    const display = try utils.getDisplay(allocator, init);
    defer allocator.free(display);

    const stream = try utils.setupStream(init.io, display);
    defer stream.close(init.io);

    var read_buffer: [1024 * 4]u8 = undefined;
    var write_buffer: [1024 * 4]u8 = undefined;

    var stream_reader = stream.reader(init.io, read_buffer[0..]);
    var stream_writer = stream.writer(init.io, write_buffer[0..]);

    var conn = Connection{
        .stream = stream,
        .reader = &stream_reader.interface,
        .writer = &stream_writer.interface,
    };
    try conn.init(allocator);
    defer conn.deinit(allocator);

    conn.wl_display = client.WlDisplay{
        .id = try conn.allocateId(allocator, Interfaces.WlDisplay),
    };

    try conn.wl_display.?.getRegistry(
        &conn,
        .{
            .new_id = try conn.allocateId(allocator, Interfaces.WlRegistry),
        },
    );

    while (true) {
        const msg = try conn.nextEvent(allocator);
        switch (msg.event) {
            .wl_display_error => |ev| {
                std.debug.print("received: {f}\n", .{msg.event});
                allocator.free(ev.message);
            },
            .wl_delete_id => {
                std.debug.print("received: {f}\n", .{msg.event});
            },
            .unknown => |ev| {
                std.debug.print("received: {f}\n", .{msg.event});
                allocator.free(ev.data);
            },
        }
    }
}
