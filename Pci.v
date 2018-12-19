module Device(
	input clk ,
    input reset,
	input grant , 
	input cbe, // 1=read , 0=write
    inout [31:0] addressdata, // wire to bus of data and address 
	output reg iframe,
	output reg iready,
	output reg tready,
	output reg deviceSelect,
	output reg request, 
    input reg forceadd 
    );
                        parameter ad1 = 32'h00000000;
                        parameter ad2 = 32'h00000001;
                        parameter ad3 = 32'h00000002;
                        reg [15:0] phases;
                        reg [15:0] next_phases;
                        parameter defaultt=16'h0010;
                        parameter master=16'h0020;
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
                        parameter  data_phase10= 16'h000b;

                        reg masterflag , targetflag;
                        // define the memory 
                        reg [31:0] mem [0:9] ;

                        always @(reset) 
                        begin 
                              iframe<=1; 
                              iready<=1;
                              tready<=1;
                              deviceSelect<=1;
                              phase<=defaultt;
                              masterflag<=0;
                              targetflag<=0;
                        end 
                        always @(posedge clk)
                        begin
                              phase<=next_phases;
                        end
                        always @(posedge clk )
                              begin
                              case(phase)
                              defaultt:
                              begin
                                    if(!grant && iframe)
                                    begin
                                    masterflag=1;
                                          @(negedge clk)
                                          begin
                                                iframe<=0;
                                                next_phases<=requestadd;
                                                
                                          end
                                    end   
                              end
                              requestadd: 
                              begin
                                    
                                          
                                    @(negedge clk)
                                    begin
                                          
                                          addressdata<=forceadd; //address asserted
                                          cbe<=1 ;//read operation 
                                          next_phases<=turn_around;
                                    end
                                                
                                    
                              end

                              turn_around:
                              begin
                                    addressdata<=32'hz;
                                    @(negedge clk)
                                    begin
                                          iready<=0;
                                          next_phases<=data_phase1;
                                    end

                                    end
                              
                              data_phase1:
                              begin
                                    if(!deviceSelect && !tready && iready && !iframe)
                                    begin
                                          addressdata<=mem[0];
                                          next_phases<=data_phase2;
                                    end
                              end
                              data_phase2:
                              begin
                                    if(!deviceSelect && !tready && iready && !iframe)
                                    begin
                                          addressdata<=mem[1];
                                          next_phases<=data_phase3;
                                    end
                              end    
                              data_phase3:
                              begin
                                    if(!deviceSelect && !tready && iready && !iframe)
                                    begin
                                          addressdata<=mem[2];
                                          next_phases<=data_phase4;
                                    end
                              end    
                              data_phase4:
                              begin
                                    if(!deviceSelect && !tready && iready && !iframe)
                                    begin
                                          addressdata<=mem[3];
                                          next_phases<=data_phase5;
                                    end
                              end    
                              data_phase5:
                              begin
                                    if(!deviceSelect && !tready && iready && !iframe)
                                    begin
                                          addressdata<=mem[4];
                                          next_phases<=data_phase6;
                                    end
                              end    
                              data_phase6:
                              begin
                                    if(!deviceSelect && !tready && iready && !iframe)
                                    begin
                                          addressdata<=mem[5];
                                          next_phases<=data_phase7;
                                    end
                              end    
                              data_phase7:
                              begin
                                    if(!deviceSelect && !tready && iready && !iframe)
                                    begin
                                          addressdata<=mem[6];
                                          next_phases<=data_phase8;
                                    end
                              end    
                              data_phase8:
                              begin
                                    if(!deviceSelect && !tready && iready && !iframe)
                                    begin
                                          addressdata<=mem[7];
                                          next_phases<=data_phase9;
                                    end
                              end   
                              data_phase9:
                              begin
                                    if(!deviceSelect && !tready && iready && !iframe)
                                    begin
                                          addressdata<=mem[8];
                                          next_phases<=data_phase10;
                                    end
                              end    
                              data_phase10:
                              begin
                                    if(!deviceSelect && !tready && iready && !iframe)
                                    begin
                                          addressdata<=mem[9];
                                          
                                    end
                              end         
                              







                              end

                              endcase
                              


                              end








                        //reg [31:0]entered_ad;
                        reg my_ad ; 
                        
                        // define the memory 
                        reg [31:0] mem [0:9] ;

                        // case 1 : the Device will be 'initiator' the operation will be 'Read' i 
                        always@(posedge clk)
                              begin
                              rise_count=rise_count+1;
                              if( request==0)  //master
                        begin 
                        entered_ad = addressdata
                        if(writen)

                        end 








                        else if (request==1)  //slave
                        begin

                        
                        
                        //  assign flag_same_ad = (entered_ad==my_ad)?1:0;
                        //reg [7:0] rise_count =8'b0000_0000_0000_0000;
                        end 
                                    @(negedge) 
                                    begin 
                                          if (!grant)
                                                begin
                                                iframe = 1'b0 

                                          

                                                
                                                end
                                    end
                              end
                        



 endmodule 