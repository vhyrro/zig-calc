const std = @import("std");
const io = std.io;

const parser = @import("./parser.zig");

pub fn main() !void {
    const stdout = io.getStdOut().writer();
    const stdin = io.getStdIn().reader();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    try stdout.writeAll("Enter your maths expression: ");

    var buffer: [50]u8 = undefined;

    var input = std.mem.trimRight(u8, (stdin.readUntilDelimiterOrEof(&buffer, '\n') catch |err| switch (err) {
        error.StreamTooLong => {
            std.log.err("Stream too long mate.", .{});
            return;
        },
        else => return,
    }).?, &.{ '\r', '\n' });

    const parsed_output = try parser.parse(allocator, input);

    switch (parsed_output) {
        .Ok => |ast| try io.getStdOut().writer().print("{any}", .{ast.items}),
        .Error => |err| try io.getStdErr().writer().print("Syntax error [char {}]: {s}.", .{ err.state.position + 1, @as([]const u8, switch (err.err) {
            parser.ParserErrorType.InvalidExpression => "Invalid expression. Expected one of: operator, operand, brackets",
            parser.ParserErrorType.MalformedFloatType => "Invalid float syntax used - more than one '.' char detected in the float",
        }) }),
    }
}
