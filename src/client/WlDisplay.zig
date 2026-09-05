const std = @import("std");
const common = @import("common.zig");
const Connection = @import("../Connection.zig");

id: u32,

const Self = @This();

const Requests = enum(u8) { Sync, GetRegistry };
pub const Events = enum(u8) { Error, DeleteId, _ };

pub const SyncArgs = extern struct { new_id: u32 };
pub const GetRegistryArgs = extern struct { new_id: u32 };

pub const Error = struct {
    object_id: u32,
    code: u32,
    message: []u8,

    pub fn format(self: *const Error, writer: *std.Io.Writer) !void {
        try writer.print(
            "wl_display_error_event: {{ object_id: {d}, code: {d}, message: {s} }}",
            .{ self.object_id, self.code, self.message },
        );
    }
};

pub const DeleteId = struct {
    id: u32,

    pub fn format(self: *const DeleteId, writer: *std.Io.Writer) !void {
        try writer.print(
            "wl_display_delete_id_event: {{ id: {d} }}",
            .{self.id},
        );
    }
};

pub fn sync(self: *const Self, conn: *const Connection, args: SyncArgs) !void {
    const header = common.Header{
        .id = self.id,
        .length = @sizeOf(common.Header) + @sizeOf(SyncArgs),
        .opcode = @intFromEnum(Requests.Sync),
    };

    try conn.writer.writeAll(std.mem.asBytes(&header));
    try conn.writer.writeAll(std.mem.asBytes(&args));
    try conn.writer.flush();
}

pub fn getRegistry(self: *const Self, conn: *const Connection, args: GetRegistryArgs) !void {
    const header = common.Header{
        .id = self.id,
        .length = @sizeOf(common.Header) + @sizeOf(GetRegistryArgs),
        .opcode = @intFromEnum(Requests.GetRegistry),
    };

    try conn.writer.writeAll(std.mem.asBytes(&header));
    try conn.writer.writeAll(std.mem.asBytes(&args));
    try conn.writer.flush();
}

pub fn handleError(allocator: std.mem.Allocator, ev: []u8) !common.Event {
    var offset: u32 = 0;
    const size_of_u32 = @sizeOf(u32);

    const object_id = std.mem.readInt(u32, ev[offset .. offset + size_of_u32][0..size_of_u32], .little);
    offset += size_of_u32;

    const code = std.mem.readInt(u32, ev[offset .. offset + size_of_u32][0..size_of_u32], .little);
    offset += size_of_u32;

    const message_len = std.mem.readInt(u32, ev[offset .. offset + size_of_u32][0..size_of_u32], .little);
    offset += size_of_u32;

    const message: []u8 = try allocator.dupe(u8, ev[offset .. offset + message_len]);
    const pad = std.mem.alignForward(usize, message_len, 4);
    offset += @intCast(pad);

    return common.Event{
        .wl_display_error = Error{
            .object_id = object_id,
            .code = code,
            .message = message,
        },
    };
}

pub fn handleDeleteId(ev: []u8) common.Event {
    const id: u32 = std.mem.readInt(u32, ev[0..@sizeOf(u32)], .little);
    return common.Event{
        .wl_delete_id = DeleteId{
            .id = id,
        },
    };
}
