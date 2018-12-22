module Device (
	input clk ,
    input reset,
	input grant , 
	input cbe, // 1=read , 0=write
    inout [31:0] addressdata, // wire to bus of data and address 
	input [3:0] no_data ,//test bench stimulus to know when the read transaction will stop  
    output reg iframe,
	output reg iready,
	output reg tready,
	output reg deviceSelect,
	output reg request, 
    input[31:0]  forceadd,
    input device_id
);

// master phases
reg [15:0] master_phase;
reg [15:0] master_next_phase;
parameter  defaultt=16'h0010;
parameter  master=16'h0020;
parameter  requestadd= 16'h0000;
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
parameter write_phase=16'h1000;

//target phases
reg [15:0] target_phase;
reg [15:0] target_next_phase;
parameter  default_target=16'h0010;
parameter  readadd= 16'h0000;
parameter  turn_around= 16'h0001;
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
parameter  beforefinsih = 16'h001b;
parameter  finish =16'h0011;
parameter write_phase=16'h1000;

//* assign address data upon control signal
reg[31:0] addressreg;
reg[31:0] datareg;
reg controlreg;
//* control reg =1 --> addressdata bus = data reg
//* control reg =0 --> addressdata bus = address reg
assign addressdata=(controlreg)?  datareg:addressreg;

// 3 addresses for 3 devices
parameter deviceA = 32'h00000000;  
parameter deviceB = 32'h00000001;   
parameter deviceC = 32'h00000002;   

//* registers for master (initiator) & target(slave)
reg targetflag;
reg masterflag;

//* define the memory 
reg [31:0] mem [0:9] ;
reg [31:0] memTarget[0:9];



//*  switching from one phase to another on rising clock edges
always @(posedge clk)
begin
      master_phase <= master_next_phase;
      target_phase <= target_next_phase;

end

always @(posedge clk or reset)
begin
     //* reset state to intialize the bus 
    if (reset)
            begin 
                iframe<=1; 
                iready<=1;
                tready<=1;
                deviceSelect<=1;
                master_phase<=defaultt;
                target_phase<=default_target;
                masterflag<=0;
                targetflag<=0;
                datareg<=32'hz;
                addressreg<=32'hz;
            end 
    else
    begin 
    case(master_phase)

      //*default where we check the frame and grant  to know the master device
      defaultt: 
      begin
            if(!grant)// * iframe will always be 1 and this conditon will enter if grant is 0
            begin
				controlreg<=1'bz;
                        masterflag<=1;
                        targetflag<=0;
                  @(negedge clk)
                  begin
                        iframe<=0;
                        master_next_phase<=requestadd;
                  end
            end  
            else
                  master_next_phase<=defaultt; 
      end
      
      //*this phase is responsible for putting the address of the slave on the data bus and
      //* check the operation (read) or (write)
      requestadd: 
      begin
            @(negedge clk)
            begin
						controlreg<=0;
                        addressreg<=forceadd; //address asserted
                  if(cbe) //read operation 
                        master_next_phase<=turn_around;
                  else
                        master_next_phase<=write_phase;
            end
      end

     //*this phase happens when master leaves the databus to the slave so it can write data on it 
      turn_around:
      begin
            controlreg<=1;
            @(negedge clk)
            begin
                  iready<=0;
                  datareg<=32'hz;
                  master_next_phase<=data_phase1;
            end

      end
      
      //*first phase for target reading data
      data_phase1:
      begin
            @(negedge clk)
            begin 
                        if(!deviceSelect && !tready && !iready && !iframe)
                        begin
                              datareg<=memTarget[0]; 
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
            if(!deviceSelect && !tready && !iready && !iframe)
            begin
                        //on the posedge you will need to read the data from the databus and save it in the memory
                        mem[0]<=datareg;
                @(negedge clk)
                begin  
                        if(!deviceSelect && !tready && !iready && !iframe)
                        begin
                              datareg<=memTarget[1];
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
            if(!deviceSelect && !tready && !iready && !iframe)
            begin
                        mem[1]<=datareg;
                @(negedge clk)
                begin  
                        if(!deviceSelect && !tready && !iready && !iframe)
                        begin
                              datareg<=memTarget[2];
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
            if(!deviceSelect && !tready && !iready && !iframe)
            begin
                        mem[2]<=datareg;
                @(negedge clk)
                begin  
                        if(!deviceSelect && !tready && !iready && !iframe)
                        begin
                              datareg<=memTarget[3];
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
            if(!deviceSelect && !tready && !iready && !iframe)
            begin
                        mem[3]<=datareg;
                @(negedge clk)
                begin  
                        if(!deviceSelect && !tready && !iready && !iframe)
                        begin
                              datareg<=memTarget[4];
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
            if(!deviceSelect && !tready && !iready && !iframe)
            begin
                        mem[4]<=datareg;
                @(negedge clk)
                begin  
                        if(!deviceSelect && !tready && !iready && !iframe)
                        begin
                              datareg<=memTarget[5];
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
            if(!deviceSelect && !tready && !iready && !iframe)
            begin
                        mem[5]<=datareg;
                @(negedge clk)
                begin  
                        if(!deviceSelect && !tready && !iready && !iframe)
                        begin
                              datareg<=memTarget[6];
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
            if(!deviceSelect && !tready && !iready && !iframe)
            begin
                        mem[6]<=datareg;
                @(negedge clk)
                begin  
                        if(!deviceSelect && !tready && !iready && !iframe)
                        begin
                              datareg<=memTarget[7];
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
           if(!deviceSelect && !tready && !iready && !iframe)
            begin
                        mem[7]<=datareg;
                @(negedge clk)
                begin  
                        if(!deviceSelect && !tready && !iready && !iframe)
                        begin
                              datareg<=memTarget[8];
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
            if(!deviceSelect && !tready && !iready && !iframe)
            begin
                  @(negedge clk)
                  begin
                        datareg<=memTarget[9];
                        iframe<=1;
                        master_next_phase<=beforefinsih;
                  end
            end
      end   

      //* all signals are asserted high again to get ready for new transactions
      beforefinsih:
      begin
            if(!deviceSelect && !tready && !iready)
            begin
                  mem[no_data-1]<=datareg;
                  @(negedge clk)
                  begin
                        iready<=1;
                        tready<=1;
                        datareg <= 32'hz;
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


always @(posedge clk)
begin

    case (target_phase)

        default_target:
        begin
            tready<=1;
            deviceSelect<=1;
            targetflag[0]=0;
            targetflag[1]=0;
            targetflag[2]=0;
            if (!iframe)
            begin
              target_next_phase <= readadd;
            end
            else
            begin
              target_next_phase <= default_target;
            end
        end

// input device_id 

// deviceA = 00 B=1 C=2

// reg [31:0] mem [9:0]

        readadd:
        begin
            if (forceadd==deviceA //forceadd==device_id)
            begin
              targetflag[0]<=1; // targetflag=1
                               // data= memory [0]
              target_next_phase <= turn_around;
            end
            else if (forceadd==deviceB)
            begin
              targetflag[1]<=1;
              target_next_phase <= turn_around;
            end
            else if (forceadd==deviceC)
            begin
              targetflag[1]<=1;
              target_next_phase <= turn_around;
            end                    
        end
                
    endcase
end



 endmodule 