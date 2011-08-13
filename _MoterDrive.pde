//libraries
#include <IRremote.h>
#include <SoftwareSerial.h>

#define checkPinA 2
#define checkPinB 3
#define rxPin 4
#define txPin 5
#define sensorPin1 A0
#define sensorPin2 A1
#define RECV_PIN 11

//for drive function
int count = 0;
int pen_direction = 0;
int last_pen_direction = 0;

//for IR function
int motorValue;
int irState;
boolean remoteMode = false;
int smoothedValue1, smoothedValue2;

//for smooth distance sesor value
const int BUFFER_LENGTH = 20;
int buffer1[BUFFER_LENGTH];
int buffer2[BUFFER_LENGTH];
int index = 0;


SoftwareSerial mySerial =  SoftwareSerial(rxPin, txPin);

IRrecv irrecv(RECV_PIN);
decode_results results;


void setup(){
  Serial.begin(57600);

  mySerial.begin(9600);
  mySerial.print(127, BYTE);

  pen_direction = -1;
  irrecv.enableIRIn();

  attachInterrupt(1, rotary, CHANGE);
  
  pinMode(rxPin, INPUT);
  pinMode(txPin, OUTPUT);
  pinMode(checkPinA, INPUT);
  pinMode(checkPinB, INPUT);
  pinMode(sensorPin1, INPUT);
  pinMode(sensorPin2, INPUT);
}

void loop(){

  ircheck();

  if(irState == 1436){
    remoteMode = !remoteMode;
  }

  if (remoteMode){
    if(irState == 27803){
      motorValue = 145;
    }
    else if (irState == 11419){
      motorValue = 100; //reverse
    }
    else if (irState == 19613){
      motorValue = 127;
    }
    mySerial.print(motorValue, BYTE); //forward
  }


  int raw1 = analogRead(sensorPin1);
  int raw2 = analogRead(sensorPin2);
  buffer1[index] = raw1;
  buffer2[index] = raw2;
  // 次回バッファに書き込む位置を更新
  // バッファの最後まで来たら折り返す
  index = (index + 1) % BUFFER_LENGTH;

  smoothedValue1 = smoothByMeanFilter(buffer1);
  smoothedValue2 = smoothByMeanFilter(buffer2);

  if(Serial.available() > 0){  
    Serial.print(smoothedValue1, DEC);
    Serial.print(',');
    Serial.println(smoothedValue2, DEC);
    Serial.read();
  }
}

void rotary(){
  if(!remoteMode){
    if(smoothedValue1 > 60){
      if(smoothedValue2 > 60){
        if(digitalRead(checkPinA) == HIGH){
          if(digitalRead(checkPinB) == HIGH){
            count++;
            pen_direction = 1;
            motor();
            last_pen_direction = pen_direction; 
          }
          else{
            count--;
            pen_direction = 0;
            motor();
            last_pen_direction = pen_direction; 
          }
        }
        if(digitalRead(checkPinA) == LOW){
          if(digitalRead(checkPinB) == LOW){
            count++;
            pen_direction = 1;
            motor();
            last_pen_direction = pen_direction;
          }
          else{
            count--;
            pen_direction = 0;
            motor();
            delay(100);
            last_pen_direction = pen_direction;      
          }
        }
        //Serial.print(pen_direction);
        //Serial.print(" ");
        //Serial.println(count);
        //delay(30);
        if (count > 16) {
          count = 1;
        }
        if (count < 0) {
          count = 16;
        }
      }
      else {
        mySerial.print(143, BYTE);
        delay(2000);
      }
    }
    else {
      mySerial.print(110, BYTE);
      delay(2000);
    }
  }
}



void motor(){
  //  if(pen_direction == 1 && last_pen_direction == 0){
  if(pen_direction == 1){
    mySerial.print(100, BYTE);
  }
  //  else  if(pen_direction == 0 && last_pen_direction == 1){
  else  if(pen_direction == 0){
    mySerial.print(153, BYTE);
  }
}
void ircheck() {
  if (irrecv.decode(&results)) {
    irState = results.value;
    irrecv.resume();
  }
  else{
    irState = 0;
    //    irrecv.resume();
  }
}


// Meanフィルタによるスムージング
int smoothByMeanFilter(int b[]) {
  // バッファの値の合計を集計するための変数
  long sum = 0;

  // バッファの値の合計を集計
  for (int i = 0; i < BUFFER_LENGTH; i++) {
    sum += b[i];
  }
  // 平均をフィルタの出力結果として返す
  return (int)(sum / BUFFER_LENGTH);
}

