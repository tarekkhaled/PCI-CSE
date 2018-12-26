module arbiter (req_a,req_b,req_c, grant_a , grant_b,grant_c,clk,reset,frame);
input req_a;
input req_b;
input req_c;
output reg grant_a; //highest priority
output reg grant_b; // akid elbenhom بديهيات
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

Clk=0;
Reset=1;
req_a=1;
req_b=1;
req_c=1;
#3
Reset=0;
#3 
Reset=1;
#2
req_a=0;
req_b=0;
#4
req_a=1;
frame=1;
#4
frame=0;
req_c=0;
#4
req_b=1;
frame=1;
#4
frame=0;
end

arbiter U1 (req_a,req_b,req_c, grant_a , grant_b,grant_c,Clk,Reset,frame);

endmodule