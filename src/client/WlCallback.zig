const std = @import("std");
const common = @import("common.zig");

id: u32,

const Self = @This();

pub const Events = enum(u8) { Done, _ };

pub const DoneEvent = struct {
    callback_data: u32,

    pub fn format(self: *const DoneEvent, writer: *std.Io.Writer) !void {
        try writer.print("wl_callback_done_event: {{ callback_data: {d} }}", .{self.callback_data});
    }
};
pub fn handleDone(ev: []u8) common.Event {
    return common.Event{
        .wl_callback_done = DoneEvent{
            .callback_data = std.mem.readInt(u32, ev[0..@sizeOf(u32)], .little),
        },
    };
}
