

/*module Device(force_req,frame,iready,tready,C/BE,AD,Dev_sel,clk,GNT,data);
input GNT;
reg data;
inout [31:0] AD; 
output frame,iready,tready,Dev_sel;
input [3:0] C/BE ;
input clk;
output force_req;
integer flag =0;
always @(posedge clk)
begin
	if(!frame)
	begin
	
	end
	if(!iread)
	if(!tready)
	if(!Dev_sel)
end
       @(negedge clk)
	begin
	
	end
endmodule

module Arbitor();
AddressToContact

endmodule
*/
module arbiter (req_a,req_b,req_c, grant_a , grant_b,grant_c,clk,reset,frame);
input req_a;
input req_b;
input req_c;
output reg grant_a; //higher priority
output reg grant_b;
output reg grant_c;
input clk;
input reset;
input frame;
 
    always @(posedge clk) 
        
                if(~reset)
                  begin
                  grant_a=1;
                  grant_b=1;
                  grant_c=1;
                  end           
                else if(req_a==0&&req_b==1&&req_c==1&&grant_a&&grant_b&&grant_c)
                 @(negedge clk)
		grant_a=0;
                else if(req_a==0&&req_b==0&&req_c==1&&grant_a&&grant_b&&grant_c)
                  @(negedge clk)
                  grant_a=0;
                else if(req_a==0&&req_b==1&&req_c==0&&grant_a&&grant_b&&grant_c)
                  @(negedge clk)
                  grant_a=0;
                else if(req_a==0&&req_b==0&&req_c==0&&grant_a&&grant_b&&grant_c)
                  @(negedge clk)
                  grant_a=0;
                else if(req_a==1&&req_b==0&&req_c==1&&grant_a&&grant_b&&grant_c)
                  @(negedge clk)
                  grant_b=0;
                else if(req_a==1&&req_b==0&&req_c==0&&grant_a&&grant_b&&grant_c)
                  @(negedge clk)
                  grant_b=0;
                else if(req_a==1&&req_b==1&&req_c==0&&grant_a&&grant_b&&grant_c)
                  @(negedge clk)
                  grant_c=0;
                else if(req_a&&req_b&&req_c)
                begin
                    @(negedge clk)
                    grant_a=1;
                    grant_b=1;
                    grant_c=1;
                end
		else if(frame)
		begin
		if(grant_a==0)grant_a=1;
                if(grant_b==0)grant_b=1;
                if(grant_c==0)grant_c=1;

		end
        

        
endmodule


module arbiter_tb();
reg Clk;
reg Reset;
reg req_a;
reg req_b;
reg req_c;
wire grant_a;
wire grant_b;
wire grant_c;
reg frame;
always #1 Clk=~Clk;

initial
begin
$monitor("%b  %b   %b   %b  %b  %b",req_a,req_b,req_c,grant_a,grant_b,grant_c);
Clk=0;
Reset=0;
req_a=1;
req_b=1;
req_c=1;
#10 Reset=1;

#10
req_a=0;
req_b=0;
#10
req_a=1;
frame=1;
#3
frame=0;
req_c=0;
#3
req_b=1;
frame=1;
#3
frame=0;





/*
repeat(1) @(posedge Clk);
req_a=0;
req_b=1;
req_c=0;
repeat(1) @(posedge Clk);
req_a=0;
req_b=0;
req_c=0;
repeat(1) @(posedge Clk);
req_a=1;
req_b=0;
req_c=1;
repeat(1) @(posedge Clk);
req_a=1;
req_b=0;
req_c=0;
repeat(1) @(posedge Clk);
req_a=1;
req_b=1;
req_c=0;
repeat(1) @(posedge Clk);
req_a=1;
req_b=1;
req_c=1;


*/


end

arbiter U1 (req_a,req_b,req_c, grant_a , grant_b,grant_c,Clk,Reset,frame);

endmodule
