const std = @import("std");
const Connection = @import("../Connection.zig");
const common = @import("common.zig");

id: u32,

const Self = @This();

const Requests = enum(u8) {
    Destroy,
    SetParent,
    SetTitle,
    SetAppId,
    ShowWindowMenu,
    Move,
    Resize,
    SetMaxSize,
    SetMinSize,
    SetMaximized,
    UnsetMaximized,
    SetFullscreen,
    UnsetFullscreen,
    SetMinimized,
};

pub const Events = enum(u8) { Configure, Close, ConfigureBounds, WmCapabilities, _ };

pub const ResizeEdge = enum(u8) {
    None,
    Top,
    Bottom,
    Left,
    TopLeft,
    BottomLeft,
    Right,
    TopRight,
    BottomRight,
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

pub const SetParentArgs = extern struct { parent: u32 };
pub fn setParent(self: *const Self, conn: *const Connection, args: SetParentArgs) !void {
    const header = common.Header{
        .id = self.id,
        .opcode = @intFromEnum(Requests.SetParent),
        .length = @sizeOf(common.Header) + @sizeOf(SetParentArgs),
    };

    try conn.writer.writeAll(std.mem.asBytes(&header));
    try conn.writer.writeAll(std.mem.asBytes(&args));
    try conn.writer.flush();
}

pub const SetTitleArgs = struct { title: []const u8 };
pub fn setTitle(self: *const Self, conn: *const Connection, args: SetTitleArgs) !void {
    const title_length = args.title.len + 1;
    const padded = std.mem.alignForward(usize, title_length, @sizeOf(u32));

    const wire_title_length: u32 = @intCast(title_length);
    const length: u16 = @intCast(@sizeOf(common.Header) + @sizeOf(u32) + padded);

    const header = common.Header{
        .id = self.id,
        .opcode = @intFromEnum(Requests.SetTitle),
        .length = length,
    };

    try conn.writer.writeAll(std.mem.asBytes(&header));
    try conn.writer.writeAll(std.mem.asBytes(&wire_title_length));
    try conn.writer.writeAll(std.mem.bytesAsSlice(u8, args.title));
    _ = try conn.writer.splatByte(0, padded - args.title.len);
    try conn.writer.flush();
}

pub const SetAppIdArgs = struct { app_id: []const u8 };
pub fn setAppId(self: *const Self, conn: *const Connection, args: SetAppIdArgs) !void {
    const app_id_length = args.app_id.len + 1;
    const padded = std.mem.alignForward(usize, app_id_length, @sizeOf(u32));

    const wire_app_id_length: u32 = @intCast(app_id_length);
    const length: u16 = @intCast(@sizeOf(common.Header) + @sizeOf(u32) + padded);

    const header = common.Header{
        .id = self.id,
        .opcode = @intFromEnum(Requests.SetAppId),
        .length = length,
    };

    try conn.writer.writeAll(std.mem.asBytes(&header));
    try conn.writer.writeAll(std.mem.asBytes(&wire_app_id_length));
    try conn.writer.writeAll(std.mem.bytesAsSlice(u8, args.app_id));
    _ = try conn.writer.splatByte(0, padded - args.app_id.len);
    try conn.writer.flush();
}

pub const ShowWindowMenuArgs = extern struct {
    seat: u32,
    serial: u32,
    x: i32,
    y: i32,
};
pub fn showWindowMenu(self: *const Self, conn: *const Connection, args: ShowWindowMenuArgs) !void {
    const header = common.Header{
        .id = self.id,
        .opcode = @intFromEnum(Requests.ShowWindowMenu),
        .length = @sizeOf(common.Header) + @sizeOf(ShowWindowMenuArgs),
    };

    try conn.writer.writeAll(std.mem.asBytes(&header));
    try conn.writer.writeAll(std.mem.asBytes(&args));
    try conn.writer.flush();
}

pub const MoveArgs = extern struct { seat: u32, serial: u32 };
pub fn move(self: *const Self, conn: *const Connection, args: MoveArgs) !void {
    const header = common.Header{
        .id = self.id,
        .opcode = @intFromEnum(Requests.Move),
        .length = @sizeOf(common.Header) + @sizeOf(MoveArgs),
    };

    try conn.writer.writeAll(std.mem.asBytes(&header));
    try conn.writer.writeAll(std.mem.asBytes(&args));
    try conn.writer.flush();
}

pub const ResizeArgs = extern struct { seat: u32, serial: u32, edges: ResizeEdge };
pub fn resize(self: *const Self, conn: *const Connection, args: ResizeArgs) !void {
    const header = common.Header{
        .id = self.id,
        .opcode = @intFromEnum(Requests.Resize),
        .length = @sizeOf(common.Header) + @sizeOf(ResizeArgs),
    };

    try conn.writer.writeAll(std.mem.asBytes(&header));
    try conn.writer.writeAll(std.mem.asBytes(&args));
    try conn.writer.flush();
}

pub const SetMaxSizeArgs = extern struct { width: i32, height: i32 };
pub fn setMaxSize(self: *const Self, conn: *const Connection, args: SetMaxSizeArgs) !void {
    const header = common.Header{
        .id = self.id,
        .opcode = @intFromEnum(Requests.SetMaxSize),
        .length = @sizeOf(common.Header) + @sizeOf(SetMaxSizeArgs),
    };

    try conn.writer.writeAll(std.mem.asBytes(&header));
    try conn.writer.writeAll(std.mem.asBytes(&args));
    try conn.writer.flush();
}

pub const SetMinSizeArgs = extern struct { width: i32, height: i32 };
pub fn setMinSize(self: *const Self, conn: *const Connection, args: SetMinSizeArgs) !void {
    const header = common.Header{
        .id = self.id,
        .opcode = @intFromEnum(Requests.SetMinSize),
        .length = @sizeOf(common.Header) + @sizeOf(SetMinSizeArgs),
    };

    try conn.writer.writeAll(std.mem.asBytes(&header));
    try conn.writer.writeAll(std.mem.asBytes(&args));
    try conn.writer.flush();
}

pub fn setMaximized(self: *const Self, conn: *const Connection) !void {
    const header = common.Header{
        .id = self.id,
        .opcode = @intFromEnum(Requests.SetMaximized),
        .length = @sizeOf(common.Header),
    };

    try conn.writer.writeAll(std.mem.asBytes(&header));
    try conn.writer.flush();
}

pub fn unsetMaximized(self: *const Self, conn: *const Connection) !void {
    const header = common.Header{
        .id = self.id,
        .opcode = @intFromEnum(Requests.UnsetMaximized),
        .length = @sizeOf(common.Header),
    };

    try conn.writer.writeAll(std.mem.asBytes(&header));
    try conn.writer.flush();
}

pub const SetFullscreenArgs = extern struct { output: u32 };
pub fn setFullscreen(self: *const Self, conn: *const Connection, args: SetFullscreenArgs) !void {
    const header = common.Header{
        .id = self.id,
        .opcode = @intFromEnum(Requests.SetFullscreen),
        .length = @sizeOf(common.Header) + @sizeOf(SetFullscreenArgs),
    };

    try conn.writer.writeAll(std.mem.asBytes(&header));
    try conn.writer.writeAll(std.mem.asBytes(&args));
    try conn.writer.flush();
}

pub fn unsetFullscreen(self: *const Self, conn: *const Connection) !void {
    const header = common.Header{
        .id = self.id,
        .opcode = @intFromEnum(Requests.UnsetFullscreen),
        .length = @sizeOf(common.Header),
    };

    try conn.writer.writeAll(std.mem.asBytes(&header));
    try conn.writer.flush();
}

pub fn setMinimized(self: *const Self, conn: *const Connection) !void {
    const header = common.Header{
        .id = self.id,
        .opcode = @intFromEnum(Requests.SetMinimized),
        .length = @sizeOf(common.Header),
    };

    try conn.writer.writeAll(std.mem.asBytes(&header));
    try conn.writer.flush();
}

pub const ConfigureEvent = struct {
    width: i32,
    height: i32,
    states: []u8,

    pub fn format(self: *const ConfigureEvent, writer: *std.Io.Writer) !void {
        try writer.print("xdg_toplevel_configure_event: {{ width: {d}, height: {d}, states: {any} }}", .{
            self.width,
            self.height,
            self.states,
        });
    }
};
pub fn handleConfigure(allocator: std.mem.Allocator, ev: []u8) !common.Event {
    var offset: u32 = 0;
    const size_of_i32 = @sizeOf(i32);

    const width = std.mem.readInt(i32, ev[offset .. offset + size_of_i32][0..size_of_i32], .little);
    offset += size_of_i32;

    const height = std.mem.readInt(i32, ev[offset .. offset + size_of_i32][0..size_of_i32], .little);
    offset += size_of_i32;

    const array_length = std.mem.readInt(i32, ev[offset .. offset + size_of_i32][0..size_of_i32], .little);
    offset += size_of_i32;

    const states: []u8 = try allocator.alloc(u8, @intCast(array_length));
    var i: u32 = 0;
    while (i < array_length) : (i += 1) {
        states[i] = std.mem.readInt(u8, ev[offset .. offset + @sizeOf(u8)][0..@sizeOf(u8)], .little);
        offset += 1;
    }

    return common.Event{
        .xdg_toplevel_configure = ConfigureEvent{
            .width = width,
            .height = height,
            .states = states,
        },
    };
}

pub const CloseEvent = struct {
    pub fn format(self: *const CloseEvent, writer: *std.Io.Writer) !void {
        _ = self;
        try writer.print("xdg_toplevel_close_event", .{});
    }
};
pub fn handleClose() common.Event {
    return common.Event{
        .xdg_toplevel_close = CloseEvent{},
    };
}

pub const ConfigureBoundsEvent = struct {
    width: i32,
    height: i32,

    pub fn format(self: *const ConfigureBoundsEvent, writer: *std.Io.Writer) !void {
        try writer.print("xdg_toplevel_configure_bounds_event: {{ width: {d}, height: {d} }}", .{
            self.width,
            self.height,
        });
    }
};
pub fn handleConfigureBounds(ev: []u8) common.Event {
    var offset: u32 = 0;
    const size_of_i32 = @sizeOf(i32);

    const width = std.mem.readInt(i32, ev[offset .. offset + size_of_i32][0..size_of_i32], .little);
    offset += size_of_i32;

    const height = std.mem.readInt(i32, ev[offset .. offset + size_of_i32][0..size_of_i32], .little);

    return common.Event{
        .xdg_toplevel_configure_bounds = ConfigureBoundsEvent{
            .width = width,
            .height = height,
        },
    };
}

pub const WmCapabilities = enum(u32) {
    _padding,
    WindowMenu,
    Maximize,
    Fullscreen,
    Minimize,
};
pub const WmCapabilitiesEvent = struct {
    capabilities: []WmCapabilities,

    pub fn format(self: *const WmCapabilitiesEvent, writer: *std.Io.Writer) !void {
        try writer.print("xdg_toplevel_wm_capabilities_event: {{ capabilities: {any} }}", .{self.capabilities});
    }
};
pub fn handleWmCapabilities(allocator: std.mem.Allocator, ev: []u8) !common.Event {
    var offset: u32 = 0;
    const size_of_u32 = @sizeOf(u32);

    const array_length = (std.mem.readInt(u32, ev[offset .. offset + size_of_u32][0..size_of_u32], .little)) / size_of_u32;
    offset += size_of_u32;

    const capabilities: []WmCapabilities = try allocator.alloc(WmCapabilities, @intCast(array_length));
    var i: u32 = 0;

    while (i < array_length) : (i += 1) {
        const capability: u32 = std.mem.readInt(u32, ev[offset .. offset + size_of_u32][0..size_of_u32], .little);
        capabilities[i] = @enumFromInt(capability);
        offset += size_of_u32;
    }

    return common.Event{
        .xdg_toplevel_wm_capabilities = WmCapabilitiesEvent{
            .capabilities = capabilities,
        },
    };
}
