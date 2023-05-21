module axi_stream_insert_header #(
        parameter DATA_WD = 32,
        parameter DATA_BYTE_WD = DATA_WD / 8,
        parameter BYTE_CNT_WD = $clog2(DATA_BYTE_WD)
) (
        input                                       clk             ,
        input                                       rst_n           ,
        // AXI Stream input original data   
        input                                       valid_in        ,
        input           [DATA_WD-1 : 0]             data_in         ,
        input           [DATA_BYTE_WD-1 : 0]        keep_in         ,
        input                                       last_in         ,
        output      reg                             ready_in        ,
        // AXI Stream output with header inserted   
        output      reg                             valid_out       ,
        output      reg [DATA_WD-1 : 0]             data_out        ,
        output      reg [DATA_BYTE_WD-1 : 0]        keep_out        ,
        output      wire                            last_out        ,
        input                                       ready_out       ,
        // The header to be inserted to AXI Stream input
        input                                       valid_insert    ,
        input           [DATA_WD-1 : 0]             data_insert     ,
        input           [DATA_BYTE_WD-1 : 0]        keep_insert     ,
        input           [BYTE_CNT_WD : 0]           byte_insert_cnt ,
        output      reg                             ready_insert
);
// Your code here


//reg define

reg      [0:7]                                data_regs [DATA_BYTE_WD - 1:0] ;      //字节寄存器
reg                                           ready_in_ff ;
reg                                           ready_in_ff2;  
reg                                           ready_insert_ff;
reg                                           ready_insert_ff2 ;
reg                                           ready_insert_ff3;
reg                                           last_in_ff ;
reg                                           last_in_ff2 ;
reg                                           last_in_ff3 ;
reg     [BYTE_CNT_WD  : 0]                    cnt_1 ;  
reg     [BYTE_CNT_WD  : 0]                    cnt_1_ff ;      
reg     [DATA_WD - 1 : 0]                     data_in_ff    ;
reg     [BYTE_CNT_WD : 0]                     vld_data_last ;               //data_out最后一拍的有效字节数
reg     [BYTE_CNT_WD+1 : 0]                   vld_sum ;


assign last_out = (vld_sum <= DATA_BYTE_WD) ? last_in_ff2 : last_in_ff3 ;


//计算一拍数据的有效字节数
integer i;
always @(*) begin
    cnt_1 = 'd0 ;
    for (i = 0 ; i < DATA_BYTE_WD ; i = i+1) begin
        if (keep_in[i] == 1)
            cnt_1 = cnt_1 + keep_in[i];
    end
end

integer t ;
always @(*) begin
    if (last_out) begin
       for (t = 0 ; t < DATA_BYTE_WD ; t = t+1) begin
        if (t >= (DATA_BYTE_WD - vld_data_last) && t < DATA_BYTE_WD)
            keep_out[t] = 1'b1 ;
        
        else
            keep_out[t] = 1'b0 ;
        end
    end
    else if (valid_out)
        keep_out <= {DATA_BYTE_WD{1'b1}};
end


//***************************相关信号打拍处理*************************************
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        ready_in_ff <= 1'b0 ;
    else
        ready_in_ff <= ready_in ; 
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        ready_in_ff2 <= 1'b0 ;
    else
        ready_in_ff2 <= ready_in_ff ; 
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        ready_insert_ff <= 1'b0 ;
    else
        ready_insert_ff <= ready_insert ; 
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        ready_insert_ff2 <= 1'b0 ;
    else
        ready_insert_ff2 <= ready_insert_ff ; 
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        ready_insert_ff3 <= 1'b0 ;
    else
        ready_insert_ff3 <= ready_insert_ff2 ; 
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        data_in_ff <= 'd0 ;
    else
        data_in_ff <= data_in ; 
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        last_in_ff <= 1'b0 ;
    else
        last_in_ff <= last_in ; 
end


always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        last_in_ff2 <= 1'b0 ;
    else
        last_in_ff2 <= last_in_ff ; 
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        last_in_ff3 <= 1'b0 ;
    else
        last_in_ff3 <= last_in_ff2 ; 
end


always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        cnt_1_ff <= 1'b0 ;
    else
        cnt_1_ff <= cnt_1 ; 
end
//***********************************************************

//保证每次处理过程只接收一拍head
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        ready_insert <= 1'b0 ;
    else if (ready_in || !ready_out)
        ready_insert <= 1'b0 ;
    else if (ready_out && valid_in && valid_insert)
        ready_insert <= 1'b1 ;
    else
        ready_insert <= ready_insert ; 
end



always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        ready_in <= 1'b0 ;
    else if (last_in || !ready_out)
        ready_in <= 1'b0 ;
    else if (ready_out && valid_in && valid_insert) 
        ready_in <= 1'b1 ;
    else
        ready_in <= ready_in ;
end


//拼接好的数据比输入数据延迟两拍输出
always @(posedge clk or negedge rst_n) begin 
    if(~rst_n) begin
        valid_out <= 'd0;
    end 
    else if (valid_in && ready_in_ff && ready_out)
        valid_out <= 1'b1;

    else
        valid_out <= 'd0 ;
end

//计算最后一拍数据的有效字节数，可以通过head和输入数据最后一拍有效字节数和与数据位宽的关系计算
always @(posedge clk or negedge rst_n) begin 
    if(~rst_n) begin
        vld_data_last <= 'd0;
    end 
    else if (last_in && (cnt_1 + byte_insert_cnt) <= DATA_BYTE_WD)
        vld_data_last <= cnt_1 + byte_insert_cnt ;
    else if (last_in)
        vld_data_last <=cnt_1 + byte_insert_cnt -DATA_BYTE_WD ;

    else
        vld_data_last <= vld_data_last ;
end

//head和输入数据最后一拍有效字节数和，以此判断last_out位置
always @(posedge clk or negedge rst_n) begin 
    if(~rst_n) begin
        vld_sum <= 'd0;
    end 
    else if (last_in)
        vld_sum <= cnt_1 + byte_insert_cnt ;

    else
        vld_sum <= vld_sum ;
end

//从字节寄存器中读出有效数据作为data_out
integer k;
always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        data_out <= 0;
    else if (valid_out && ready_out)
        for ( k = 0; k < DATA_BYTE_WD; k=k+1) begin
           data_out[((DATA_BYTE_WD-k)*8-1)-:8] <= data_regs[k]; 
        end
    else
        data_out <= data_out ;
end

//通过字节寄存器拼接寄存head+data的有效字节
genvar j;
generate for (j = 0 ; j < DATA_BYTE_WD ; j = j+1) begin
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_regs[j] <= 'd0;
        //寄存head有效内容
        else if (valid_insert && !ready_insert && ready_insert_ff && j >= 0 && j < byte_insert_cnt)
            data_regs[j] <= data_insert[DATA_WD - 1 - (DATA_BYTE_WD - byte_insert_cnt + j)*8 -: 8] ;
        //寄存完head有效内容后，若还有空位，寄存部分数据
        else if (valid_insert && !ready_insert && ready_insert_ff && j >= byte_insert_cnt && j < DATA_BYTE_WD)
            data_regs[j] <= data_in[DATA_WD -1 - (j - byte_insert_cnt)*8 -: 8] ;
        //继续寄存数据
        else if (valid_in && ready_in && last_in != 1'b1 && j >= byte_insert_cnt && j < DATA_BYTE_WD)
            data_regs[j] <= data_in[DATA_WD -1 - (j - byte_insert_cnt)*8 -: 8] ;
        else if (valid_in && ready_in && last_in != 1'b1 && j >= 0 && j < byte_insert_cnt)
            data_regs[j] <= data_in_ff[DATA_WD - 1 - (DATA_BYTE_WD - byte_insert_cnt + j)*8 -: 8] ;
        else if (valid_in && ready_in && last_in == 1'b1 && j >= 0 && j < byte_insert_cnt) 
            data_regs[j] <= data_in_ff[DATA_WD - 1 - (DATA_BYTE_WD - byte_insert_cnt + j)*8 -: 8] ;
        else if (valid_in && ready_in && last_in == 1'b1 && (DATA_BYTE_WD - byte_insert_cnt) >= cnt_1) begin
            if (j >= byte_insert_cnt && j < (byte_insert_cnt + cnt_1))
                data_regs[j] <= data_in[DATA_WD -1 - (j - byte_insert_cnt)*8 -: 8] ;
            else
                data_regs[j] <= 'd0 ;
        end
        else if (valid_in && ready_in && last_in == 1'b1 && (DATA_BYTE_WD - byte_insert_cnt) < cnt_1)
                data_regs[j] <= data_in[DATA_WD -1 - (j - byte_insert_cnt)*8 -: 8] ;
        else if (valid_in && ready_in_ff && last_in_ff == 1'b1 && (DATA_BYTE_WD - byte_insert_cnt) < cnt_1_ff && j >= 0 && j<(cnt_1_ff - DATA_BYTE_WD + byte_insert_cnt))
                data_regs[j] <= data_in_ff[DATA_WD - 1 - (DATA_BYTE_WD - byte_insert_cnt + j)*8 -: 8] ;

    end 
    end
endgenerate


//integer k;






endmodule