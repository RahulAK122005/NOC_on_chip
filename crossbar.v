module crossbar #(
    parameter DATA_WIDTH = 32
)(
    // 5 input data buses from the FIFOs
    input  wire [DATA_WIDTH-1:0] in_north,
    input  wire [DATA_WIDTH-1:0] in_south,
    input  wire [DATA_WIDTH-1:0] in_east,
    input  wire [DATA_WIDTH-1:0] in_west,
    input  wire [DATA_WIDTH-1:0] in_local,

    // Select signals from Switch Allocator / Arbiter
    input  wire [2:0] sel_north,
    input  wire [2:0] sel_south,
    input  wire [2:0] sel_east,
    input  wire [2:0] sel_west,
    input  wire [2:0] sel_local,

    // 5 output data buses
    output reg [DATA_WIDTH-1:0] out_north,
    output reg [DATA_WIDTH-1:0] out_south,
    output reg [DATA_WIDTH-1:0] out_east,
    output reg [DATA_WIDTH-1:0] out_west,
    output reg [DATA_WIDTH-1:0] out_local
);

    // ------------------------------------------------
    // North Output MUX
    // ------------------------------------------------
    always @(*) begin
        case (sel_north)
            3'b000: out_north = in_north;
            3'b001: out_north = in_south;
            3'b010: out_north = in_east;
            3'b011: out_north = in_west;
            3'b100: out_north = in_local;
            default: out_north = {DATA_WIDTH{1'b0}};
        endcase
    end

    // ------------------------------------------------
    // South Output MUX
    // ------------------------------------------------
    always @(*) begin
        case (sel_south)
            3'b000: out_south = in_north;
            3'b001: out_south = in_south;
            3'b010: out_south = in_east;
            3'b011: out_south = in_west;
            3'b100: out_south = in_local;
            default: out_south = {DATA_WIDTH{1'b0}};
        endcase
    end

    // ------------------------------------------------
    // East Output MUX
    // ------------------------------------------------
    always @(*) begin
        case (sel_east)
            3'b000: out_east = in_north;
            3'b001: out_east = in_south;
            3'b010: out_east = in_east;
            3'b011: out_east = in_west;
            3'b100: out_east = in_local;
            default: out_east = {DATA_WIDTH{1'b0}};
        endcase
    end

    // ------------------------------------------------
    // West Output MUX
    // ------------------------------------------------
    always @(*) begin
        case (sel_west)
            3'b000: out_west = in_north;
            3'b001: out_west = in_south;
            3'b010: out_west = in_east;
            3'b011: out_west = in_west;
            3'b100: out_west = in_local;
            default: out_west = {DATA_WIDTH{1'b0}};
        endcase
    end

    // ------------------------------------------------
    // Local Output MUX
    // ------------------------------------------------
    always @(*) begin
        case (sel_local)
            3'b000: out_local = in_north;
            3'b001: out_local = in_south;
            3'b010: out_local = in_east;
            3'b011: out_local = in_west;
            3'b100: out_local = in_local;
            default: out_local = {DATA_WIDTH{1'b0}};
        endcase
    end

endmodule
