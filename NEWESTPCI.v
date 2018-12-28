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
      input force_request,
      output reg masterflag,
      output reg targetflag,
      inout target_found
);

assign request = force_request;

//* master phases
reg [15:0] master_next_phase;
parameter  master=16'h0020;
parameter  requestadd= 16'h0000;
parameter default_master=16'h8888;
//* read phases
parameter  turn_around= 16'h0001;
parameter  master_read_phase= 16'h0002;
parameter  beforefinsih = 16'h001b;
parameter  finish =16'h0011;
//*Master write phases
parameter master_write_phase=16'h1000;
parameter finishwrite=16'h1099;
//*target phases
reg [15:0] target_phase;
reg [15:0] target_next_phase;
parameter  default_target=16'hbbbb;
parameter  readadd= 16'h0000;
parameter  turn_around_target= 16'h0001;
parameter  target_write_phase= 16'h0002;
parameter  target_finish =16'h0011;
parameter write_phase_target=16'h1000;
//*Target write phases
parameter  target_read_phase = 16'h1101;


// 32-bit data-address bus register 
reg[31:0] dataadd;
assign addressdata = dataadd;

reg iframe, tready,iready,deviceselect;

assign frame = (masterflag) ? iframe : 1'bz;
assign i_ready=(masterflag)?iready:1'bz;
assign t_ready=(targetflag)?tready:1'bz;
assign devSelect=(targetflag)? deviceselect:1'bz;
assign target_found = (targetflag) ? 1'b1 : 1'bz;

//* define the memory 
reg [31:0] mem [0:9] ;
// counter to determine no of words being read or written
integer i,a;

always @(!reset)
begin
     //* reset state to intialize the bus     
     
    iready<=1'bz;
    tready<=1'bz;
    deviceselect<=1'bz;
    master_next_phase<=default_master;
    target_next_phase<=default_target;
    masterflag<=0;
    targetflag<=0;
    dataadd<=32'hz;
    iframe<=1;
    i =0;
    if (device_id == 32'h00000000)
    begin
      for(a=0 ; a<10 ; a=a+1)
      begin
            mem [a] <= 32'hAAAAAAAA;    
      end
    end
    else if (device_id == 32'h00000001)
    begin
      for(a=0 ; a<10; a=a+1)
      begin
            mem [a] <= 32'hBBBBBBBB;
      end
    end
    else 
    begin
    for(a=0 ; a<10; a=a+1)
      begin
             mem [a] <=32'hCCCCCCCC;
      end
    end
end

always@(posedge clk)
begin
    
     if(!grant & iframe)
        begin
        masterflag<=1;
        iready<=1;
        targetflag<=0; 
		end
		
case(master_next_phase)

	default_master: 
      begin
			
        if(masterflag==1)
        begin
          @(negedge clk)
            begin
                iframe<=0;
                dataadd<=forceadd; //address asserted
                if(cbe) //read operation 
                    begin
                    master_next_phase<=turn_around;
                    
                    end
                else
                  begin
                        master_next_phase<=master_write_phase;
                        i=0;
                  end
            end
        end
        else
            master_next_phase<=default_master;   
      end
      
      //*this phase is responsible for putting the address of the slave on the data bus and
      //* check the operation (read) or (write)
      
      master_write_phase: 
      begin
            @(negedge clk)
            begin
                  if (target_found)
                  begin
                        dataadd<=mem[i];
                        iready<=0;
                        if (no_data == i+1)
                        begin
                              iframe <= 1;
                              master_next_phase<=finishwrite;
                        end     
                        else
                        begin
                              master_next_phase<=master_write_phase;
                              i = i+1;
                        end  
                  end
                  else
                  begin
                    master_next_phase<=default_master;
                    masterflag <=0;
                    dataadd<=32'bz;
                  end    
            end
      end
      
      finishwrite:
      begin
            @(negedge clk)
            begin
            dataadd<=32'bz;
            iready <=1'bz;
            master_next_phase<=default_master; 
		masterflag<=0;
		iframe<=1;
		
            end  
      end
     //*this phase happens when master leaves the databus to the slave so it can write data on it 
      turn_around:
      begin
            @(negedge clk)
            begin
                if(target_found)
                begin
                  iready<=0;
                  dataadd<=32'hz;
                  master_next_phase<=master_read_phase;
                  i=0;
                end
                 else 
                 begin
                    master_next_phase<=default_master;
                    masterflag<=0; 
                    dataadd<=32'bz;                  
                 end
            end
      end
      //*first phase for target reading data
      master_read_phase:
      begin
            if(!devSelect && !t_ready && !iready && !frame)
              begin
                   mem[i]<=addressdata;
                   @(negedge clk)
                        begin 
                        if(!devSelect && !t_ready && !iready && !frame)
                        begin 
                              //*this if to check if this is the last data transaction will happen 
                              if(no_data-1==i+1)  
                              begin
                                    iframe<=1;
                                    master_next_phase<=beforefinsih;
                              end
                              else
                              begin
                                    master_next_phase<=master_read_phase;
                                    i=i+1;
                              end                              
                        end
                        else
                          master_next_phase<=master_read_phase;
                     end
            end
             else
                          master_next_phase<=master_read_phase;
           
      end  
      //* all signals are asserted high again to get ready for new transactions
      beforefinsih:
      begin
            if(!devSelect && !t_ready && !iready)
            begin
                  mem[no_data-1]<=addressdata;
                  @(negedge clk)
                  begin
                        iready<=1'bz;
                        dataadd <= 32'hz;
                        masterflag<=0;
                        master_next_phase <= finish;
                  end
            end
      end  
    
    //* a turnaround phase after data transactions
      finish:
      begin
            master_next_phase <= default_master;
      end                    
    
    endcase

end
always @ (posedge clk)
begin
      case(target_next_phase)
      
       default_target:
        
      begin
           
            targetflag <=0;
        if (frame)
        begin
            @ (negedge frame)
            if (!masterflag )
                  target_next_phase <= readadd;
            else
                target_next_phase <= default_target; 
        end 
        else
            target_next_phase <= default_target;        
      end

      readadd:
      begin
            if (forceadd == device_id)
            begin
                targetflag <=1;
                tready <= 1;
                deviceselect<=1;
					 i=0;
                if (cbe)
                 target_next_phase <= turn_around_target;
                else
                begin
                    target_next_phase<= target_read_phase;
                    @(negedge clk)
                    begin
                        tready <= 0;
                        deviceselect<=0;
                    end
                end
            end
            else
                target_next_phase<= default_target;        
      end
      
      turn_around_target:
      begin
        target_next_phase <= target_write_phase;
      end

      target_write_phase:
      begin
        @ (negedge clk)
            begin
                  if (!frame)
                  begin
                        tready <= 0;
                        deviceselect <=0;
                        dataadd <= mem[i];
                        if (!i_ready)
                              if (no_data == i+1)
                                    target_next_phase <= target_finish;
                              else
                              begin
                                    target_next_phase <= target_write_phase;
                                    i=i+1;
                              end
                        else 
                        target_next_phase <= target_write_phase;
                  end
                  else 
                  target_next_phase <= default_target; 
            end          
      end

    target_finish:
      begin
        @(negedge clk)
        begin
            tready<=1'b1;
            deviceselect<=1'b1;
            dataadd <= 32'hz;
            target_next_phase <= default_target;
        end
      end
      
      target_read_phase:
      begin
            mem[i]<=addressdata;
            if (no_data>i+1)
            begin
                if (!deviceselect && !tready && !i_ready)
                  begin
                        i=i+1;
                        target_next_phase <= target_read_phase;
                 end
                 else 
                    target_next_phase <= target_read_phase;
            end
            else
            begin
                @(negedge clk)
                begin
                    tready<=1'b1;
                    deviceselect<=1'b1;
                    dataadd <= 32'hz;
                    target_next_phase <= default_target;
                end  
            end                       
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

reg b_request, c_request;

parameter defaultt=4'b1111;
parameter a=4'b0001;
parameter b=4'b0010;
parameter c=4'b0011;
reg[3:0] current_phase;

always @ (*)
begin

if(!reset)
      begin
            current_phase<=defaultt;
      end 

  case(current_phase)
  
      defaultt:
      begin
            grant_a <=1;
            grant_b <=1;
            grant_c <=1;
            b_request<=0;
            c_request<=0;

            if(!req_a & frame)
            begin
             current_phase <= a;
              if (!req_b)
              begin
                b_request <=1 ;
              end
              if (!req_c)
              begin
                c_request <=1 ;
              end
            end  

            else if(req_a & !req_b  & frame)
            begin
                  current_phase <= b;
                  if (!req_c)
                  begin
                   c_request <=1 ;
                  end
            end

            else if(req_a & req_b & !req_c & frame)
                  current_phase <= c;

            else 
                  current_phase<=defaultt;
      end

      a:
      begin
            @ (negedge clk)
            begin
                  grant_a <=0;
                  @(posedge frame)
                  begin
                        grant_a <=1;
                        if(b_request)
                              current_phase<=b;
                        else if(c_request)
								begin
                              current_phase<=c;
								end		
                        else                        
                              current_phase<=defaultt;
                  end
            end
      end
      
      b:
      begin
      @(negedge clk)
           begin
                  grant_b <=0;
                  @(posedge frame)
                  begin
                        grant_b <=1;
                        if(c_request)
                              current_phase<=c;
                        else
                              current_phase<=defaultt;
                  end
            end
      end

      c:
      begin
      @(negedge clk)
            begin
                  grant_c <=0;
                  @(posedge frame)
                  begin
                    current_phase<=defaultt;
                    grant_c <=1;
                  end
            end
      end
 endcase
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
    wire masterA,masterB,masterC;
    wire targetA,targetB,targetC;
    wire targetfound;
                        
      assign targetfound = (targetA | targetB | targetC) ? 1'bz : 1'b0;
      assign frame = (masterA | masterB | masterC) ? 1'bz : 1'b1;
      assign iready = (masterA | masterB | masterC) ? 1'bz : 1'b1;
      assign tready = (targetA | targetB | targetC) ? 1'bz : 1'b1;
      assign deviceSelect = (targetA | targetB | targetC) ? 1'bz : 1'b1;    
    
initial
begin 

      
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
    forceadd = deviceB; 
    no_data=3;
    #10
    force_request_A=1;
    #140

      // 2nd scenario
    cbe=0;
    force_request_A=1;
    force_request_B=0;
    force_request_C=1;
    forceadd = 32'h12345678;
    no_data = 5;
    #10
    force_request_B=1;

   #140
   cbe=0; // 1=read , 0=write
    force_request_A=0;
    force_request_B=1;
    force_request_C=1;
    forceadd = deviceB; 
    no_data=3;
    #10
    force_request_A=1;
	#140
     cbe=0;
    force_request_A=0;
    force_request_B=1;
    force_request_C=0;
    forceadd = deviceC;
    no_data = 2;
    #10
    force_request_A=1;
    force_request_C=1;
   #50
      forceadd = deviceA;
      no_data = 1;

 #50
      cbe=0;
    force_request_A=1;
    force_request_B=1;
    force_request_C=0;
    forceadd = deviceB;
    no_data = 1;
	#7
     #10
    force_request_C=1;

end

    // clock 
    always #5 clk=~clk;

    // devices instansiation        
    Device A (clk,reset,cbe,data_address_bus,no_data,frame,iready,tready,deviceSelect,request_A,forceadd, grant_A , deviceA,force_request_A, masterA, targetA,targetfound);
    Device B (clk,reset,cbe,data_address_bus,no_data,frame,iready,tready,deviceSelect,request_B,forceadd, grant_B , deviceB,force_request_B, masterB, targetB,targetfound);
    Device C (clk,reset,cbe,data_address_bus,no_data,frame,iready,tready,deviceSelect,request_C,forceadd, grant_C , deviceC ,force_request_C, masterC, targetC,targetfound);

    arbiter U (request_A, request_B, request_C, grant_A, grant_B, grant_C, clk, reset, frame);

endmodule
