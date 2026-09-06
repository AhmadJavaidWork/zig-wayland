const std = @import("std");
const Connection = @import("../Connection.zig");
const common = @import("common.zig");

id: u32,

const Self = @This();

const Requests = enum(u8) { CreateSurface, CreateRegion, Release };
pub const Events = enum(u8) { _ };

const CreateSurfaceArgs = extern struct { id: u32 };
const CreateRegionArgs = extern struct { id: u32 };

pub fn create_surface(self: *const Self, conn: *const Connection, args: CreateSurfaceArgs) !u32 {
    const header = common.Header{
        .id = self.id,
        .opcode = @intFromEnum(Requests.CreateSurface),
        .length = @sizeOf(common.Header) + @sizeOf(CreateSurfaceArgs),
    };

    try conn.writer.writeAll(std.mem.asBytes(&header));
    try conn.writer.writeAll(std.mem.asBytes(&args));
    try conn.writer.flush();

    return args.id;
}

pub fn create_region(self: *const Self, conn: *const Connection, args: CreateRegionArgs) !u32 {
    const header = common.Header{
        .id = self.id,
        .opcode = @intFromEnum(Requests.CreateRegion),
        .length = @sizeOf(common.Header) + @sizeOf(CreateRegionArgs),
    };

    try conn.writer.writeAll(std.mem.asBytes(&header));
    try conn.writer.writeAll(std.mem.asBytes(&args));
    try conn.writer.flush();

    return args.id;
}

pub fn release(self: *const Self, conn: *const Connection) !void {
    const header = common.Header{
        .id = self.id,
        .opcode = @intFromEnum(Requests.CreateRegion),
        .length = @sizeOf(common.Header) + @sizeOf(CreateRegionArgs),
    };

    try conn.writer.writeAll(std.mem.asBytes(&header));
    try conn.writer.flush();
}
