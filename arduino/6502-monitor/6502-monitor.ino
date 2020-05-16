#define CLOCK 2
#define READ_WRITE 46
#define ADDR_BASE 22
#define DATA_BASE 38
#define ADDR_NUM 16
#define DATA_NUM 8
char ADDR[16];
char DATA[16];
//const char ADDR[] = {22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37};
//const char DATA[] = {38, 39, 40, 41, 42, 43, 44, 45};


void setup() {
  for (int i = 0; i < ADDR_NUM; i++) {
    ADDR[i] = (ADDR_BASE + ADDR_NUM) - (i + 1);
  }
  for (int i = 0; i < DATA_NUM; i++) {
    DATA[i] = (DATA_BASE + i);
  }
  for (int n = 0; n < 16; n += 1) {
    pinMode(ADDR[n], INPUT);
  }
  for (int n = 0; n < 8; n += 1) {
    pinMode(DATA[n], INPUT);
  }
  pinMode(CLOCK, INPUT);
  pinMode(READ_WRITE, INPUT);
  
  attachInterrupt(digitalPinToInterrupt(CLOCK), onClock, RISING);
  
  Serial.begin(57600);

  print_pins();
}


void print_pins() {
  for (int i = 0; i < ADDR_NUM; i++){
    Serial.print(int(ADDR[i]));
    Serial.print(", ");
  }
  Serial.println(" ");
  for (int i = 0; i < DATA_NUM; i++){
    Serial.print(int(DATA[i]));
    Serial.print(", ");
  }
  Serial.println(" ");
}


void onClock() {
  char output[15];

  unsigned int address = 0;
  for (int n = 0; n < 16; n += 1) {
    int bit = digitalRead(ADDR[n]) ? 1 : 0;
    Serial.print(bit);
    address = (address << 1) + bit;
  }
  
  Serial.print("   ");
  
  unsigned int data = 0;
  for (int n = 0; n < 8; n += 1) {
    int bit = digitalRead(DATA[n]) ? 1 : 0;
    Serial.print(bit);
    data = (data << 1) + bit;
  }

  sprintf(output, "   %04x  %c %02x", address, digitalRead(READ_WRITE) ? 'r' : 'W', data);
  Serial.println(output);  
}

void loop() {
}
