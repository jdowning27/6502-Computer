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
    pinMode(ADDR[i], OUTPUT);
  }
  for(int i = 0; i < DATA_NUM; i++) {
    pinMode(DATA[i], INPUT);
  }
  pinMode(CLK, INPUT);
  pinMode(CHIP_ENABLE, OUTPUT);
  pinMode(OUTPUT_ENABLE, OUTPUT);

  // set chip enable and output enable low so we can read the contents of the EPROM
  digitalWrite(CHIP_ENABLE, LOW);
  digitalWrite(OUTPUT_ENABLE, LOW);

  attachInterrupt(digitalPinToInterrupt(CLK), onClock, RISING);
  Serial.begin(57600);
  
}

void onClock() {
  // write new address to EPROM
  static int address = 0;
  char output[6];
  sprintf(output, "%04x    ", address);
  Serial.print(output);
  for(int n = 0; n < ADDR_NUM; n++) {
    bool bit = (1 << n) & address;
    Serial.print(bit);
    digitalWrite(ADDR[n], bit ? HIGH : LOW);
  }
  
  Serial.print("  ");
  
  // read data output from EPROM
  unsigned int data = 0;
  for(int n = 0; n < DATA_NUM; n++) {
    int bit = digitalRead(DATA[n]) ? 1 : 0;
    Serial.print(bit);
    data = (data << 1)+ bit;  
  }
  
  // print out serial data
  sprintf(output, "  %02x  ", data);
  Serial.println(output);
  
  //increment address counter
  address++;
}

void loop() {
}
