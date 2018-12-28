
module Device (
      // shared bus
      input clk ,
      input reset, 
      input cbe, // 1=read , 0=write
      inout [31:0] addressdata, // wire to bus of data and address 
      input [3:0] no_data ,//test bench stimulus to know when the read transaction will stop  
      inout frame,
      inout  i_ready,
      inout  t_ready,
      inout devSelect,
      output  request, 
      input[31:0]  forceadd,
      // per device
      input grant ,
      input[31:0] device_id,
//       input[31:0] init_mem_0,
//      input[31:0] init_mem_1,
//      input[31:0] init_mem_2,
//      input[31:0] init_mem_3,
//      input[31:0] init_mem_4,
//      input[31:0] init_mem_5,
//      input[31:0] init_mem_6,
//      input[31:0] init_mem_7,
//      input[31:0] init_mem_8,
//      input[31:0] init_mem_9,
      input force_request,
      output reg masterflag
		   // output frame_dub

);

assign request = force_request;

//* master phases
reg [15:0] master_phase;
reg [15:0] master_next_phase;
parameter  defaultt=16'h0010;
parameter  master=16'h0020;
parameter  requestadd= 16'h0000;
parameter predefault=16'h8888;
//* read phases
parameter  turn_around= 16'h0001;
parameter  data_phase1= 16'h0002;
parameter  data_phase2= 16'h0003;
parameter  data_phase3= 16'h0004;
parameter  data_phase4= 16'h0005;
parameter  data_phase5= 16'h0006;
parameter  data_phase6= 16'h0007;
parameter  data_phase7= 16'h0008;
parameter  data_phase8= 16'h0009;
parameter  data_phase9= 16'h000a;
parameter  data_phase10 = 16'h000b;
parameter  beforefinsih = 16'h001b;
parameter  finish =16'h0011;

//*Master write phases
parameter write_phase10=16'h1000;
parameter write_phase1=16'h1001;
parameter write_phase2=16'h1002;
parameter write_phase3=16'h1003;
parameter write_phase4=16'h1004;
parameter write_phase5=16'h1005;
parameter write_phase6=16'h1006;
parameter write_phase7=16'h1007;
parameter write_phase8=16'h1008;
parameter write_phase9=16'h1009;
parameter finishwrite=16'h1099;
parameter beforefinsihwrite=16'h1100;

//*target phases
reg [15:0] target_phase;
reg [15:0] target_next_phase;
parameter  default_target=16'hbbbb;
parameter  readadd= 16'h0000;
parameter  turn_around_target= 16'h0001;
parameter  target_data_phase1= 16'h0002;
parameter  target_data_phase2= 16'h0003;
parameter  target_data_phase3= 16'h0004;
parameter  target_data_phase4= 16'h0005;
parameter  target_data_phase5= 16'h0006;
parameter  target_data_phase6= 16'h0007;
parameter  target_data_phase7= 16'h0002;
parameter  target_data_phase8= 16'h0008;
parameter  target_data_phase9= 16'h0009;
parameter  target_data_phase10= 16'h000a;
parameter  target_finish =16'h0011;
parameter write_phase_target=16'h1000;

//*Target write phases
parameter  target_read1 = 16'h1101;
parameter  target_read2 = 16'h1102;
parameter  target_read3 = 16'h1103;
parameter  target_read4 = 16'h1104;
parameter  target_read5 = 16'h1105;
parameter  target_read6 = 16'h1106;
parameter  target_read7 = 16'h1107;
parameter  target_read8 = 16'h1108;
parameter  target_read9 = 16'h1109;
parameter  target_read10 = 16'h11010;
parameter target_read_before_finish = 16'h1111;

//* registers for master (initiator) & target(slave)
reg targetflag;
//reg masterflag;

// 32-bit data-address bus register 
reg[31:0] dataadd;
assign addressdata = dataadd;

reg iframe;
reg tready,iready,deviceselect;

assign frame = (masterflag) ? iframe : 1'bz;
assign i_ready=(masterflag)?iready:1'bz;
assign t_ready=(targetflag)?tready:1'bz;
assign devSelect=(targetflag)? deviceselect:1'bz;
//* define the memory 
reg [31:0] mem [0:9] ;


//*  switching from one phase to another on rising clock edges
always @(posedge clk)
begin
      master_phase <= master_next_phase;
      target_phase <= target_next_phase;
end


always @(!reset)
begin
     //* reset state to intialize the bus     
     
    iready<=1'bz;
    tready<=1'bz;
    deviceselect<=1'bz;
    master_next_phase<=predefault;
    target_next_phase<=default_target;
    masterflag<=0;
    targetflag<=0;
    dataadd<=32'hz;
    iframe<=1;
    if (device_id == 32'h00000000)
    begin
      mem [0] <= 32'hAAAAAAAA;
      mem [1] <= 32'hAAAAAAAA;
      mem [2] <= 32'hAAAAAAAA;
      mem [3] <= 32'hAAAAAAAA;
      mem [4] <= 32'hAAAAAAAA;
      mem [5] <= 32'hAAAAAAAA;
      mem [6] <= 32'hAAAAAAAA;
      mem [7] <= 32'hAAAAAAAA;
      mem [8] <= 32'hAAAAAAAA;
      mem [9] <= 32'hAAAAAAAA;
    end
    else if (device_id == 32'h00000001)
    begin
      mem [0] <= 32'hBBBBBBBB;
      mem [1] <= 32'hBBBBBBBB;
      mem [2] <= 32'hBBBBBBBB;
      mem [3] <= 32'hBBBBBBBB;
      mem [4] <= 32'hBBBBBBBB;
      mem [5] <= 32'hBBBBBBBB;
      mem [6] <= 32'hBBBBBBBB;
      mem [7] <= 32'hBBBBBBBB;
      mem [8] <= 32'hBBBBBBBB;
      mem [9] <= 32'hBBBBBBBB;
    end
    else 
    begin
      mem [0] <= 32'hCCCCCCCC;
      mem [1] <= 32'hCCCCCCCC;
      mem [2] <= 32'hCCCCCCCC;
      mem [3] <= 32'hCCCCCCCC;
      mem [4] <= 32'hCCCCCCCC;
      mem [5] <= 32'hCCCCCCCC;
      mem [6] <= 32'hCCCCCCCC;
      mem [7] <= 32'hCCCCCCCC;
      mem [8] <= 32'hCCCCCCCC;
      mem [9] <= 32'hCCCCCCCC;
    end
end

always@(posedge clk)
begin
    
     if(!grant & iframe)
        begin
        masterflag<=1;
        targetflag<=0; 
		end
		
		 case(master_next_phase)
      //*default where we check the frame and grant  to know the master device
	/*predefault:
		begin
            if(masterflag==1)
                    master_next_phase<=defaultt;
            else
                    master_next_phase<=predefault;
		end*/

	predefault: 
      begin
        if(masterflag==1)
        begin
          @(negedge clk)
            begin
                iframe<=0;
                iready<=1'b1;
                dataadd<=forceadd; //address asserted
                if(cbe) //read operation 
                    master_next_phase<=turn_around;
                else
                    master_next_phase<=write_phase1;
                
            end
        end
        else
            master_next_phase<=predefault;   
      end
      
      //*this phase is responsible for putting the address of the slave on the data bus and
      //* check the operation (read) or (write)
      write_phase1: 
      begin
            @(negedge clk)
            begin
                  dataadd<=mem[0];
                  iready<=0;
                  if (no_data == 0+1)
                  begin
                        iframe <= 1;
                        master_next_phase<=finishwrite;
                  end     
                  else
                        master_next_phase<=write_phase2;
            end
      end

      write_phase2:
      begin		
            @(negedge clk)
            begin      
                  if(!iready && !t_ready && !devSelect)
                 begin
                        dataadd<=mem[1];
                        if (no_data == 1+1)
                        begin
                              iframe <= 1;
                              master_next_phase<=finishwrite;
                       end     
                        else
                        master_next_phase<=write_phase3;
                  end
                  else  
                        master_next_phase<=write_phase2;
            end
      end
      
      write_phase3:
      begin
            @(negedge clk)
            begin
                  if(!iready && !t_ready && !devSelect)
                 begin
                        dataadd<=mem[2];
                        if(no_data==2+1)
                        begin
                              iframe <= 1;
                              master_next_phase<=finishwrite;
                        end
                       else
                         master_next_phase<=write_phase4;
                  end
                  else  master_next_phase<=write_phase3;
            end
      end

      write_phase4:
      begin
      @(negedge clk)
      begin
             if(!iready && !t_ready && !devSelect)
               begin
                    dataadd<=mem[3];
                     if(no_data==3+1)
                        begin
                              iframe <= 1;
                              master_next_phase<=finishwrite;
                        end
                        else
                         master_next_phase<=write_phase5;
                end
            else  master_next_phase<=write_phase4;
      end
      end

      write_phase5:
      begin
      @(negedge clk)
      begin
             if(!iready && !t_ready && !devSelect)
                begin
                    dataadd<=mem[4];
                     if(no_data==4+1)
                        begin
                              iframe <= 1;
                              master_next_phase<=finishwrite;
                        end
                        else
                              master_next_phase<=write_phase6;
                end
             else  master_next_phase<=write_phase5;
      end
      end

      write_phase6:
      begin
            @(negedge clk)
            begin
                  if(!iready && !t_ready && !devSelect)
                  begin
                        dataadd<=mem[5];
                         if(no_data==5+1)
                        begin
                              iframe <= 1;
                              master_next_phase<=finishwrite;
                        end
                        else
                              master_next_phase<=write_phase7;
                  end
                  else  master_next_phase<=write_phase6;
            end
      end

      write_phase7:
      begin
      @(negedge clk)
      begin
             if(!iready && !t_ready && !devSelect)
                begin
                    dataadd<=mem[6];
                     if(no_data==6+1)
                        begin
                              iframe <= 1;
                              master_next_phase<=finishwrite;
                        end
                        else
                               master_next_phase<=write_phase8;
                end
            else  master_next_phase<=write_phase7;
        end
      end

      write_phase8:
      begin
      @(negedge clk)
      begin
             if(!iready && !t_ready && !devSelect)
                begin
                    dataadd<=mem[7];
                     if(no_data==7+1)
                        begin
                              iframe <= 1;
                              master_next_phase<=finishwrite;
                        end
                        else
                               master_next_phase<=write_phase9;
                end
            else  master_next_phase<=write_phase8;
        end
      end

      write_phase9:
      begin
      @(negedge clk)
      begin
             if(!iready && !t_ready && !devSelect)
                begin
                    dataadd<=mem[8];
                     if(no_data==8+1)
                        begin
                              iframe <= 1;
                              master_next_phase<=finishwrite;
                        end
                        else
                              master_next_phase<=write_phase10;
                end
            else  master_next_phase<=write_phase9;
        end
      end

      write_phase10:
      begin
      @(negedge clk)
      begin
             if(!iready && !t_ready && !devSelect)
                begin
                    dataadd<=mem[9];
                    master_next_phase<=finishwrite;
                end
            else  master_next_phase<=write_phase10;
        end
      end

      finishwrite:
      begin
            @(negedge clk)
            begin
            dataadd<=32'bz;
            iready <=1;
            master_next_phase<=predefault; 
				masterflag<=0;
            end  
      end

     //*this phase happens when master leaves the databus to the slave so it can write data on it 
      turn_around:
      begin
            @(negedge clk)
            begin
                  iready<=0;
                  dataadd<=32'hz;
                  master_next_phase<=data_phase1;
            end
      end
      
      //*first phase for target reading data
      data_phase1:
      begin
        mem[0]<=addressdata;
            @(negedge clk)
            begin 
                        if(!devSelect && !t_ready && !iready && !frame)
                        begin 
                              //*this if to check if this is the last data transaction will happen 
                              if(no_data==0+1)  
                                    begin
                                    iframe<=1;
                                    master_next_phase<=beforefinsih;
                                    end
                              else
                              master_next_phase<=data_phase2;
                        end

                        else
                              begin
                                 master_next_phase<=data_phase1;
                              end
            end
      end

      data_phase2:
      begin
            if(!devSelect && !t_ready && !iready && !frame)
            begin
                        //on the posedge you will need to read the data from the databus and save it in the memory
                        mem[1]<=addressdata;
                @(negedge clk)
                begin  
                        if(!devSelect && !t_ready && !iready && !frame)
                        begin
                              if(no_data==1+1)
                                    begin
                                    iframe<=1;
                                    master_next_phase<=beforefinsih;
                                    end
                              else
                              master_next_phase<=data_phase3;
                        end
                         else
                              begin
                                 master_next_phase<=data_phase2;
                              end
                end 
            end
      end 

      data_phase3:
      begin
            if(!devSelect && !t_ready && !iready && !frame)
            begin
                        mem[2]<=addressdata;
                @(negedge clk)
                begin  
                        if(!devSelect && !t_ready && !iready && !frame)
                        begin
                              if(no_data==2+1)
                                    begin
                                    iframe<=1;
                                    master_next_phase<=beforefinsih;
                                    end
                              else
                              master_next_phase<=data_phase4;
                        end
                         else
                              begin
                                 master_next_phase<=data_phase3;
                              end
                end 
            end
      end    
      data_phase4:
      begin
            if(!devSelect && !t_ready && !iready && !frame)
            begin
                        mem[3]<=addressdata;
                @(negedge clk)
                begin  
                        if(!devSelect && !t_ready && !iready && !frame)
                        begin
                              if(no_data==3+1)
                                    begin
                                    iframe<=1;
                                    master_next_phase<=beforefinsih;
                                    end
                              else
                              master_next_phase<=data_phase5;
                        end
                         else
                              begin
                                 master_next_phase<=data_phase4;
                              end
                end 
            end
      end  

      data_phase5:
      begin
            if(!devSelect && !t_ready && !iready && !frame)
            begin
                        mem[4]<=addressdata;
                @(negedge clk)
                begin  
                        if(!devSelect && !t_ready && !iready && !frame)
                        begin
                              if(no_data==4+1)
                                    begin
                                    iframe<=1;
                                    master_next_phase<=beforefinsih;
                                    end
                              else
                              master_next_phase<=data_phase6;
                        end
                         else
                              begin
                                 master_next_phase<=data_phase5;
                              end
                end 
            end
      end 

      data_phase6:
      begin
            if(!devSelect && !t_ready && !iready && !frame)
            begin
                        mem[5]<=addressdata;
                @(negedge clk)
                begin  
                        if(!devSelect && !t_ready && !iready && !frame)
                        begin
                              if(no_data==5+1)
                                    begin
                                    iframe<=1;
                                    master_next_phase<=beforefinsih;
                                    end
                              else
                              master_next_phase<=data_phase7;
                        end
                         else
                              begin
                                 master_next_phase<=data_phase6;
                              end
                end 
            end
      end    

      data_phase7:
      begin
            if(!devSelect && !t_ready && !iready && !frame)
            begin
                        mem[6]<=addressdata;
                @(negedge clk)
                begin  
                        if(!devSelect && !t_ready && !iready && !frame)
                        begin
                              if(no_data==6+1)
                                    begin
                                    iframe<=1;
                                    master_next_phase<=beforefinsih;
                                    end
                              else
                              master_next_phase<=data_phase8;
                        end
                         else
                              begin
                                 master_next_phase<=data_phase7;
                              end
                end 
            end
      end 

      data_phase8:
      begin
            if(!deviceselect && !tready && !iready && !iframe)
            begin
                        mem[7]<=addressdata;
                @(negedge clk)
                begin  
                        if(!devSelect && !t_ready && !iready && !frame)
                        begin
                              if(no_data==7+1)
                                    begin
                                    iframe<=1;
                                    master_next_phase<=beforefinsih;
                                    end
                              else
                              master_next_phase<=data_phase9;
                        end
                         else
                              begin
                                 master_next_phase<=data_phase8;
                              end
                end 
            end
      end   

      data_phase9:
      begin
           if(!deviceselect && !tready && !iready && !iframe)
            begin
                        mem[8]<=addressdata;
                @(negedge clk)
                begin  
                        if(!devSelect && !t_ready && !iready && !frame)
                        begin
                              if(no_data==8+1)
                                    begin
                                    iframe<=1;
                                    master_next_phase<=beforefinsih;
                                    end
                              else
                              master_next_phase<=data_phase10;
                        end
                         else
                              begin
                                 master_next_phase<=data_phase9;
                              end
                end 
            end
      end    
      
      data_phase10:
      begin
            if(!devSelect && !t_ready && !iready && !frame)
            begin
                  @(negedge clk)
                  begin
                        iframe<=1;
                        master_next_phase<=beforefinsih;
                  end
            end
      end   

      //* all signals are asserted high again to get ready for new transactions
      beforefinsih:
      begin
            if(!devSelect && !t_ready && !iready)
            begin
                  mem[no_data-1]<=addressdata;
                  @(negedge clk)
                  begin
                        iready<=1;
                        dataadd <= 32'hz;
                        master_next_phase <= finish;
                  end
            end
      end  
    
    //* a turnaround phase after data transactions
      finish:
      begin
            master_next_phase <= defaultt;
      end                    
    
    endcase


end
always @ (posedge clk)
begin
      case(target_next_phase)
      
        default_target:
      begin
        //targetflag<=0;
        if (frame)
        begin
        @ (negedge frame)
            target_next_phase <= readadd;
        end 
        else
            target_next_phase <= default_target;        
      end
      
      readadd:
      begin
            if (forceadd == device_id)
            begin
                targetflag <=1;
                if (cbe)
                 target_next_phase <= turn_around_target;
                else
                begin
                    target_next_phase<= target_read1;
                    @(negedge clk)
                    begin
                        tready <= 0;
                        deviceselect<=0;
                    end
                end
            end      
      end
      
      turn_around_target:
      begin
        target_next_phase <= target_data_phase1;
      end

      target_data_phase1:
      begin
        @ (negedge clk)
            begin
                  if (!frame)
                  begin
                        tready <= 0;
                        deviceselect <=0;
                        dataadd <= mem[0];
                        if (!i_ready)
                              if (no_data == 1)
                              target_next_phase <= target_finish;
                              else
                              target_next_phase <= target_data_phase2;
                        else 
                        target_next_phase <= target_data_phase1;
                  end
                  else 
                  target_next_phase <= default_target; 
            end          
                    
      end

      target_data_phase2:
      begin
      @(negedge clk)
      begin
            if(!frame)
            begin
            dataadd <= mem[1];
                  if (!i_ready)
                        if (no_data == 2)
                           target_next_phase <= target_finish;
                         else
                           target_next_phase <= target_data_phase3;
                  else 
                  target_next_phase <= target_data_phase2;
            end
            else 
                  target_next_phase <= default_target;
       end
      end
      
      target_data_phase3:
      begin
       @(negedge clk)
      begin
            if(!frame)
            begin
            dataadd <= mem[2];
                  if (!i_ready)
                        if (no_data == 3)
                           target_next_phase <= target_finish;
                         else
                           target_next_phase <= target_data_phase4;
                  else 
                  target_next_phase <= target_data_phase3;
            end
            else 
                  target_next_phase <= default_target;
       end
      end

      target_data_phase4:
      begin
      @(negedge clk)
      begin
            if(!frame)
            begin
            dataadd <= mem[3];
                  if (!i_ready)
                        if (no_data == 4)
                           target_next_phase <= target_finish;
                         else
                           target_next_phase <= target_data_phase5;
                  else 
                  target_next_phase <= target_data_phase4;
            end
            else 
                  target_next_phase <= default_target;
       end
      end       

      target_data_phase5:
      begin
      @(negedge clk)
      begin
            if(!frame)
            begin
            dataadd <= mem[4];
                  if (!i_ready)
                        if (no_data == 5)
                           target_next_phase <= target_finish;
                         else
                           target_next_phase <= target_data_phase6;
                  else 
                  target_next_phase <= target_data_phase5;
            end
            else 
                  target_next_phase <= default_target;
       end
      end

      target_data_phase6:
      begin
      @(negedge clk)
      begin
            if(!frame)
            begin
            dataadd <= mem[5];
                  if (!i_ready)
                        if (no_data == 6)
                           target_next_phase <= target_finish;
                         else
                           target_next_phase <= target_data_phase7;
                  else 
                  target_next_phase <= target_data_phase6;
            end
            else 
                  target_next_phase <= default_target;
       end
      end

      target_data_phase7:
      begin
      @(negedge clk)
      begin
            if(!frame)
            begin
            dataadd <= mem[6];
                  if (!i_ready)
                        if (no_data == 7)
                           target_next_phase <= target_finish;
                         else
                           target_next_phase <= target_data_phase8;
                  else 
                  target_next_phase <= target_data_phase7;
            end
            else 
                  target_next_phase <= default_target;
       end   
      end

      target_data_phase8:
      begin
      @(negedge clk)
      begin
            if(!frame)
            begin
            dataadd <= mem[7];
                  if (!i_ready)
                        if (no_data == 8)
                           target_next_phase <= target_finish;
                         else
                           target_next_phase <= target_data_phase9;
                  else 
                  target_next_phase <= target_data_phase8;
            end
            else 
                  target_next_phase <= default_target;
       end
      end

      target_data_phase9:
      begin
      @(negedge clk)
      begin
            if(!frame)
            begin
            dataadd <= mem[8];
                  if (!i_ready)
                        if (no_data == 9)
                           target_next_phase <= target_finish;
                         else
                           target_next_phase <= target_data_phase10;
                  else 
                  target_next_phase <= target_data_phase9;
            end
            else 
                  target_next_phase <= default_target;
       end
      end

      target_data_phase10:
      begin
      @(negedge clk)
      begin
            if(!frame)
            begin
            dataadd <= mem[9];
                  if (!i_ready)
                  target_next_phase <= target_finish;    
                  else 
                  target_next_phase <= target_data_phase10;
            end
            else 
                  target_next_phase <= default_target;
       end
      end

     
 
    target_finish:
      begin
        @(negedge clk)
        begin
            tready<=1;
            deviceselect<=1;
            dataadd <= 32'hz;
            target_next_phase <= default_target;
        end
      end
      
      target_read1:
      begin
            mem[0]<=addressdata;
            if (no_data>1)
            begin
                if (!deviceselect && !tready && !i_ready)
                  target_next_phase <= target_read2;
                 else 
                    target_next_phase <= target_read1;
            end
            else
            begin
                @(negedge clk)
                begin
                    tready<=1;
                    deviceselect<=1;
                    dataadd <= 32'hz;
                    target_next_phase <= default_target;
                end  
            end                       
      end     

      target_read2:
      begin
            mem[1]<=addressdata;
            if (no_data>2)
            begin
                if (!deviceselect && !tready && !i_ready)
                  target_next_phase <= target_read3;
                else 
                  target_next_phase <= target_read2;
            end
            else
            begin
                @(negedge clk)
                begin
                    tready<=1;
                    deviceselect<=1;
                    dataadd <= 32'hz;
                    target_next_phase <= default_target;
                end  
            end                       
      end    

      target_read3:
      begin
                    
             mem[2]<=addressdata;
            if (no_data>3)
            begin
                  if (!deviceselect && !tready && !i_ready)
                  target_next_phase <= target_read4;
                  else 
                  target_next_phase <= target_read3;
            end
            else
            begin
                @(negedge clk)
                begin
                    tready<=1;
                    deviceselect<=1;
                    dataadd <= 32'hz;
                    target_next_phase <= default_target;
                end  
            end                       
      end    

      target_read4:
      begin
            mem[3]<=addressdata;
            if (no_data>4)
            begin
                  if (!deviceselect && !tready && !i_ready)
                  target_next_phase <= target_read5;
                  else 
                  target_next_phase <= target_read4;
            end
             else
            begin
                @(negedge clk)
                begin
                    tready<=1;
                    deviceselect<=1;
                    dataadd <= 32'hz;
                    target_next_phase <= default_target;
                end  
            end                       
      end    

      target_read5:
      begin
            mem[4]<=addressdata;
            if (no_data>5)
            begin
                  if (!deviceselect && !tready && !i_ready)
                  target_next_phase <= target_read6;
                  else 
                  target_next_phase <= target_read5;
            end
             else
            begin
                @(negedge clk)
                begin
                    tready<=1;
                    deviceselect<=1;
                    dataadd <= 32'hz;
                    target_next_phase <= default_target;
                end  
            end                       
      end    

      target_read6:
      begin
            mem[5]<=addressdata;
            if (no_data>6)
            begin
                if (!deviceselect && !tready && !i_ready)
                target_next_phase <= target_read7;
                else 
                target_next_phase <= target_read6;
            end
            else
            begin
                @(negedge clk)
                begin
                    tready<=1;
                    deviceselect<=1;
                    dataadd <= 32'hz;
                    target_next_phase <= default_target;
                end  
            end
      end

      target_read7:
      begin
            mem[6]<=addressdata;
            if (no_data>7)
            begin
                  if (!deviceselect && !tready && !i_ready)
                  target_next_phase <= target_read8;
                  else 
                  target_next_phase <= target_read7;
            end
            else
           begin
                @(negedge clk)
                begin
                    tready<=1;
                    deviceselect<=1;
                    dataadd <= 32'hz;
                    target_next_phase <= default_target;
                end  
            end      
      end

      target_read8:
      begin
            mem[7]<=addressdata;
            if (no_data>8)
            begin
                  
                  if (!deviceselect && !tready && !i_ready)
                  target_next_phase <= target_read9;
                  else 
                  target_next_phase <= target_read8;
            end
             else
            begin
                @(negedge clk)
                begin
                    tready<=1;
                    deviceselect<=1;
                    dataadd <= 32'hz;
                    target_next_phase <= default_target;
                end  
            end                       
      end    

      target_read9:
      begin
            mem[8]<=addressdata;
            if (no_data>9)
            begin
                  
                  if (!deviceselect && !tready && !i_ready)
                  target_next_phase <= target_read10;
                  else 
                  target_next_phase <= target_read9;
            end
            else
            begin
                @(negedge clk)
                begin
                    tready<=1;
                    deviceselect<=1;
                    dataadd <= 32'hz;
                    target_next_phase <= default_target;
                end  
            end                       
      end    

      target_read10:
      begin
             mem[9]<=addressdata;
            if (!deviceselect && !tready && !i_ready)
            begin
            @(negedge clk)
            begin
            tready<=1;
            deviceselect<=1;
            dataadd <= 32'hz;
            target_next_phase <= default_target;
            end      
            end
            else 
            target_next_phase <= target_read10;
      end
     

endcase
end

endmodule 
module arbiter (req_a,req_b,req_c, grant_a , grant_b,grant_c,clk,reset,frame);
input req_a;
input req_b;
input req_c;
output reg grant_a; //highest priority
output reg grant_b; // akid elbenhom ???????
output reg grant_c; // lowest priority
input clk;
input reset;
input frame;
 
always @(posedge clk) 
begin

  if(~reset)
    begin
      grant_a <=1;
      grant_b <=1;
      grant_c <=1;
    end   

  else if(!req_a & grant_a & grant_b & grant_c & frame)
    @(negedge clk)
      grant_a<=0;

  else if(req_a & !req_b & grant_a &grant_b & grant_c & frame)
    @(negedge clk)
      grant_b<=0;

  else if(req_a & req_b & !req_c & grant_a & grant_b & grant_c & frame)
    @(negedge clk)
      grant_c<=0;

  else
  begin
    @(negedge clk)
      grant_a<=1;
      grant_b<=1;
      grant_c<=1;
  end

end
              
endmodule


module PCI_TB () ;
    // common
    reg clk ;
    reg reset;
    reg cbe; // 1=read , 0=write
    wire [31:0] data_address_bus ; 
    reg [3:0] no_data ; 
    wire frame;
    wire  iready;
    wire  tready;

    wire deviceSelect; 
    reg[31:0]  forceadd;
    // per device
    reg[31:0] deviceA;
    reg[31:0] deviceB;
    reg[31:0] deviceC;    
    /*reg[31:0] initialize_memory_A0;
    reg[31:0] initialize_memory_A1;
    reg[31:0] initialize_memory_A2;
    reg[31:0] initialize_memory_A3;
    reg[31:0] initialize_memory_A4;
    reg[31:0] initialize_memory_A5;
    reg[31:0] initialize_memory_A6;
    reg[31:0] initialize_memory_A7;
    reg[31:0] initialize_memory_A8;
    reg[31:0] initialize_memory_A9;
    
    reg[31:0] initialize_memory_B0;
    reg[31:0] initialize_memory_B1;
    reg[31:0] initialize_memory_B2;
    reg[31:0] initialize_memory_B3;
    reg[31:0] initialize_memory_B4;
    reg[31:0] initialize_memory_B5;
    reg[31:0] initialize_memory_B6;
    reg[31:0] initialize_memory_B7;
    reg[31:0] initialize_memory_B8;
    reg[31:0] initialize_memory_B9;    
    // 
    reg[31:0] initialize_memory_C0;
    reg[31:0] initialize_memory_C1;
    reg[31:0] initialize_memory_C2;
    reg[31:0] initialize_memory_C3;
    reg[31:0] initialize_memory_C4;
    reg[31:0] initialize_memory_C5;
    reg[31:0] initialize_memory_C6;
    reg[31:0] initialize_memory_C7;
    reg[31:0] initialize_memory_C8;
    reg[31:0] initialize_memory_C9;   */ 
    wire request_A;
    wire request_B;
    wire request_C;
    wire grant_A;
    wire grant_B;
    wire grant_C;    
    reg force_request_A;
    reg force_request_B;
    reg force_request_C;
    integer i;
    wire masterA;
    wire masterB;
    wire masterC;
   
    assign frame = (masterA | masterB | masterC) ? 1'bz : 1'b1;

initial
begin 

    // memory initialization
    //10 words of A
    /*initialize_memory_A0 <= 0;
    initialize_memory_A1 <= 1;
    initialize_memory_A2 <= 2;
    initialize_memory_A3 <= 3;
    initialize_memory_A4 <= 4;
    initialize_memory_A5 <= 5;
    initialize_memory_A6 <= 6;
    initialize_memory_A7 <= 7;
    initialize_memory_A8 <= 8;
    initialize_memory_A9 <= 9;
    //10 words of B    
    initialize_memory_B0 <= 10;
    initialize_memory_B1 <= 11;
    initialize_memory_B2 <= 12;
    initialize_memory_B3 <= 13;
    initialize_memory_B4 <= 14;
    initialize_memory_B5 <= 15;
    initialize_memory_B6 <= 16;
    initialize_memory_B7 <= 17;
    initialize_memory_B8 <= 18;
    initialize_memory_B9 <= 19;
    //10 words of A        
    initialize_memory_C0 <= 20;
    initialize_memory_C1 <= 21;
    initialize_memory_C2 <= 22;
    initialize_memory_C3 <= 23;
    initialize_memory_C4 <= 24;
    initialize_memory_C5 <= 25;
    initialize_memory_C6 <= 26;
    initialize_memory_C7 <= 27;
    initialize_memory_C8 <= 28;
    initialize_memory_C9 <= 29;      */          

    // setting addresses for all devices
    deviceA <= 32'h00000000;
    deviceB <= 32'h00000001;
    deviceC <= 32'h00000002;   
clk =0;  	 

    // resetting
    reset=1;
    #7
    reset=0;
    #5
    reset=1;
	 #10
    // 1st scenario
    cbe=0; // 1=read , 0=write
    force_request_A=0;
    force_request_B=1;
    force_request_C=1;
	//grant_A=0;
    forceadd = deviceB; 
    no_data=3;
    #10
    //grant_A=1;
    force_request_A=1;
    #140
    // resetting
	reset=1;
    #7
    reset=0;
    #5
    reset=1;
	 #10
       // 2nd scenario
    cbe=0;
    force_request_A=1;
    force_request_B=0;
    force_request_C=1;
   // grant_B=0;
    forceadd = deviceA;
    no_data = 2;
    #10
   // grant_B=1;
    force_request_B=1;
    #140
// resetting    
	reset=1;
    #7
    reset=0;
    #5
    reset=1;
	 #10
       // 3rd scenario
    cbe=0;
    force_request_A=0;
    force_request_B=1;
    force_request_C=0;
   // grant_B=0;
    forceadd = deviceC;
    no_data = 2;
    #10
   // grant_B=1;
    force_request_A=1;
    #140
	reset=1;
    #7
    reset=0;
    #5
    reset=1;
      forceadd = deviceA;
    no_data = 1;
    #140
	reset=1;
    #7
    reset=0;
    #5
    reset=1;
      forceadd = deviceB;
    no_data = 1;
      #10
   // grant_B=1;
    force_request_C=1;    

end


    // clock 
    always #5 clk=~clk;

    // devices instansiation        
    Device A (clk,reset,cbe,data_address_bus,no_data,frame,iready,tready,deviceSelect,request_A,forceadd, grant_A , deviceA,force_request_A, masterA);//,frame_dub);//32'hFFFFFFFF ,32'hFFFFFFFF  ,32'hFFFFFFFF  ,initialize_memory_A3 ,initialize_memory_A4 ,initialize_memory_A5 ,initialize_memory_A6 ,initialize_memory_A7 ,initialize_memory_A8 ,initialize_memory_A9, force_request_A );
    Device B (clk,reset,cbe,data_address_bus,no_data,frame,iready,tready,deviceSelect,request_B,forceadd, grant_B , deviceB,force_request_B, masterB);//,frame_dub);//initialize_memory_B0,initialize_memory_B1,initialize_memory_B2,initialize_memory_B3,initialize_memory_B4,initialize_memory_B5,initialize_memory_B6,initialize_memory_B7,initialize_memory_B8 ,initialize_memory_B9 ,force_request_B);
    Device C (clk,reset,cbe,data_address_bus,no_data,frame,iready,tready,deviceSelect,request_C,forceadd, grant_C , deviceC ,force_request_C, masterC);//,frame_dub);//initialize_memory_C0,initialize_memory_C1,initialize_memory_C2,initialize_memory_C3,initialize_memory_C4,initialize_memory_C5,initialize_memory_C6,initialize_memory_C7,initialize_memory_C8,initialize_memory_C9 , force_request_C);

    arbiter U (request_A, request_B, request_C, grant_A, grant_B, grant_C, clk, reset, frame);

endmodule



