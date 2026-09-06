const std = @import("std");
const Connection = @import("../Connection.zig");
const common = @import("common.zig");

id: u32,

const Self = @This();

const Requests = enum(u8) {
    Destroy,
    GetToplevel,
    GetPopup,
    SetWindowGeometry,
    AckConfigure,
};
pub const Events = enum(u8) { Configure, _ };

pub fn destroy(self: *const Self, conn: *const Connection) !void {
    const header = common.Header{
        .id = self.id,
        .opcode = @intFromEnum(Requests.Destroy),
        .length = @sizeOf(common.Header),
    };

    try conn.writer.writeAll(std.mem.asBytes(&header));
    try conn.writer.flush();
}

pub const GetToplevelArgs = extern struct { id: u32 };
pub fn getToplevel(self: *const Self, conn: *const Connection, args: GetToplevelArgs) !u32 {
    const header = common.Header{
        .id = self.id,
        .opcode = @intFromEnum(Requests.GetToplevel),
        .length = @sizeOf(common.Header) + @sizeOf(GetToplevelArgs),
    };

    try conn.writer.writeAll(std.mem.asBytes(&header));
    try conn.writer.writeAll(std.mem.asBytes(&args));
    try conn.writer.flush();

    return args.id;
}

pub const GetPopupArgs = extern struct { id: u32, parent: u32, positioner: u32 };
pub fn getPopup(self: *const Self, conn: *const Connection, args: GetPopupArgs) !u32 {
    const header = common.Header{
        .id = self.id,
        .opcode = @intFromEnum(Requests.GetPopup),
        .length = @sizeOf(common.Header) + @sizeOf(GetPopupArgs),
    };

    try conn.writer.writeAll(std.mem.asBytes(&header));
    try conn.writer.writeAll(std.mem.asBytes(&args));
    try conn.writer.flush();

    return args.id;
}

pub const SetWindowGeometryArgs = extern struct {
    x: i32,
    y: i32,
    width: i32,
    height: i32,
};
pub fn setWindowGeometry(self: *const Self, conn: *const Connection, args: SetWindowGeometryArgs) !void {
    const header = common.Header{
        .id = self.id,
        .opcode = @intFromEnum(Requests.SetWindowGeometry),
        .length = @sizeOf(common.Header) + @sizeOf(SetWindowGeometryArgs),
    };

    try conn.writer.writeAll(std.mem.asBytes(&header));
    try conn.writer.writeAll(std.mem.asBytes(&args));
    try conn.writer.flush();
}

pub const AckConfigureArgs = extern struct { serial: u32 };
pub fn ackConfigure(self: *const Self, conn: *const Connection, args: AckConfigureArgs) !void {
    const header = common.Header{
        .id = self.id,
        .opcode = @intFromEnum(Requests.AckConfigure),
        .length = @sizeOf(common.Header) + @sizeOf(AckConfigureArgs),
    };

    try conn.writer.writeAll(std.mem.asBytes(&header));
    try conn.writer.writeAll(std.mem.asBytes(&args));
    try conn.writer.flush();
}

pub const ConfigureEvent = struct {
    serial: u32,

    pub fn format(self: *const ConfigureEvent, writer: *std.Io.Writer) !void {
        try writer.print("xdg_surface_configure_event: {{ serial: {d} }}", .{self.serial});
    }
};
pub fn handleConfigure(ev: []u8) common.Event {
    return common.Event{
        .xdg_surface_configure = ConfigureEvent{
            .serial = std.mem.readInt(u32, ev[0..@sizeOf(u32)], .little),
        },
    };
}
