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

    const listener_thread_id = try std.Thread.spawn(.{}, eventListener, .{ allocator, &conn });

    conn.wl_surface = client.WlSurface{
        .id = try conn.wl_compositor.?.create_surface(
            &conn,
            .{
                .id = try conn.allocateId(allocator, Interfaces.WlSurface),
            },
        ),
    };

    conn.xdg_surface = client.XdgSurface{
        .id = try conn.xdg_wm_base.?.getXdgSurface(
            &conn,
            .{
                .id = try conn.allocateId(allocator, Interfaces.XdgSurface),
                .surface = conn.wl_surface.?.id,
            },
        ),
    };

    conn.xdg_toplevel = client.XdgToplevel{
        .id = try conn.xdg_surface.?.getToplevel(
            &conn,
            .{
                .id = try conn.allocateId(allocator, Interfaces.XdgToplevel),
            },
        ),
    };

    const title: []const u8 = "Hello World in Wayland";
    const app_id: []const u8 = "Hello World in Wayland";

    try conn.xdg_toplevel.?.setTitle(
        &conn,
        .{
            .title = title[0..],
        },
    );
    try conn.xdg_toplevel.?.setAppId(
        &conn,
        .{
            .app_id = app_id[0..],
        },
    );

    try conn.wl_surface.?.commit(&conn);

    listener_thread_id.join();
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
                    .wl_registry_global => |g| {
                        print("received: {f}\n", .{msg.event});
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
                    .wl_registry_global_remove => {
                        print("received: {f}\n", .{msg.event});
                    },
                    .unknown => |ev| {
                        print("received: {f}\n", .{msg.event});
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
                    .wl_callback_done => {
                        print("received: {f}\n", .{msg.event});
                        if (msg.sender == callback.id) break;
                    },
                    .unknown => |ev| {
                        print("received: {f}\n", .{msg.event});
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

pub fn eventListener(allocator: std.mem.Allocator, conn: *Connection) !void {
    while (true) {
        const msg = try conn.nextEvent(allocator);
        switch (msg.event) {
            .wl_display_error => |ev| {
                print("received: {f}\n", .{msg.event});
                allocator.free(ev.message);
            },
            .wl_display_delete_id => {
                print("received: {f}\n", .{msg.event});
            },
            .wl_registry_global => {
                print("received: {f}\n", .{msg.event});
            },
            .wl_registry_global_remove => {
                print("received: {f}\n", .{msg.event});
            },
            .wl_callback_done => {
                print("received: {f}\n", .{msg.event});
            },
            .wl_shm_format => {
                print("received: {f}\n", .{msg.event});
            },
            .xdg_wm_base_ping => |p| {
                print("received: {f}\n", .{p});
                try conn.xdg_wm_base.?.pong(conn, .{ .serial = p.serial });
            },
            .wl_surface_enter => {
                print("received: {f}\n", .{msg.event});
            },
            .wl_surface_leave => {
                print("received: {f}\n", .{msg.event});
            },
            .wl_surface_preferred_buffer_scale => {
                print("received: {f}\n", .{msg.event});
            },
            .wl_surface_preferred_buffer_transform => {
                print("received: {f}\n", .{msg.event});
            },
            .xdg_surface_configure => {
                print("received: {f}\n", .{msg.event});
            },
            .xdg_toplevel_configure => {
                print("received: {f}\n", .{msg.event});
            },
            .xdg_toplevel_close => {
                print("received: {f}\n", .{msg.event});
            },
            .xdg_toplevel_configure_bounds => {
                print("received: {f}\n", .{msg.event});
            },
            .xdg_toplevel_wm_capabilities => |ev| {
                print("received: {f}\n", .{msg.event});
                allocator.free(ev.capabilities);
            },
            .unknown => |ev| {
                print("received: {f}\n", .{msg.event});
                allocator.free(ev.data);
            },
        }
    }
}
