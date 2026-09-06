const std = @import("std");
const common = @import("common.zig");
const Connection = @import("../Connection.zig");
const utils = @import("../utils.zig");

id: u32,

const Self = @This();

const Requests = enum(u8) { Sync, GetRegistry };
pub const Events = enum(u8) { Error, DeleteId, _ };

pub const SyncArgs = extern struct { callback: u32 };
pub fn sync(self: *const Self, conn: *const Connection, args: SyncArgs) !u32 {
    const header = common.Header{
        .id = self.id,
        .length = @sizeOf(common.Header) + @sizeOf(SyncArgs),
        .opcode = @intFromEnum(Requests.Sync),
    };

    try conn.writer.writeAll(std.mem.asBytes(&header));
    try conn.writer.writeAll(std.mem.asBytes(&args));
    try conn.writer.flush();

    return args.callback;
}

pub const GetRegistryArgs = extern struct { registry: u32 };
pub fn getRegistry(self: *const Self, conn: *const Connection, args: GetRegistryArgs) !u32 {
    const header = common.Header{
        .id = self.id,
        .length = @sizeOf(common.Header) + @sizeOf(GetRegistryArgs),
        .opcode = @intFromEnum(Requests.GetRegistry),
    };

    try conn.writer.writeAll(std.mem.asBytes(&header));
    try conn.writer.writeAll(std.mem.asBytes(&args));
    try conn.writer.flush();

    return args.registry;
}

pub const ErrorEvent = struct {
    object_id: u32,
    code: u32,
    message: []u8,

    pub fn format(self: *const ErrorEvent, writer: *std.Io.Writer) !void {
        try writer.print(
            "wl_display_error_event: {{ object_id: {d}, code: {d}, message: {s} }}",
            .{ self.object_id, self.code, self.message },
        );
    }
};
pub fn handleError(allocator: std.mem.Allocator, ev: []u8) !common.Event {
    var offset: u32 = 0;
    const size_of_u32 = @sizeOf(u32);

    const object_id = std.mem.readInt(u32, ev[offset .. offset + size_of_u32][0..size_of_u32], .little);
    offset += size_of_u32;

    const code = std.mem.readInt(u32, ev[offset .. offset + size_of_u32][0..size_of_u32], .little);
    offset += size_of_u32;

    const message_len = std.mem.readInt(u32, ev[offset .. offset + size_of_u32][0..size_of_u32], .little);
    offset += size_of_u32;

    const message: []u8 = try allocator.dupe(u8, utils.takeString(ev, message_len, &offset));

    return common.Event{
        .wl_display_error = ErrorEvent{
            .object_id = object_id,
            .code = code,
            .message = message,
        },
    };
}

pub const DeleteIdEvent = struct {
    id: u32,

    pub fn format(self: *const DeleteIdEvent, writer: *std.Io.Writer) !void {
        try writer.print(
            "wl_display_delete_id_event: {{ id: {d} }}",
            .{self.id},
        );
    }
};
pub fn handleDeleteId(ev: []u8) common.Event {
    const id: u32 = std.mem.readInt(u32, ev[0..@sizeOf(u32)], .little);
    return common.Event{
        .wl_display_delete_id = DeleteIdEvent{
            .id = id,
        },
    };
}
