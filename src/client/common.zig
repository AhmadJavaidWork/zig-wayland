const std = @import("std");
const WlDisplay = @import("WlDisplay.zig");

pub const Interfaces = enum(u16) {
    _padding,
    WlDisplay,
    WlRegistry,
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

    pub fn format(self: *const Event, writer: *std.Io.Writer) !void {
        try writer.flush();
        switch (self.*) {
            inline else => |payload| try payload.format(writer),
        }
    }
};

pub fn handleUnknownEvent(ev: []u8) Event {
    return Event{ .unknown = UnknownEvent{ .data = ev } };
}
