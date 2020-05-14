// declaring pin values

#define CLK 2
#define CHIP_ENABLE 40
#define OUTPUT_ENABLE 42
#define ADDR_NUM 15
#define DATA_NUM 8
const char ADDR[] = {31, 30, 29, 28, 27, 26, 25, 24, 45, 44, 41, 43, 23, 46, 22};
const char DATA[] = {32, 33, 34, 35, 36, 37, 38, 39};
void setup() {
  // put your setup code here, to run once:
  for(int i = 0; i < ADDR_NUM; i++) {
    pinMode(ADDR[i], INPUT);
  }
  for(int i = 0; i < DATA_NUM; i++) {
    pinMode(DATA[i], INPUT);
  }
  pinMode(CLK, INPUT);
  pinMode(CHIP_ENABLE, INPUT);
  pinMode(OUTPUT_ENABLE, INPUT);

  attachInterrupt(digitalPinToInterrupt(CLK), onClock, RISING);
  Serial.begin(57600);
  
}

void onClock() {
  char output[8];
  
  //read the address given to the EPROM
  unsigned int addr = 0;
  for(int n = 0; n < ADDR_NUM; n++) {
    int bit = digitalRead(ADDR[n]) ? 1 : 0;
    Serial.print(bit);
    addr = (addr << 1) + bit;
  }
  sprintf(output, "  %04x  ", addr);
  Serial.print(output);
  
  // read data output from EPROM
  unsigned int data = 0;
  for(int n = 0; n < DATA_NUM; n++) {
    int bit = digitalRead(DATA[n]) ? 1 : 0;
    Serial.print(bit);
    data = (data << 1) + bit;  
  }
  sprintf(output, "  %0x2  ", data);
  Serial.print(output);

  // read the cip enable and output enable pins and print them
  sprintf(output, "  %c  %c  ", digitalRead(CHIP_ENABLE) ? 'H' : 'L', digitalRead(OUTPUT_ENABLE) ? 'H' : 'L');
  Serial.println(output);
  
}

void loop() {
}
