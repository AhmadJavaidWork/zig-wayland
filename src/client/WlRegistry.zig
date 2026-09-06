const std = @import("std");
const Connection = @import("../Connection.zig");
const common = @import("common.zig");
const utils = @import("../utils.zig");

id: u32,

const Self = @This();

const Requests = enum(u8) { Bind };
pub const Events = enum(u8) { Global, GlobalRemove, _ };

pub const GlobalType = struct {
    name: u32,
    version: u32,
};

pub const GlobalRemove = struct {
    id: u32,

    pub fn format(self: *const GlobalRemove, writer: *std.Io.Writer) !void {
        try writer.print("wl_registry_global_remove_event: {{ id: {d} }}", .{self.id});
    }
};

pub const Global = union(enum) {
    wl_compositor: GlobalType,
    wl_subcompositor: GlobalType,
    wp_viewporter: GlobalType,
    zxdg_output_manager_v1: GlobalType,
    wp_presentation: GlobalType,
    wp_single_pixel_buffer_manager_v1: GlobalType,
    wp_tearing_control_manager_v1: GlobalType,
    zwp_relative_pointer_manager_v1: GlobalType,
    zwp_pointer_constraints_v1: GlobalType,
    zwp_input_timestamps_manager_v1: GlobalType,
    weston_capture_v1: GlobalType,
    wl_data_device_manager: GlobalType,
    wl_shm: GlobalType,
    wl_eglstream_display: GlobalType,
    wl_drm: GlobalType,
    zwp_linux_dmabuf_v1: GlobalType,
    wl_seat: GlobalType,
    wl_output: GlobalType,
    zwp_input_panel_v1: GlobalType,
    zwp_input_method_v1: GlobalType,
    zwp_text_input_manager_v1: GlobalType,
    xdg_wm_base: GlobalType,
    weston_desktop_shell: GlobalType,
    zwp_primary_selection_device_manager_v1: GlobalType,
    gtk_shell1: GlobalType,
    wp_fractional_scale_manager_v1: GlobalType,
    zwp_pointer_gestures_v1: GlobalType,
    zwp_tablet_manager_v2: GlobalType,
    zxdg_exporter_v2: GlobalType,
    zxdg_importer_v2: GlobalType,
    zxdg_exporter_v1: GlobalType,
    zxdg_importer_v1: GlobalType,
    zwp_keyboard_shortcuts_inhibit_manager_v1: GlobalType,
    zwp_text_input_manager_v3: GlobalType,
    xdg_activation_v1: GlobalType,
    zwp_idle_inhibit_manager_v1: GlobalType,
    unknown_global: GlobalType,

    pub fn format(self: Global, writer: *std.Io.Writer) !void {
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

pub const BindArgs = struct { global: Global, id: u32 };

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
        GlobalType{
            .name = name,
            .version = version,
        },
    );

    return common.Event{ .global = global };
}

pub fn handleGlobalRemove(ev: []u8) common.Event {
    return common.Event{
        .global_remove = GlobalRemove{
            .id = std.mem.readInt(u32, ev[0..@sizeOf(u32)], .little),
        },
    };
}
