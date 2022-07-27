const std = @import("std");

pub const SyntaxTree = std.ArrayList(Token);

pub const ParserState = struct {
    position: u32 = undefined,
    tokens: std.ArrayList(Token) = undefined,

    pub fn init(allocator: std.mem.Allocator) ParserState {
        return .{
            .position = 0,
            .tokens = std.ArrayList(Token).init(allocator),
        };
    }

    pub fn deinit(self: *ParserState) void {
        self.position = 0;
        self.tokens.deinit();
    }
};

pub const ParserErrorType = error{
    InvalidExpression, // When you have a symbol that isn't valid at all (e.g. `test + 3`)
    MalformedFloatType,
};

pub const ParserError = struct {
    state: ParserState,
    err: ParserErrorType,
};

pub fn Result(comptime ok: type, comptime err: type) type {
    return union(enum) {
        Ok: ok,
        Error: err,
    };
}

pub const Token = enum {
    Integer,
    Float,

    Plus,
    Minus,
    Multiply,
    Divide,

    Whitespace,
};

fn get_next_token(input: []const u8, state: *ParserState) !?Token {
    return switch (input[state.position]) {
        '0' ... '9' => integer_parse: {
            var resulting_token: Token = .Integer;
            // This is kinda hacky but it resets the position to the "expected"
            // state. Without this, the whitespace after the integer would also
            // be treated as part of the token.
            defer state.*.position -= 1;

            break :integer_parse while (state.position < input.len) : (state.*.position += 1) {
                switch (input[state.position]) {
                    '0' ... '9' => continue,
                    '.' => if (resulting_token != .Float) {
                        resulting_token = .Float;
                        continue;
                    } else return null,
                    else => return resulting_token,
                }
            } else .Integer;
        },
        '+' => .Plus,
        '-' => .Minus,
        '*' => .Multiply,
        '/' => .Divide,
        ' ', '\t' => .Whitespace,
        else => null,
    };
}

pub fn parse(allocator: std.mem.Allocator, input: []const u8) std.mem.Allocator.Error!Result(SyntaxTree, ParserError) {
    var state = ParserState.init(allocator);
    defer state.deinit();

    var ast = SyntaxTree.init(allocator);

    return while (state.position < input.len) : (state.position += 1) {
        try ast.append((get_next_token(input, &state) catch |err| break .{
            .err = err,
            .state = state,
        }) orelse break .{
            .Error = .{
                .err = ParserErrorType.InvalidExpression,
                .state = state,
            },
        });
    } else .{ .Ok = ast };
}
