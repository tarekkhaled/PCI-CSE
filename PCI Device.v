module Device (
      input clk ,
      input reset,
      input grant , 
      input cbe, // 1=read , 0=write
      inout [31:0] addressdata, // wire to bus of data and address 
      input [3:0] no_data ,//test bench stimulus to know when the read transaction will stop  
      inout frame,
      inout  i_ready,
      inout  t_ready,
      inout devSelect,
      output  request, 
      input[31:0]  forceadd,
      input[31:0] device_id,
      input[31:0] init_mem[0:10],
      input force_request
);

assign request = force_request;

//* master phases
reg [15:0] master_phase;
reg [15:0] master_next_phase;
parameter  defaultt=16'h0010;
parameter  master=16'h0020;
parameter  requestadd= 16'h0000;

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
parameter beforefinsihwrite=16'h1100;

//*target phases
reg [15:0] target_phase;
reg [15:0] target_next_phase;
parameter  default_target=16'h0010;
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
reg masterflag;

// 32-bit data-address bus register 
reg[31:0] dataadd;
assign addressdata = dataadd;

reg iframe;
reg tready,iready,deviceselect;

assign frame=(masterflag)?iframe:1'bz;
assign i_ready=(masterflag)?iready:1'bz;
assign t_ready=(targetflag)?tready:1'bz;
assign devSelect=(targetflag)? deviceselect:1'bz;
   
//* define the memory 
reg [31:0] mem [0:9] ;

initial
begin 
      mem[0] <= init_mem [0];
      mem[1] <= init_mem [1];
      mem[2] <= init_mem [2];
      mem[3] <= init_mem [3];
      mem[4] <= init_mem [4];
      mem[5] <= init_mem [5];
      mem[6] <= init_mem [6];
      mem[7] <= init_mem [7];
      mem[8] <= init_mem [8];
      mem[9] <= init_mem [9];
end

//*  switching from one phase to another on rising clock edges
always @(posedge clk)
begin
      master_phase <= master_next_phase;
      target_phase <= target_next_phase;
end


always @(reset)
begin
     //* reset state to intialize the bus     
      iframe<=1; 
      iready<=z;
      tready<=z;
      deviceselect<=z;
      master_phase<=defaultt;
      target_phase<=default_target;
      masterflag<=0;
      targetflag<=0;
      dataadd<=32'hz;
end

always@(posedge clk)
begin
    if(!force_request)
    begin
     if(!grant & iframe)
        begin
        masterflag<=1;
        targetflag<=0; 
        case(master_phase)

      //*default where we check the frame and grant  to know the master device
      defaultt: 
      begin
            iready<=1'b1;
            tready<=1'bz;
            deviceselect<=1'bz;
            @(negedge clk)
            begin
                iframe<=0;
                dataadd<=forceadd; //address asserted
                if(cbe) //read operation 
                master_next_phase<=turn_around;
                else if(!cbe)
                master_next_phase<=write_phase;
                
            end 
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
                  if(!iready && !tready && !deviceselect)
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
                  if(!iready && !tready && !deviceselect )
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
             if( !iready && !tready && !deviceselect )
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
             if( !iready && !tready && !deviceselect )
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
                  if( !iready && !tready && !deviceselect  )
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
             if(!iready && !tready && !deviceselect )
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
             if( !iready && !tready && !deviceselect )
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
             if( !iready && !tready && !deviceselect)
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
             if( !iready && !tready && !deviceselect)
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
            master_next_phase<=defaultt; 
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
            @(negedge clk)
            begin 
                        if(!deviceselect && !tready && !iready && !iframe)
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
            if(!deviceselect && !tready && !iready && !iframe)
            begin
                        //on the posedge you will need to read the data from the databus and save it in the memory
                        mem[0]<=dataadd;
                @(negedge clk)
                begin  
                        if(!deviceselect && !t
                        ready && !iready && !iframe)
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
            if(!deviceselect && !t
            ready && !iready && !iframe)
            begin
                        mem[1]<=dataadd;
                @(negedge clk)
                begin  
                        if(!deviceselect && !t
                        ready && !iready && !iframe)
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
            if(!deviceselect && !t
            ready && !iready && !iframe)
            begin
                        mem[2]<=dataadd;
                @(negedge clk)
                begin  
                        if(!deviceselect && !t
                        ready && !iready && !iframe)
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
            if(!deviceselect && !t
            ready && !iready && !iframe)
            begin
                        mem[3]<=dataadd;
                @(negedge clk)
                begin  
                        if(!deviceselect && !t
                        ready && !iready && !iframe)
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
            if(!deviceselect && !t
            ready && !iready && !iframe)
            begin
                        mem[4]<=dataadd;
                @(negedge clk)
                begin  
                        if(!deviceselect && !t
                        ready && !iready && !iframe)
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
            if(!deviceselect && !t
            ready && !iready && !iframe)
            begin
                        mem[5]<=dataadd;
                @(negedge clk)
                begin  
                        if(!deviceselect && !t
                        ready && !iready && !iframe)
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
            if(!deviceselect && !t
            ready && !iready && !iframe)
            begin
                        mem[6]<=dataadd;
                @(negedge clk)
                begin  
                        if(!deviceselect && !t
                        ready && !iready && !iframe)
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
           if(!deviceselect && !t
           ready && !iready && !iframe)
            begin
                        mem[7]<=dataadd;
                @(negedge clk)
                begin  
                        if(!deviceselect && !t
                        ready && !iready && !iframe)
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
            if(!deviceselect && !t
            ready && !iready && !iframe)
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
            if(!deviceselect && !t
            ready && !iready)
            begin
                  mem[no_data-1]<=dataadd;
                  @(negedge clk)
                  begin
                        iready<=1;
                        tready<=1;
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
end
end

always @ (posedge clk)
begin
      case(target_phase)
      
      default_target:
      begin
            targetflag<=0;
            @(negedge clk)
                  @(negedge iframe)
                  target_next_phase <= readadd;
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
                  if (!iframe)
                  begin
                        tready <= 0;
                        devSelect <=0;
                        dataadd <= mem[0];
                        if (!iready)
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
            if(!iframe)
            begin
            dataadd <= mem[1];
                  if (!iready)
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
            if(!iframe)
            begin
            dataadd <= mem[2];
                  if (!iready)
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
            if(!iframe)
            begin
            dataadd <= mem[3];
                  if (!iready)
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
            if(!iframe)
            begin
            dataadd <= mem[4];
                  if (!iready)
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
            if(!iframe)
            begin
            dataadd <= mem[5];
                  if (!iready)
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
            if(!iframe)
            begin
            dataadd <= mem[6];
                  if (!iready)
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
            if(!iframe)
            begin
            dataadd <= mem[7];
                  if (!iready)
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
      if(!iframe)
      @(negedge clk)
      begin
            if(!iframe)
            begin
            dataadd <= mem[8];
                  if (!iready)
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
            if(!iframe)
            begin
            dataadd <= mem[9];
                  if (!iready)
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
      
            @(posedge iframe)
            begin
                  target_next_phase<=target_read_before_finish;           
            end
            if (no_data>1)
            begin
                  mem[0]<=dataadd;
                  if (!deviceselect && !tready && !iready)
                  target_next_phase <= target_read2;
                  else 
                  target_next_phase <= target_read1;
            end                
      end
            

      target_read2:
      begin
       @(posedge iframe)
            begin
                  target_next_phase<=target_read_before_finish;           
            end
            if (no_data>2)
            begin
                  mem[1]<=dataadd;
                  if (!deviceselect && !tready && !iready)
                  target_next_phase <= target_read3;
                  else 
                  target_next_phase <= target_read2;
            end
      end

      target_read3:
      begin
             @(posedge iframe)
            begin
                  target_next_phase<=target_read_before_finish;           
            end
            if (no_data>3)
            begin
                  mem[2]<=dataadd;
                  if (!deviceselect && !tready && !iready)
                  target_next_phase <= target_read4;
                  else 
                  target_next_phase <= target_read3;
            end
      end

      target_read4:
      begin
             @(posedge iframe)
            begin
                  target_next_phase<=target_read_before_finish;           
            end
            if (no_data>4)
            begin
                  mem[3]<=dataadd;
                  if (!deviceselect && !tready && !iready)
                  target_next_phase <= target_read5;
                  else 
                  target_next_phase <= target_read4;
            end
      end

      target_read5:
      begin
             @(posedge iframe)
            begin
                  target_next_phase<=target_read_before_finish;           
            end
            if (no_data>5)
            begin
                  mem[4]<=dataadd;
                  if (!deviceselect && !tready && !iready)
                  target_next_phase <= target_read6;
                  else 
                  target_next_phase <= target_read5;
            end
      end

      target_read6:
      begin
             @(posedge iframe)
            begin
                  target_next_phase<=target_read_before_finish;           
            end
            if (no_data>6)
            begin
            mem[5]<=dataadd;
            if (!deviceselect && !tready && !iready)
            target_next_phase <= target_read7;
            else 
            target_next_phase <= target_read6;
            end
      end

      target_read7:
      begin
 @(posedge iframe)
            begin
                  target_next_phase<=target_read_before_finish;           
            end
            if (no_data>7)
            begin
                  mem[6]<=dataadd;
                  if (!deviceselect && !tready && !iready)
                  target_next_phase <= target_read8;
                  else 
                  target_next_phase <= target_read7;
            end
      end

      target_read8:
      begin
       @(posedge iframe)
            begin
                  target_next_phase<=target_read_before_finish;           
            end
            if (no_data>8)
            begin
                  mem[7]<=dataadd;
                  if (!deviceselect && !tready && !iready)
                  target_next_phase <= target_read9;
                  else 
                  target_next_phase <= target_read8;
            end
      end

      target_read9:
      begin
       @(posedge iframe)
            begin
                  target_next_phase<=target_read_before_finish;           
            end
            if (no_data>9)
            begin
                  mem[8]<=dataadd;
                  if (!deviceselect && !tready && !iready)
                  target_next_phase <= target_read10;
                  else 
                  target_next_phase <= target_read9;
            end
      end

      target_read10:
      begin
            if (!deviceselect && !tready && !iready)
            target_next_phase <= target_read_before_finish;
            else 
            target_next_phase <= target_read10;
      end

      target_read_before_finish:
      begin
        mem[no_data-1]<=dataadd;
        target_next_phase<=target_finish;
      end       

endcase
end

endmodule 

