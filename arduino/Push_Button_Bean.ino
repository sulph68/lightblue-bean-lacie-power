#define CR 13
#define LF 10

static int d0 = 0;
static int d1 = 1;
static int d2 = 2;
static int d3 = 3;
static int d4 = 4;
static int d5 = 5;

int charCount = 0;
char buffer[64];

uint8_t battLevel = 0;

// set a unique Bean Namd
String beanName = "RemoteBean";


void setup() {
    // init beanName
    Bean.setBeanName(beanName);
    
    // initialize serial communication at 57600 bits per second:
    Serial.begin(57600);
    // this makes it so that the arduino read function returns
    // immediatly if there are no less bytes than asked for.
    Serial.setTimeout(25);
    
    // Init pin to be off
    pinMode(d0, OUTPUT);
    digitalWrite(d0, LOW);
    
    // wake only on connect to save battery
    Bean.enableWakeOnConnect(true);
    
    bootBlink();
}
 
// the loop routine runs over and over again forever:
void loop() {
  bool connected = Bean.getConnectionState();
  
  if (connected) {
    // wake and process only if connected
        
    // blink if low battery
    battLevel = Bean.getBatteryLevel();
    if (battLevel < 5) {
      lowPowerBlink();
    }
    
    charCount = getSerialData();    
    if (String(buffer) != "") {
      Serial.print("CMD: ");
      Serial.println(buffer); 
      processCommand();
    }
    Bean.sleep(3000);
  } else {
    // sleep arduino until woken up
    Bean.sleep(0xFFFFFFFF);
  }
}

int getSerialData() {
  int total_read = 0;
  int length = 64;

  // length = Serial.readBytes(buffer, length);
  total_read = Serial.readBytesUntil(CR, buffer, length);
  // Send back the value read

  // read an input pin
  if (total_read > 0) {
      buffer[total_read] = '\0';
      Serial.flush();
      return total_read;
  } else {
    return 0;
  }
}

void processCommand() { // process additional command string upon authentication
  if (String(buffer) == "on") {
    powerOn();
  } else if (String(buffer) == "off") {
    powerOff();
  } else if (String(buffer) == "short") {
    shortPress();
  } else if (String(buffer) == "long") {
    longPress();
  }
  clearBuffer();
}

void clearBuffer() {
  buffer[0] = '\0';
}

void bootBlink() {
	Bean.setLedGreen(128);
	Bean.sleep(500);
	Bean.setLed(0, 0, 0);
	Bean.sleep(500);
	Bean.setLedGreen(128);
	Bean.sleep(500);
	Bean.setLed(0, 0, 0);
}

void lowPowerBlink() {
	Bean.setLedRed(128);
	Bean.sleep(500);
	Bean.setLed(0, 0, 0);
	Bean.sleep(500);
	Bean.setLedRed(128);
	Bean.sleep(500);
	Bean.setLed(0, 0, 0);
}

void powerOn() {
  digitalWrite(d0, HIGH);
  Bean.sleep(2000);
  digitalWrite(d0, LOW);
}

void powerOff() {
  digitalWrite(d0, HIGH);
  Bean.sleep(2000);
  digitalWrite(d0, LOW);
}

void shortPress() {
  digitalWrite(d0, HIGH);
  Bean.sleep(2000);
  digitalWrite(d0, LOW);
}

void longPress() {
  digitalWrite(d0, HIGH);
  Bean.sleep(10000);
  digitalWrite(d0, LOW);
}