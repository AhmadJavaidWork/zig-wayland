const std = @import("std");
const Connection = @import("../Connection.zig");
const common = @import("common.zig");
const utils = @import("../utils.zig");

id: u32,
globals: std.ArrayList(Global) = .empty,

const Self = @This();

const Requests = enum(u8) { Bind };
pub const Events = enum(u8) { Global, GlobalRemove, _ };

pub const GlobalType = struct {
    name: u32,
    interface: []u8,
    version: u32,

    pub fn format(self: *const GlobalType, writer: *std.Io.Writer) !void {
        try writer.print(
            "wl_registry_global_event: {{ name: {d}, interface: {s}, version: {d} }}",
            .{ self.name, self.interface, self.version },
        );
    }
};

pub const GlobalRemove = struct {
    id: u32,

    pub fn format(self: *const GlobalRemove, writer: *std.Io.Writer) !void {
        try writer.print("wl_registry_global_remove_event: {{ id: {d} }}", .{self.id});
    }
};

pub const Global = union(enum) {};

pub const BindArgs = extern struct {
    name: u32,
    id: u32,
};

pub fn bind(self: *const Self, conn: *const Connection, args: BindArgs) !void {
    const header = common.Header{
        .id = self.id,
        .opcode = @intFromEnum(Requests.Bind),
        .length = @sizeOf(common.Header) + @sizeOf(BindArgs),
    };

    try conn.writer.writeAll(std.mem.asBytes(&header));
    try conn.writer.writeAll(std.mem.asBytes(&args));
    try conn.writer.flush();
}

pub fn handleGlobal(allocator: std.mem.Allocator, ev: []u8) !common.Event {
    var offset: u32 = 0;
    const size_of_u32 = @sizeOf(u32);

    const name: u32 = std.mem.readInt(u32, ev[offset..size_of_u32][0..size_of_u32], .little);
    offset += size_of_u32;

    const interface_len: u32 = std.mem.readInt(u32, ev[offset .. offset + size_of_u32][0..size_of_u32], .little);
    const interface: []u8 = try allocator.dupe(u8, utils.takeString(ev, interface_len, &offset));

    const version: u32 = std.mem.readInt(u32, ev[offset .. offset + size_of_u32][0..size_of_u32], .little);

    return common.Event{
        .global = GlobalType{
            .name = name,
            .interface = interface,
            .version = version,
        },
    };
}

pub fn handleGlobalRemove(ev: []u8) common.Event {
    return common.Event{
        .global_remove = GlobalRemove{
            .id = std.mem.readInt(u32, ev[0..@sizeOf(u32)], .little),
        },
    };
}
