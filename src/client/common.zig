const std = @import("std");
const WlDisplay = @import("WlDisplay.zig");
const WlRegistry = @import("WlRegistry.zig");
const WlCallback = @import("WlCallback.zig");
const WlShm = @import("WlShm.zig");
const XdgWmBase = @import("XdgWmBase.zig");
const WlSurface = @import("WlSurface.zig");
const XdgSurface = @import("XdgSurface.zig");
const XdgToplevel = @import("XdgToplevel.zig");

pub const Interfaces = enum(u16) {
    _padding,
    WlDisplay,
    WlRegistry,
    WlCallback,
    WlCompositor,
    WlShm,
    XdgWmBase,
    WlSurface,
    XdgSurface,
    XdgToplevel,
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
    wl_display_error: WlDisplay.ErrorEvent,
    wl_display_delete_id: WlDisplay.DeleteIdEvent,
    wl_registry_global: WlRegistry.GlobalEvent,
    wl_registry_global_remove: WlRegistry.GlobalRemoveEvent,
    wl_callback_done: WlCallback.DoneEvent,
    wl_shm_format: WlShm.FormatEvent,
    xdg_wm_base_ping: XdgWmBase.PingEvent,
    wl_surface_enter: WlSurface.EnterEvent,
    wl_surface_leave: WlSurface.LeaveEvent,
    wl_surface_preferred_buffer_scale: WlSurface.PreferredBufferScaleEvent,
    wl_surface_preferred_buffer_transform: WlSurface.PreferredBufferTransformEvent,
    xdg_surface_configure: XdgSurface.ConfigureEvent,
    xdg_toplevel_configure: XdgToplevel.ConfigureEvent,
    xdg_toplevel_close: XdgToplevel.CloseEvent,
    xdg_toplevel_configure_bounds: XdgToplevel.ConfigureBoundsEvent,
    xdg_toplevel_wm_capabilities: XdgToplevel.WmCapabilitiesEvent,

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
