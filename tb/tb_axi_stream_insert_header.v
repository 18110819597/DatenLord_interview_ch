`timescale  1ns / 1ps

module tb_axi_stream_insert_header; 

	parameter PERIOD = 10 ; 
	parameter DATA_WD = 32 ; 
	parameter DATA_BYTE_WD = DATA_WD / 8 ; 
	parameter BYTE_CNT_WD = $clog2(DATA_BYTE_WD);
	parameter DATA_SEND_SIZE = 8;
    
    // axi_stream_insert_header Inputs
    reg   clk                                = 0 ;
    reg   rst_n                              = 0 ;
    reg   valid_in                           = 1 ;
    reg   [DATA_WD-1 : 0]  data_in           = 0 ;
    reg   [DATA_BYTE_WD-1 : 0]  keep_in      = 0 ;
    reg   ready_out                          = 1 ;
    reg   valid_insert                       = 1 ;
    reg   [DATA_WD-1 : 0]  header_insert     = 0 ;
    reg   [DATA_BYTE_WD-1 : 0]  keep_insert  = 0 ;
    reg   [BYTE_CNT_WD : 0]  byte_insert_cnt = 0 ;
    
    // axi_stream_insert_header Outputs
    wire  ready_in                             	 ;
    wire  valid_out                            	 ;
    wire  [DATA_WD-1 : 0]  data_out            	 ;
    wire  [DATA_BYTE_WD-1 : 0]  keep_out       	 ;
    wire  last_out                             	 ;
    wire  ready_insert                         	 ;
    wire  last_in                              	 ;
    

initial begin
    rst_n = 0;
    clk = 0 ;
end

initial	begin
       forever #(PERIOD/2)  clk = ~clk;
end

//验证反压
//initial begin
//    #(PERIOD*100);
//    ready_out = 0;
//    #(PERIOD*150);
//    ready_out = 1;
//end

initial begin
       #(PERIOD*2) rst_n = 1;
	   #(PERIOD*200);
	   $finish;
end

integer seed;
initial begin	                                 
	seed = 2 ;
end

//计算byte_insert_cnt
always @(*) begin
    cnt_1(keep_insert,byte_insert_cnt) ;
end

//计算有效字节数的task
integer j ;
task cnt_1;
    input   [DATA_BYTE_WD-1 : 0]    keep ;
    output  [BYTE_CNT_WD : 0]       cnt ;

    begin
        cnt = 'd0 ;
        for (j = 0 ; j < DATA_BYTE_WD ; j = j+1) begin
            if (keep[j] == 1)
                cnt = cnt + keep[j];
        end
    end
endtask 


// 随机产生1拍header数据和随机的有效位信号
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        header_insert   =   'd0       ;
        keep_insert     =   'd0 ;
    end
    else if (valid_insert && ready_insert) begin
        header_insert   =   $random(seed)       ;
        keep_insert     =   {DATA_BYTE_WD{1'b1}} >> ({$random} % DATA_BYTE_WD);
    end
    else begin
        header_insert   =   header_insert       ;
        keep_insert     =   keep_insert;
    end
end
// 计数器cnt
reg [3:0]       cnt = 0 ;
always @(posedge clk or negedge rst_n)begin
    if(!rst_n)
        cnt <= 0 ;
    else if(cnt == (DATA_SEND_SIZE+1)) 
        cnt <= 0 ;
    else if(ready_in && cnt == 0)
        cnt <= cnt + 1 ;
    else if(ready_in && valid_in)
        cnt <= cnt + 1 ;
    
    else 
        cnt <= 'd0 ;
end

// 产生设置好size拍的data_in数据
always @(posedge clk or negedge rst_n)begin
    if(!rst_n)
        data_in <= 'd0 ;
    else if(ready_in && valid_in)
        data_in <= $random(seed);
    else 
        data_in <=  data_in ;
end



always @(*) begin
    if (ready_in && last_in != 1)
        keep_in <= {DATA_BYTE_WD{1'b1}};
    else if (ready_in ) 
        keep_in <= {DATA_BYTE_WD{1'b1}} << ({$random} % DATA_BYTE_WD);
    else
        keep_in <= 'd0 ;
end
// last_in:最后一拍数据
assign  last_in = (cnt == DATA_SEND_SIZE) ? 1: 0      ;


    
  
    axi_stream_insert_header #(
            .DATA_WD(DATA_WD),
            .DATA_BYTE_WD(DATA_BYTE_WD),
            .BYTE_CNT_WD(BYTE_CNT_WD)
        ) inst_axi_stream_insert_header (
            .clk             (clk),
            .rst_n           (rst_n),
            .valid_in        (valid_in),
            .data_in         (data_in [DATA_WD-1 : 0] ),
            .keep_in         (keep_in[DATA_BYTE_WD-1 : 0]),
            .last_in         (last_in),
            .ready_in        (ready_in),
            .valid_out       (valid_out),
            .data_out        (data_out[DATA_WD-1 : 0] ),
            .keep_out        (keep_out[DATA_BYTE_WD-1 : 0] ),
            .last_out        (last_out),
            .ready_out       (ready_out),
            .valid_insert    (valid_insert),
            .data_insert     (header_insert[DATA_WD-1 : 0]),
            .keep_insert     (keep_insert[DATA_BYTE_WD-1 : 0]),
            .byte_insert_cnt (byte_insert_cnt [BYTE_CNT_WD : 0] ),
            .ready_insert    (ready_insert)
        );


  


    
endmodule