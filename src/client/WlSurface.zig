const std = @import("std");
const Connection = @import("../Connection.zig");
const common = @import("common.zig");
const WlOutput = @import("WlOutput.zig");

id: u32,

const Self = @This();

const Requests = enum(u8) {
    Destroy,
    Attach,
    Damage,
    Frame,
    SetOpaqueRegion,
    SetInputRegion,
    Commit,
    SetBufferTransform,
    SetBufferScale,
    DamageBuffer,
    Offset,
    GetRelease,
};
pub const Events = enum(u8) { Enter, Leave, PreferredBufferScale, PreferredBufferTransform, _ };

pub fn destroy(self: *const Self, conn: *const Connection) !void {
    const header = common.Header{
        .id = self.id,
        .opcode = @intFromEnum(Requests.Destroy),
        .length = @sizeOf(common.Header),
    };

    try conn.writer.writeAll(std.mem.asBytes(&header));
    try conn.writer.flush();
}

pub const AttachArgs = extern struct {
    buffer: u32,
    x: i32,
    y: i32,
};
pub fn attach(self: *const Self, conn: *const Connection, args: AttachArgs) !void {
    const header = common.Header{
        .id = self.id,
        .opcode = @intFromEnum(Requests.Attach),
        .length = @sizeOf(common.Header) + @sizeOf(AttachArgs),
    };

    try conn.writer.writeAll(std.mem.asBytes(&header));
    try conn.writer.writeAll(std.mem.asBytes(&args));
    try conn.writer.flush();
}

pub const DamageArgs = extern struct {
    x: i32,
    y: i32,
    width: i32,
    height: i32,
};
pub fn damage(self: *const Self, conn: *const Connection, args: DamageArgs) !void {
    const header = common.Header{
        .id = self.id,
        .opcode = @intFromEnum(Requests.Damage),
        .length = @sizeOf(common.Header) + @sizeOf(DamageArgs),
    };

    try conn.writer.writeAll(std.mem.asBytes(&header));
    try conn.writer.writeAll(std.mem.asBytes(&args));
    try conn.writer.flush();
}

pub const FrameArgs = extern struct { callback: u32 };
pub fn frame(self: *const Self, conn: *const Connection, args: FrameArgs) !u32 {
    const header = common.Header{
        .id = self.id,
        .opcode = @intFromEnum(Requests.Frame),
        .length = @sizeOf(common.Header) + @sizeOf(FrameArgs),
    };

    try conn.writer.writeAll(std.mem.asBytes(&header));
    try conn.writer.writeAll(std.mem.asBytes(&args));
    try conn.writer.flush();

    return args.callback;
}

pub const SetOpaqueRegionArgs = extern struct { region: u32 };
pub fn setOpaqueRegion(self: *const Self, conn: *const Connection, args: SetOpaqueRegionArgs) !void {
    const header = common.Header{
        .id = self.id,
        .opcode = @intFromEnum(Requests.SetOpaqueRegion),
        .length = @sizeOf(common.Header) + @sizeOf(SetOpaqueRegionArgs),
    };

    try conn.writer.writeAll(std.mem.asBytes(&header));
    try conn.writer.writeAll(std.mem.asBytes(&args));
    try conn.writer.flush();
}

pub const SetInputRegionArgs = extern struct { region: u32 };
pub fn setInputRegion(self: *const Self, conn: *const Connection, args: SetInputRegionArgs) !void {
    const header = common.Header{
        .id = self.id,
        .opcode = @intFromEnum(Requests.SetInputRegion),
        .length = @sizeOf(common.Header) + @sizeOf(SetInputRegionArgs),
    };

    try conn.writer.writeAll(std.mem.asBytes(&header));
    try conn.writer.writeAll(std.mem.asBytes(&args));
    try conn.writer.flush();
}

pub fn commit(self: *const Self, conn: *const Connection) !void {
    const header = common.Header{
        .id = self.id,
        .opcode = @intFromEnum(Requests.Commit),
        .length = @sizeOf(common.Header),
    };

    try conn.writer.writeAll(std.mem.asBytes(&header));
    try conn.writer.flush();
}

pub const SetBufferTransformArgs = extern struct { transform: WlOutput.Transform };
pub fn setBufferTransform(self: *const Self, conn: *const Connection, args: SetBufferTransformArgs) !void {
    const header = common.Header{
        .id = self.id,
        .opcode = @intFromEnum(Requests.SetBufferTransform),
        .length = @sizeOf(common.Header) + @sizeOf(SetBufferTransformArgs),
    };

    try conn.writer.writeAll(std.mem.asBytes(&header));
    try conn.writer.writeAll(std.mem.asBytes(&args));
    try conn.writer.flush();
}

pub const SetBufferScaleArgs = extern struct { scale: i32 };
pub fn setBufferScale(self: *const Self, conn: *const Connection, args: SetBufferScaleArgs) !void {
    const header = common.Header{
        .id = self.id,
        .opcode = @intFromEnum(Requests.SetBufferScale),
        .length = @sizeOf(common.Header) + @sizeOf(SetBufferScaleArgs),
    };

    try conn.writer.writeAll(std.mem.asBytes(&header));
    try conn.writer.writeAll(std.mem.asBytes(&args));
    try conn.writer.flush();
}

pub const DamageBufferArgs = extern struct {
    x: i32,
    y: i32,
    width: i32,
    height: i32,
};
pub fn damageBuffer(self: *const Self, conn: *const Connection, args: DamageBufferArgs) !void {
    const header = common.Header{
        .id = self.id,
        .opcode = @intFromEnum(Requests.DamageBuffer),
        .length = @sizeOf(common.Header) + @sizeOf(DamageBufferArgs),
    };

    try conn.writer.writeAll(std.mem.asBytes(&header));
    try conn.writer.writeAll(std.mem.asBytes(&args));
    try conn.writer.flush();
}

pub const OffsetArgs = extern struct { x: i32, y: i32 };
pub fn offset(self: *const Self, conn: *const Connection, args: OffsetArgs) !void {
    const header = common.Header{
        .id = self.id,
        .opcode = @intFromEnum(Requests.Offset),
        .length = @sizeOf(common.Header) + @sizeOf(OffsetArgs),
    };

    try conn.writer.writeAll(std.mem.asBytes(&header));
    try conn.writer.writeAll(std.mem.asBytes(&args));
    try conn.writer.flush();
}

pub const GetReleaseArgs = extern struct { callback: u32 };
pub fn getRelease(self: *const Self, conn: *const Connection, args: GetReleaseArgs) !u32 {
    const header = common.Header{
        .id = self.id,
        .opcode = @intFromEnum(Requests.GetRelease),
        .length = @sizeOf(common.Header) + @sizeOf(GetReleaseArgs),
    };

    try conn.writer.writeAll(std.mem.asBytes(&header));
    try conn.writer.writeAll(std.mem.asBytes(&args));
    try conn.writer.flush();

    return args.callback;
}

pub const EnterEvent = struct {
    wl_output: u32,

    pub fn format(self: *const EnterEvent, writer: *std.Io.Writer) !void {
        try writer.print("wl_surface_enter_event: {{ wl_output: {d} }}", .{self.wl_output});
    }
};
pub fn handleEnter(ev: []u8) common.Event {
    return common.Event{
        .wl_surface_enter = EnterEvent{
            .wl_output = std.mem.readInt(u32, ev[0..@sizeOf(u32)], .little),
        },
    };
}

pub const LeaveEvent = struct {
    wl_output: u32,

    pub fn format(self: *const LeaveEvent, writer: *std.Io.Writer) !void {
        try writer.print("wl_surface_leave_event: {{ wl_output: {d} }}", .{self.wl_output});
    }
};
pub fn handleLeave(ev: []u8) common.Event {
    return common.Event{
        .wl_surface_leave = LeaveEvent{
            .wl_output = std.mem.readInt(u32, ev[0..@sizeOf(u32)], .little),
        },
    };
}

pub const PreferredBufferScaleEvent = struct {
    factor: u32,

    pub fn format(self: *const PreferredBufferScaleEvent, writer: *std.Io.Writer) !void {
        try writer.print("wl_surface_preferred_buffer_scale_event: {{ factor: {d} }}", .{self.factor});
    }
};
pub fn handlePreferredBufferScale(ev: []u8) common.Event {
    return common.Event{
        .wl_surface_preferred_buffer_scale = PreferredBufferScaleEvent{
            .factor = std.mem.readInt(u32, ev[0..@sizeOf(u32)], .little),
        },
    };
}

pub const PreferredBufferTransformEvent = struct {
    transform: WlOutput.Transform,

    pub fn format(self: *const PreferredBufferTransformEvent, writer: *std.Io.Writer) !void {
        try writer.print("wl_surface_preferred_buffer_transform_event: {{ transform: {any} }}", .{self.transform});
    }
};
pub fn handlePreferredBufferTransform(ev: []u8) common.Event {
    return common.Event{
        .wl_surface_preferred_buffer_transform = PreferredBufferTransformEvent{
            .transform = @enumFromInt(std.mem.readInt(u32, ev[0..@sizeOf(u32)], .little)),
        },
    };
}
