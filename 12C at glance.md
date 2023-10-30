**I2C communication protocol** is a serial communication protocol with two wire interface. It is commonly used for communication between integrated circuits on the same circuit board.<br>

-> It has an _I2C controller_ and _I2C memory_. The communication between them done using _SDA_ and _SCL_ port.<br>
-> **start condition** : _SDA_ stays at active high for one bit rate and then active low for one bit rate. At the same time, _SCL_ stays at active high for 2 bit rate.<br> 
-> After start condition adress bit (MSB -> LSB) and a bit to represent the operation (read [active high] or write [active low]) is send through _SDA_ respectively.<br>
-> An acknowledgement bit (active high for one bit rate) is sent following the operation bit. Then Data is sent (MSB -> LSB) through _SDA_ after that an acknowledgement bit sent again.<br>
-> **stop condition** : _SDA_ stays at active low for one bit rate and then active high for one bit rate. At the same time, _SCL_ stays at active high for 2 bit rate.<br> 

Done port in _I2C controller_ is turned to active high when the transaction is complete.<br> 
newd in _I2C controller_ is turned to active high when there is new data to send.

_click here_<br>
**[Design_code](https://github.com/Mhd-Shah/Verification-of-I2C-communication-protocol/blob/main/design.sv)**<br>
**testbench_code**<br>
