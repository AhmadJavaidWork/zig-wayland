const std = @import("std");
const Connection = @import("../Connection.zig");
const common = @import("common.zig");

id: u32,

const Self = @This();

const Requests = enum(u8) { CreatePool, Release };
pub const Events = enum(u8) { Format, _ };

pub const Format = struct {
    format_data: u32,

    pub fn format(self: *const Format, writer: *std.Io.Writer) !void {
        try writer.print("wl_shm_format_event: {{ format: 0x{x} }}", .{self.format_data});
    }
};

pub const CreatePoolArgs = extern struct { id: u32, fd: std.os.linux.fd_t, size: i32 };

// pub fn createPool(self: *const Self, conn: *const Connection, args: CreatePoolArgs) !u32 {}

// pub fn release(self: *const Self, conn: *const Connection) !void {}

pub fn handleFormat(ev: []u8) common.Event {
    return common.Event{
        .wl_shm_format = Format{
            .format_data = std.mem.readInt(u32, ev[0..@sizeOf(u32)], .little),
        },
    };
}
