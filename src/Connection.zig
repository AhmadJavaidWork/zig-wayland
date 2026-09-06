const std = @import("std");
const Io = std.Io;
const client = @import("client/root.zig");
const common = client.common;

stream: Io.net.Stream,
reader: *Io.Reader,
writer: *Io.Writer,
objects: std.ArrayList(client.common.Interfaces) = .empty,
wl_display: ?client.WlDisplay = null,
wl_registry: ?client.WlRegistry = null,

const Self = @This();

pub fn init(self: *Self, allocator: std.mem.Allocator) !void {
    try self.objects.append(allocator, common.Interfaces._padding);
}

pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
    self.objects.deinit(allocator);
    self.wl_display = null;
    self.wl_registry = null;
}

pub fn allocateId(self: *Self, allocator: std.mem.Allocator, interface: common.Interfaces) !u32 {
    try self.objects.append(allocator, interface);
    return @intCast(self.objects.items.len - 1);
}

pub fn nextEvent(self: *const Self, allocator: std.mem.Allocator) !client.common.Message {
    const header = try self.reader.takeStructPointer(common.Header);
    const ev = try self.reader.take(header.length - @sizeOf(common.Header));
    const interface: common.Interfaces = self.objects.items[header.id];
    const event = switch (interface) {
        .WlDisplay => blk: {
            const event: client.WlDisplay.Events = @enumFromInt(header.opcode);
            break :blk switch (event) {
                .Error => try client.WlDisplay.handleError(allocator, ev),
                .DeleteId => client.WlDisplay.handleDeleteId(ev),
                else => try common.handleUnknownEvent(allocator, ev),
            };
        },
        .WlRegistry => blk: {
            const event: client.WlRegistry.Events = @enumFromInt(header.opcode);
            break :blk switch (event) {
                .Global => try client.WlRegistry.handleGlobal(ev),
                .GlobalRemove => client.WlRegistry.handleGlobalRemove(ev),
                else => try common.handleUnknownEvent(allocator, ev),
            };
        },
        .WlCallback => blk: {
            const event: client.WlCallback.Events = @enumFromInt(header.opcode);
            break :blk switch (event) {
                .Done => client.WlCallback.handleDone(ev),
                else => try common.handleUnknownEvent(allocator, ev),
            };
        },
        else => blk: {
            std.debug.print("unhandled interface: {any}\n", .{interface});
            break :blk try common.handleUnknownEvent(allocator, ev);
        },
    };

    return .{ .sender = header.id, .event = event };
}
