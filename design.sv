module eeprom_top
  (
 input clk,
 input rst,
 input newd,
 input ack,
 input wr,   
 output scl,
 inout sda,
 input [7:0] wdata,
 input [6:0] addr, 
 output reg [7:0] rdata,
 output reg done
  );
  
 reg sda_en = 0;
  
 reg sclt, sdat, donet; 
 reg [7:0] rdatat; 
 reg [7:0] addrt;
 
  
  typedef enum {new_data = 0, check_wr = 1, wstart = 2, wsend_addr = 3, waddr_ack = 4, 
                wsend_data = 5, wdata_ack = 6, wstop = 7, rsend_addr = 8, raddr_ack = 9, rsend_data = 10,
                rdata_ack = 11, rstop = 12 } state_type;
  state_type state;
  
  
  
  
  
  reg sclk_ref = 0;
  int count = 0;
  int i = 0;
  
  ////100 M / 400 K = N
  ///N/2
  
  
  always@(posedge clk)
    begin
      if(count <= 9) 
        begin
           count <= count + 1;     
        end
      else
         begin
           count     <= 0; 
           sclk_ref  <= ~sclk_ref;
         end	      
    end
  
  
  
  always@(posedge sclk_ref, posedge rst)
    begin 
      if(rst == 1'b1)
         begin
           sclt  <= 1'b0;
           sdat  <= 1'b0;
           donet <= 1'b0;
         end
       else begin
         case(state)
           new_data : 
           begin
              sdat <= 1'b0;
              done <= 1'b0;
              sda_en  <= 1'b1;
              sclt <= 1'b1;
              sdat <= 1'b1;
             if(newd == 1'b1) 
                state  <= wstart;
             else 
                 state <= new_data;         
           end
         
            wstart: 
            begin
              sdat  <= 1'b0;
              sclt  <= 1'b1;
              state <= check_wr;
              addrt <= {addr,wr};
            end
            
            
            
            check_wr: begin
              if(wr == 1'b1) 
                 begin
                 state <= wsend_addr;
                 sdat <= addrt[0];
                 i <= 1;
                 end
               else 
                 begin
                 state <= rsend_addr;
                 sdat <= addrt[0];
                 i <= 1;
                 end
            end
         
                    
 
 
         
         
            wsend_addr : begin                
                      if(i <= 7) begin
                      sdat  <= addrt[i];
                      i <= i + 1;
                      end
                      else
                        begin
                          i <= 0;
                          state <= waddr_ack; 
                        end   
                    end
         
         
           waddr_ack : begin
             if(ack == 1'b1) begin
               state <= wsend_data;
               sdat  <= wdata[0];
               i <= i + 1;
               end
             else
               state <= waddr_ack;
           end
         
         wsend_data : begin
           if(i <= 7) begin
              i     <= i + 1;
              sdat  <= wdata[i]; 
           end
           else begin
              i     <= 0;
              state <= wdata_ack;
           end
         end
         
          wdata_ack : begin
             if(ack == 1'b1) begin
               state <= wstop;
               sdat <= 1'b0;
               sclt <= 1'b1;
               end
             else begin
               state <= wdata_ack;
             end 
            end
         
              
         
         wstop: begin
              sdat  <=  1'b1;
              state <=  new_data;
              done  <=  1'b1;  
         end
         
         ///////////////////////read state
         
         
          rsend_addr : begin
                     if(i <= 7) begin
                      sdat  <= addrt[i];
                      i <= i + 1;
                      end
                      else
                        begin
                          i <= 0;
                          state <= raddr_ack; 
                        end   
                    end
         
         
           raddr_ack : begin
             if(ack == 1'b1) begin
               state  <= rsend_data;
               sda_en <= 1'b0;
             end
             else
               state <= raddr_ack;
           end
         
         rsend_data : begin
                   if(i <= 7) begin
                         i <= i + 1;
                         state <= rsend_data;
                         rdata[i] <= sda;
                      end
                      else
                        begin
                          i <= 0;
                          state <= rstop;
                          sclt <= 1'b1;
                          sdat <= 1'b0;  
                        end         
         end
          
        
         
         
         rstop: begin
              sdat  <=  1'b1;
              state <=  new_data;
              done  <=  1'b1;  
              end
         
         
         default : state <= new_data;
         
          	 endcase
          end
  end
  
 assign scl = (( state == wstart) || ( state == wstop) || ( state == rstop)) ? sclt : sclk_ref;
 assign sda = (sda_en == 1'b1) ? sdat : 1'bz;
endmodule
 
 
 
/////////////////////////////module i2c_memory
 
module i2cmem_top (
input clk, rst,
input scl,
inout sda,
output reg ack
);
 
reg [7:0] mem[128];
reg [7:0] addrin;
reg [7:0] datain;
reg [7:0] temprd;
reg sda_en = 0;
reg sdar = 0;
 
int i = 0;
int count = 0;
 
reg sclk_ref = 0;
  
  always@(posedge clk)
    begin
      if(count <= 9) 
        begin
           count <= count + 1;     
        end
      else
         begin
           count     <= 0; 
           sclk_ref  <= ~sclk_ref;
         end	      
    end
    
    
 
typedef enum {start = 0, store_addr = 1, ack_addr = 2, store_data = 3, ack_data  = 4, stop = 5, send_data = 6} state_type;
state_type state;
 
 
always@(posedge sclk_ref, posedge rst)
    begin 
      if(rst == 1'b1) begin
        for(int j =0; j < 127 ; j++) begin 
         mem[j] <= 8'h91;
        end
        sda_en <= 1'b1;        
       end 
      else begin
       case(state)
         start: begin
           sda_en <= 1'b1;  ///read data
          if ((scl == 1'b1) && (sda == 1'b0)) begin
               state <= store_addr;
               end
           else
              state <= start;         
         end
         
         store_addr: begin
           sda_en <= 1'b1; 
            if(i <= 7) begin
            i <= i + 1;
            addrin[i] <= sda;
          end
          else begin
             state <= ack_addr;
             temprd <= mem[addrin[7:1]]; 
             ack <= 1'b1; 
             i <= 0;
             end
         end
         
         ack_addr: begin
           ack <= 1'b0;
                  
          if(addrin[0] == 1'b1) begin
             state <= store_data;
             sda_en <= 1'b1; 
             end
          else begin
             state <= send_data;
              i <= 1;
              sda_en <= 1'b0;  ///write data
              sdar <= temprd[0];
            end
         end
         
         store_data : 
         begin
         
         if(i <= 7) begin
            i <= i + 1;
            datain[i] <= sda;
          end
          else begin
             state <= ack_data; 
             ack <= 1'b1;
             i <= 0;
             end   
         end
         
         ack_data : begin
           ack <= 1'b0;
           mem[addrin[7:1]] <= datain;
           state <= stop;    
         end
         
         stop: begin
           sda_en <= 1'b1;
          if( (scl == 1'b1)&&(sda == 1'b1) )
           state <= start;
           else
           state <= stop; 
         end
         
         send_data : begin
           sda_en <= 1'b0;
          if(i <= 7) begin
            i <= i + 1;
            sdar <= temprd[i];
            end
          else begin
             state <= stop; 
             i <= 0;
             sda_en <= 1'b1;
             end 
         end
         
         default : state <= start;
       endcase
      end
    end
    
assign sda = (sda_en == 1'b1) ? 1'bz : sdar;
 
endmodule
 

module i2c_top(
 input clk,
 input rst,
 input newd,
 input wr,   
 input [7:0] wdata,
 input [6:0] addr,
 output [7:0] rdata,
 output  done
);
 
wire sdac;
wire sclc;
wire ackc;
 
eeprom_top e1 (clk,rst,newd, ackc,wr,sclc, sdac, wdata, addr, rdata,done);
 
i2cmem_top m1 (clk,rst, sclc, sdac, ackc);
 
endmodule
 
 
interface i2c_if;
  logic clk;
  logic rst;
  logic newd;
  logic wr;   
  logic [7:0] wdata;
  logic [6:0] addr;
  logic [7:0] rdata;
  logic  done;
  logic sclk_ref;
  
  
endinterface