module timer_ip (
    input            clk,
    input            resetn,
    // Bus interface (matches SOC instantiation)
    input            sel,
    input            wr_en,
    input            rd_en,     // unused internally (combinational read), kept for interface match
    input      [1:0] addr,      // word offset: 00=CTRL 01=LOAD 10=VALUE 11=STATUS
    input      [31:0] wdata,
    output reg [31:0] rdata,
    // Output
    output           timeout_o
);
    // ------------------------------------------------------------
    // Register map (word offsets, matches mem_addr[3:2])
    // ------------------------------------------------------------
    localparam REG_CTRL  = 2'b00;  // 0x00
    localparam REG_LOAD  = 2'b01;  // 0x04
    localparam REG_VALUE = 2'b10;  // 0x08
    localparam REG_STAT  = 2'b11;  // 0x0C

    // ------------------------------------------------------------
    // Internal registers
    // ------------------------------------------------------------
    reg        en, mode, presc_en;
    reg [7:0]  presc_div;
    reg [31:0] load_reg;
    reg [31:0] value_reg;
    reg        timeout_flag;
    reg        en_prev;
    reg [7:0]  presc_cnt;

    assign timeout_o = timeout_flag;

    // ------------------------------------------------------------
    // Write logic — CTRL / LOAD (STATUS clear handled in core block)
    // ------------------------------------------------------------
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            en        <= 1'b0;
            mode      <= 1'b0;
            presc_en  <= 1'b0;
            presc_div <= 8'd0;
            load_reg  <= 32'd0;
        end else if (sel && wr_en) begin
            case (addr)
                REG_CTRL: begin
                    en        <= wdata[0];
                    mode      <= wdata[1];
                    presc_en  <= wdata[2];
                    presc_div <= wdata[15:8];
                end
                REG_LOAD: load_reg <= wdata;
                default: ; // REG_VALUE read-only, REG_STAT handled below
            endcase
        end
    end

    // ------------------------------------------------------------
    // Prescaler tick generation
    // ------------------------------------------------------------
    wire tick = en && (!presc_en || (presc_cnt == presc_div));

    always @(posedge clk or negedge resetn) begin
        if (!resetn) presc_cnt <= 8'd0;
        else if (!en)               presc_cnt <= 8'd0;
        else if (presc_en && tick)  presc_cnt <= 8'd0;
        else if (presc_en)          presc_cnt <= presc_cnt + 1'b1;
    end

    // ------------------------------------------------------------
    // Timer core: load-on-enable, countdown, sticky TIMEOUT,
    // write-1-to-clear
    // ------------------------------------------------------------
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            value_reg    <= 32'd0;
            timeout_flag <= 1'b0;
            en_prev      <= 1'b0;
        end else begin
            en_prev <= en;

            if (en && !en_prev) begin
                // Timer just started: load initial value
                value_reg <= load_reg;
            end else if (en && tick) begin
                if (value_reg == 32'd0) begin
                    timeout_flag <= 1'b1;
                    if (mode)
                        value_reg <= load_reg;   // periodic reload
                    // else: one-shot, VALUE stays 0, EN stays 1
                end else begin
                    value_reg <= value_reg - 1'b1;
                end
            end

            // Write-1-to-clear
            if (sel && wr_en && addr == REG_STAT && wdata[0])
                timeout_flag <= 1'b0;
        end
    end

    // ------------------------------------------------------------
    // Read logic
    // ------------------------------------------------------------
    always @(*) begin
        case (addr)
            REG_CTRL:  rdata = {16'b0, presc_div, 5'b0, presc_en, mode, en};
            REG_LOAD:  rdata = load_reg;
            REG_VALUE: rdata = value_reg;
            REG_STAT:  rdata = {31'b0, timeout_flag};
            default:   rdata = 32'b0;
        endcase
    end
endmodule
