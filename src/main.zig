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

    try setupRegistry(allocator, &conn);

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
            .global => {
                std.debug.print("received: {f}\n", .{msg.event});
            },
            .global_remove => {
                std.debug.print("received: {f}\n", .{msg.event});
            },
            .callback => {
                std.debug.print("received: {f}\n", .{msg.event});
            },
            .wl_shm_format => {
                std.debug.print("received: {f}\n", .{msg.event});
            },
            .ping => |p| {
                std.debug.print("received: {f}\n", .{p});
                try conn.xdg_wm_base.?.pong(&conn, .{ .serial = p.serial });
            },
            .unknown => |ev| {
                std.debug.print("received: {f}\n", .{msg.event});
                allocator.free(ev.data);
            },
        }
    }
}

pub fn setupRegistry(allocator: std.mem.Allocator, conn: *Connection) !void {
    conn.wl_registry = client.WlRegistry{
        .id = try conn.wl_display.?.getRegistry(
            conn,
            .{
                .registry = try conn.allocateId(allocator, Interfaces.WlRegistry),
            },
        ),
    };

    const callback = client.WlCallback{
        .id = try conn.wl_display.?.sync(
            conn,
            .{
                .callback = try conn.allocateId(allocator, Interfaces.WlCallback),
            },
        ),
    };

    while (true) {
        const header = try conn.reader.peekStructPointer(client.common.Header);
        const interface: Interfaces = conn.objects.items[header.id];
        switch (interface) {
            .WlRegistry => {
                const msg = try conn.nextEvent(allocator);
                switch (msg.event) {
                    .global => |g| {
                        std.debug.print("received: {f}\n", .{msg.event});
                        switch (g) {
                            .wl_compositor => {
                                conn.wl_compositor = client.WlCompositor{
                                    .id = try conn.wl_registry.?.bind(
                                        conn,
                                        .{
                                            .global = g,
                                            .id = try conn.allocateId(allocator, Interfaces.WlCompositor),
                                        },
                                    ),
                                };
                            },
                            .xdg_wm_base => {
                                conn.xdg_wm_base = client.XdgWmBase{
                                    .id = try conn.wl_registry.?.bind(
                                        conn,
                                        .{
                                            .global = g,
                                            .id = try conn.allocateId(allocator, Interfaces.XdgWmBase),
                                        },
                                    ),
                                };
                            },
                            .wl_shm => {
                                conn.wl_shm = client.WlShm{
                                    .id = try conn.wl_registry.?.bind(
                                        conn,
                                        .{
                                            .global = g,
                                            .id = try conn.allocateId(allocator, Interfaces.WlShm),
                                        },
                                    ),
                                };
                            },
                            else => {},
                        }
                    },
                    .global_remove => {
                        std.debug.print("received: {f}\n", .{msg.event});
                    },
                    .unknown => |ev| {
                        std.debug.print("received: {f}\n", .{msg.event});
                        allocator.free(ev.data);
                    },
                    else => {
                        break;
                    },
                }
            },
            .WlCallback => {
                const msg = try conn.nextEvent(allocator);
                switch (msg.event) {
                    .callback => {
                        std.debug.print("received: {f}\n", .{msg.event});
                        if (msg.sender == callback.id) break;
                    },
                    .unknown => |ev| {
                        std.debug.print("received: {f}\n", .{msg.event});
                        allocator.free(ev.data);
                    },
                    else => {
                        break;
                    },
                }
            },
            else => {
                break;
            },
        }
    }
}
