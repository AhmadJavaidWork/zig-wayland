const std = @import("std");
const utils = @import("utils.zig");

const print = std.debug.print;

pub fn main(init: std.process.Init) !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    const display = try utils.get_display(allocator, init);
    defer allocator.free(display);

    const stream = try utils.setup_stream(init.io, display);
    defer stream.close(init.io);

    var read_buffer: [1024 * 4]u8 = undefined;
    var write_buffer: [1024 * 4]u8 = undefined;

    var stream_reader = stream.reader(init.io, read_buffer[0..]);
    var stream_writer = stream.writer(init.io, write_buffer[0..]);

    _ = &stream_reader.interface;
    _ = &stream_writer.interface;
}
