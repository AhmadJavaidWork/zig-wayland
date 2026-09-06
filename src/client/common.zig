const std = @import("std");
const WlDisplay = @import("WlDisplay.zig");
const WlRegistry = @import("WlRegistry.zig");
const WlCallback = @import("WlCallback.zig");
const WlShm = @import("WlShm.zig");
const XdgWmBase = @import("XdgWmBase.zig");
const WlSurface = @import("WlSurface.zig");

pub const Interfaces = enum(u16) {
    _padding,
    WlDisplay,
    WlRegistry,
    WlCallback,
    WlCompositor,
    WlShm,
    XdgWmBase,
    WlSurface,
};

pub const Header = extern struct {
    id: u32,
    opcode: u16,
    length: u16,
};

pub const Message = struct {
    sender: u32,
    event: Event,
};

pub const UnknownEvent = struct {
    data: []u8,

    const Self = @This();

    pub fn format(self: *const Self, writer: *std.Io.Writer) !void {
        try writer.print("unknown_event: {{ data: {any} }}", .{self.data});
    }
};

pub const Event = union(enum) {
    unknown: UnknownEvent,
    wl_display_error: WlDisplay.Error,
    wl_delete_id: WlDisplay.DeleteId,
    global: WlRegistry.Global,
    global_remove: WlRegistry.GlobalRemove,
    callback: WlCallback.Done,
    wl_shm_format: WlShm.Format,
    ping: XdgWmBase.Ping,
    enter: WlSurface.Enter,
    leave: WlSurface.Leave,
    preferred_buffer_scale: WlSurface.PreferredBufferScale,
    preferred_buffer_transform: WlSurface.PreferredBufferTransform,

    pub fn format(self: *const Event, writer: *std.Io.Writer) !void {
        try writer.flush();
        switch (self.*) {
            inline else => |payload| try payload.format(writer),
        }
    }
};

pub fn handleUnknownEvent(allocator: std.mem.Allocator, ev: []u8) !Event {
    return Event{
        .unknown = UnknownEvent{
            .data = try allocator.dupe(u8, ev),
        },
    };
}
