

           
set file_wave  ./wave.do


set wave_exist   [file exists $file_wave]



    quit -sim
    .main clear


    vlib ./lib/
    vlib ./lib/work

    vmap    work   ./lib/work
    vlog -f  ./rtl_cover.lst -cover bcesxf 


    vsim    -voptargs=+acc  work.tb_axi_stream_insert_header

#加信号
if {$wave_exist} {
    do wave.do
} else {
    add wave    -divider {tb_axi_stream_insert_header}
    add wave    tb_axi_stream_insert_header/*
}
    
log -r /*

#运行
    run 100us
