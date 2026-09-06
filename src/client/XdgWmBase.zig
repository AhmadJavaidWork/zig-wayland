const std = @import("std");
const Connection = @import("../Connection.zig");
const common = @import("common.zig");

id: u32,

const Self = @This();

const Requests = enum(u8) { Destroy, CreatePositioner, GetXdgSurface, Pong };
pub const Events = enum(u8) { Ping, _ };

pub const CreatePositionerArgs = extern struct { id: u32 };
pub const GetXdgSurfaceArgs = extern struct { id: u32, surface: u32 };
pub const PongArgs = extern struct { serial: u32 };

pub const Ping = struct {
    serial: u32,

    pub fn format(self: *const Ping, writer: *std.Io.Writer) !void {
        try writer.print("xdg_wm_base_event: {{ serial: {d} }}", .{self.serial});
    }
};

pub fn destroy(self: *const Self, conn: *const Connection) !void {
    const header = common.Header{
        .id = self.id,
        .opcode = @intFromEnum(Requests.Destroy),
        .length = @sizeOf(common.Header),
    };

    try conn.writer.writeAll(std.mem.asBytes(&header));
    try conn.writer.flush();
}

pub fn createPositioner(self: *const Self, conn: *const Connection, args: CreatePositionerArgs) !u32 {
    const header = common.Header{
        .id = self.id,
        .opcode = @intFromEnum(Requests.CreatePositioner),
        .length = @sizeOf(common.Header) + @sizeOf(CreatePositionerArgs),
    };

    try conn.writer.writeAll(std.mem.asBytes(&header));
    try conn.writer.writeAll(std.mem.asBytes(&args));
    try conn.writer.flush();

    return args.id;
}

pub fn getXdgSurface(self: *const Self, conn: *const Connection, args: GetXdgSurfaceArgs) !u32 {
    const header = common.Header{
        .id = self.id,
        .opcode = @intFromEnum(Requests.GetXdgSurface),
        .length = @sizeOf(common.Header) + @sizeOf(GetXdgSurfaceArgs),
    };

    try conn.writer.writeAll(std.mem.asBytes(&header));
    try conn.writer.writeAll(std.mem.asBytes(&args));
    try conn.writer.flush();

    return args.id;
}

pub fn pong(self: *const Self, conn: *const Connection, args: PongArgs) !void {
    const header = common.Header{
        .id = self.id,
        .opcode = @intFromEnum(Requests.Pong),
        .length = @sizeOf(common.Header) + @sizeOf(PongArgs),
    };

    try conn.writer.writeAll(std.mem.asBytes(&header));
    try conn.writer.writeAll(std.mem.asBytes(&args));
    try conn.writer.flush();
}

pub fn handlePing(ev: []u8) common.Event {
    return common.Event{
        .ping = Ping{
            .serial = std.mem.readInt(u32, ev[0..@sizeOf(u32)], .little),
        },
    };
}
