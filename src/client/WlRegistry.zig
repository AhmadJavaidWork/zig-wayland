const std = @import("std");
const Connection = @import("../Connection.zig");
const common = @import("common.zig");
const utils = @import("../utils.zig");

id: u32,

const Self = @This();

const Requests = enum(u8) { Bind };
pub const Events = enum(u8) { Global, GlobalRemove, _ };

pub const BindArgs = struct { global: GlobalEvent, id: u32 };
pub fn bind(self: *const Self, conn: *const Connection, args: BindArgs) !u32 {
    const name = @tagName(args.global);
    const name_length = name.len + 1;
    const padded = std.mem.alignForward(usize, name_length, @sizeOf(u32));

    const wire_name_length: u32 = @intCast(name_length);
    const length: u16 = @intCast(@sizeOf(common.Header) + (4 * @sizeOf(u32)) + padded);

    const header = common.Header{
        .id = self.id,
        .opcode = @intFromEnum(Requests.Bind),
        .length = length,
    };

    try conn.writer.writeAll(std.mem.asBytes(&header));
    switch (args.global) {
        inline else => |v| {
            try conn.writer.writeAll(std.mem.asBytes(&v.name));
            try conn.writer.writeAll(std.mem.asBytes(&wire_name_length));
            try conn.writer.writeAll(name);
            _ = try conn.writer.splatByte(0, padded - name.len);
            try conn.writer.writeAll(std.mem.asBytes(&v.version));
        },
    }
    try conn.writer.writeAll(std.mem.asBytes(&args.id));
    try conn.writer.flush();

    return args.id;
}

pub const Global = struct {
    name: u32,
    version: u32,
};
pub const GlobalEvent = union(enum) {
    wl_compositor: Global,
    wl_subcompositor: Global,
    wp_viewporter: Global,
    zxdg_output_manager_v1: Global,
    wp_presentation: Global,
    wp_single_pixel_buffer_manager_v1: Global,
    wp_tearing_control_manager_v1: Global,
    zwp_relative_pointer_manager_v1: Global,
    zwp_pointer_constraints_v1: Global,
    zwp_input_timestamps_manager_v1: Global,
    weston_capture_v1: Global,
    wl_data_device_manager: Global,
    wl_shm: Global,
    wl_eglstream_display: Global,
    wl_drm: Global,
    zwp_linux_dmabuf_v1: Global,
    wl_seat: Global,
    wl_output: Global,
    zwp_input_panel_v1: Global,
    zwp_input_method_v1: Global,
    zwp_text_input_manager_v1: Global,
    xdg_wm_base: Global,
    weston_desktop_shell: Global,
    zwp_primary_selection_device_manager_v1: Global,
    gtk_shell1: Global,
    wp_fractional_scale_manager_v1: Global,
    zwp_pointer_gestures_v1: Global,
    zwp_tablet_manager_v2: Global,
    zxdg_exporter_v2: Global,
    zxdg_importer_v2: Global,
    zxdg_exporter_v1: Global,
    zxdg_importer_v1: Global,
    zwp_keyboard_shortcuts_inhibit_manager_v1: Global,
    zwp_text_input_manager_v3: Global,
    xdg_activation_v1: Global,
    zwp_idle_inhibit_manager_v1: Global,
    unknown_global: Global,

    pub fn format(self: GlobalEvent, writer: *std.Io.Writer) !void {
        try writer.flush();
        switch (self) {
            inline else => |g, tag| {
                const interface = @tagName(tag);
                try writer.print("wl_registry_global_event: {{ name: {d}, interface: {s}, version: {d} }}", .{
                    g.name,
                    interface,
                    g.version,
                });
            },
        }
    }
};
pub fn handleGlobal(ev: []u8) !common.Event {
    var offset: u32 = 0;
    const size_of_u32 = @sizeOf(u32);

    const name: u32 = std.mem.readInt(u32, ev[offset..size_of_u32][0..size_of_u32], .little);
    offset += size_of_u32;

    const interface_len: u32 = std.mem.readInt(u32, ev[offset .. offset + size_of_u32][0..size_of_u32], .little);
    offset += size_of_u32;

    const interface: []u8 = utils.takeString(ev, interface_len - 1, &offset);
    const version: u32 = std.mem.readInt(u32, ev[offset .. offset + size_of_u32][0..size_of_u32], .little);

    const global = utils.nameToGlobal(
        interface,
        Global{
            .name = name,
            .version = version,
        },
    );

    return common.Event{ .wl_registry_global = global };
}

pub const GlobalRemoveEvent = struct {
    id: u32,

    pub fn format(self: *const GlobalRemoveEvent, writer: *std.Io.Writer) !void {
        try writer.print("wl_registry_global_remove_event: {{ id: {d} }}", .{self.id});
    }
};
pub fn handleGlobalRemove(ev: []u8) common.Event {
    return common.Event{
        .wl_registry_global_remove = GlobalRemoveEvent{
            .id = std.mem.readInt(u32, ev[0..@sizeOf(u32)], .little),
        },
    };
}
