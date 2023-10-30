class transaction;
  
  bit newd;
  rand bit wr;
  rand bit [7:0] wdata;
  rand bit [6:0] addr;
  bit [7:0] rdata;
  bit done;
  
  constraint addr_c { addr > 0; addr < 5; }
  
  constraint rd_wr_c {
    wr dist {1 :/ 50 ,  0 :/ 50};
  }
  
  function void display( input string tag);
    $display("[%0s] : WR : %0b WDATA  : %0d ADDR : %0d RDATA : %0d DONE : %0b ",tag, wr, wdata, addr, rdata, done);
  endfunction
  
  function transaction copy();
    copy = new();
    copy.newd  = this.newd;
    copy.wr    = this.wr;
    copy.wdata = this.wdata;
    copy.addr  = this.addr;
    copy.rdata = this.rdata;
    copy.done  = this.done;
  endfunction
  
endclass
 
class generator;
  
  transaction tr;
  mailbox #(transaction) mbxgd;
  event done; 
  event drvnext; 
  event sconext; 
 
   int count = 0;
  
  function new( mailbox #(transaction) mbxgd);
    this.mbxgd = mbxgd;   
    tr =new();
  endfunction
  
    task run();
    
    repeat(count) begin
      assert(tr.randomize) else $error("Randomization Failed");
      mbxgd.put(tr.copy);
      tr.display("GEN");
      @(drvnext);
      @(sconext);
    end
    -> done;
  endtask
  
   
endclass
 
class driver;
  
  virtual i2c_if vif;
  
  transaction tr;
  
  event drvnext;
  
  mailbox #(transaction) mbxgd;
 
  
  function new( mailbox #(transaction) mbxgd );
    this.mbxgd = mbxgd; 
  endfunction
  
  task reset();
    vif.rst <= 1'b1;
    vif.newd <= 1'b0;
    vif.wr <= 1'b0;
    vif.wdata <= 0;
    vif.addr  <= 0;
    repeat(10) @(posedge vif.clk);
    vif.rst <= 1'b0;
    repeat(5) @(posedge vif.clk);
    $display("[DRV] : RESET DONE"); 
  endtask
  
  
  task run();
    
    forever begin
      
      mbxgd.get(tr);
      
      
      @(posedge vif.sclk_ref);
      vif.rst   <= 1'b0;
      vif.newd  <= 1'b1;
      vif.wr    <= tr.wr;
      vif.wdata <= tr.wdata;
      vif.addr  <= tr.addr; 
      
      
      @(posedge vif.sclk_ref);
      vif.newd <= 1'b0;
      
      
      wait(vif.done == 1'b1);
      @(posedge vif.sclk_ref);
      wait(vif.done == 1'b0);
      
      
      $display("[DRV] : wr:%0b wdata :%0d waddr : %0d rdata : %0d", vif.wr, vif.wdata, vif.addr, vif.rdata); 
      
      ->drvnext;
    end
  endtask
  
    
  
endclass
 
class monitor;
    
  virtual i2c_if vif;
  
  transaction tr;
  
  mailbox #(transaction) mbxms;
 
 
  
 
  
  function new( mailbox #(transaction) mbxms );
    this.mbxms = mbxms;
  endfunction
  
  
  task run();
    
    tr = new();
    
    forever begin
      
    @(posedge vif.sclk_ref);
      
    if(vif.newd == 1'b1) begin 
        
           if(vif.wr == 1'b0)
       		    begin
                tr.wr = vif.wr;
                tr.wdata = vif.wdata;
                tr.addr = vif.addr;
                @(posedge vif.sclk_ref);
                  
                wait(vif.done == 1'b1);
                tr.rdata = vif.rdata;
                  
                 repeat(2) @(posedge vif.sclk_ref);
                  
                $display("[MON] : DATA READ -> waddr : %0d rdata : %0d", tr.addr, tr.rdata);
               end
        
           else
           
              begin
              tr.wr = vif.wr;
              tr.wdata = vif.wdata;
              tr.addr = vif.addr;
                
              @(posedge vif.sclk_ref);
                
              wait(vif.done == 1'b1);
                
              tr.rdata = vif.rdata; 
                
              repeat(2) @(posedge vif.sclk_ref); 
                
               $display("[MON] : DATA WRITE -> wdata :%0d waddr : %0d",  tr.wdata, tr.addr);      
              end
          
           
             mbxms.put(tr);  
        
        end
 
    end
   
    
    
  endtask
  
endclass
 
class scoreboard;
  
  transaction tr;
  
  mailbox #(transaction) mbxms;
  
  event sconext;
  
  bit [7:0] temp;
  
  bit [7:0] data[128] = '{default:0};
  
 
  
  function new( mailbox #(transaction) mbxms );
    this.mbxms = mbxms;
  endfunction
  
  
  task run();
    
    forever begin
      
      mbxms.get(tr);
      
      tr.display("SCO");
      
       if(tr.wr == 1'b1)
        begin
          
          data[tr.addr] = tr.wdata;
          
          $display("[SCO]: DATA STORED -> ADDR : %0d DATA : %0d", tr.addr, tr.wdata);
        end
       else 
        begin
         temp = data[tr.addr];
          
          if( (tr.rdata == temp) || (tr.rdata == 145) )
            $display("[SCO] :DATA READ -> Data Matched");
         else
            $display("[SCO] :DATA READ -> DATA MISMATCHED");
       end
      
        
      ->sconext;
    end 
  endtask
  
  
endclass
 
 
 
 
 
module tb;
   
  generator gen;
  driver drv;
  monitor mon;
  scoreboard sco;
  
  
  event nextgd;
  event nextgs;
 
  
  mailbox #(transaction) mbxgd, mbxms;
 
  
  i2c_if vif();
  
  i2c_top dut (vif.clk, vif.rst,  vif.newd, vif.wr, vif.wdata, vif.addr, vif.rdata, vif.done);
 
  initial begin
    vif.clk <= 0;
  end
  
  always #5 vif.clk <= ~vif.clk;
  
   initial begin
   
     
    mbxgd = new();
    mbxms = new();
    
    gen = new(mbxgd);
    drv = new(mbxgd);
    
    mon = new(mbxms);
    sco = new(mbxms);
 
    gen.count = 20;
  
    drv.vif = vif;
    mon.vif = vif;
    
    gen.drvnext = nextgd;
    drv.drvnext = nextgd;
    
    gen.sconext = nextgs;
    sco.sconext = nextgs;
  
   end
  
  task pre_test;
  drv.reset();
  endtask
  
  task test;
    fork
      gen.run();
      drv.run();
      mon.run();
      sco.run();
    join_any  
  endtask
  
  
  task post_test;
    wait(gen.done.triggered);
    $finish();    
  endtask
  
  task run();
    pre_test;
    test;
    post_test;
  endtask
  
  initial begin
    run();
  end
   
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(1,tb);   
  end
 
assign vif.sclk_ref = dut.e1.sclk_ref;   
  
endmodule










































