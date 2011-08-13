

//testing with rotary encoder
//振り子の回転方向にあわせてモータを回すことで振り子の回転を助長するためのスケッチ
//そこまではできたっぽい
//ただ、振り子の回転方向が変わった瞬間だけ、少し回るってのができない。

#include <IRremote.h>
#include <SoftwareSerial.h>  // ライブラリの導入
#include <VirtualWire.h>

#define rxPin 4
#define txPin 5
//#define ledPin 13
#define sensorPin1 A0
#define sensorPin2 A1

SoftwareSerial mySerial =  SoftwareSerial(rxPin, txPin);

const int led_pin = 11;
const int transmit_pin = 12;
const int receive_pin = 2;
const int transmit_en_pin = 3;

int RECV_PIN = 11;
int checkPinA = 2;
int checkPinB = 3;
int count = 0;
int pen_direction = 0;
int last_pen_direction = 0;
int motorValue;
int irState;
long now = 0;

int value1Sum = 0;
int value2Sum = 0;
int smoothCount = 0;
int smoothNum = 100;
int smoothedValue1 = value1Sum/smoothNum;
int smoothedValue2 = value2Sum/smoothNum;

boolean remoteMode = false;

IRrecv irrecv(RECV_PIN);
decode_results results;

void setup(){
  Serial.begin(57600);
  pinMode(rxPin, INPUT);
  pinMode(txPin, OUTPUT);
  mySerial.begin(9600);
  mySerial.print(127, BYTE);
  pen_direction = -1;
  irrecv.enableIRIn();
  attachInterrupt(1, rotary, CHANGE);
  pinMode(checkPinA, INPUT);
  pinMode(checkPinB, INPUT);
  pinMode(sensorPin1, INPUT);
  pinMode(sensorPin2, INPUT);

  /*
  vw_set_tx_pin(transmit_pin);
   vw_set_rx_pin(receive_pin);
   vw_set_ptt_pin(transmit_en_pin);
   vw_set_ptt_inverted(true); // Required for DR3100
   vw_setup(7000); // Bits per sec
   */
}

//byte count = 1;


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

  // watch present
  //now++;

  int value1=analogRead(sensorPin1);
  int value2=analogRead(sensorPin2);
  value1Sum += value1;
  value2Sum += value2;
  smoothCount++;
  if(smoothCount > smoothNum - 1){
    smoothedValue1 = value1Sum/smoothNum;
    smoothedValue2 = value2Sum/smoothNum;
    /*
    Serial.print(smoothedValue1, DEC);
     Serial.print(',');
     Serial.println(smoothedValue2, DEC);
     */
    smoothCount = 0;
    value1Sum = 0;
    value2Sum = 0;
  }

}

void rotary(){
  if(!remoteMode){
    if(smoothedValue1 > 80){
      if(smoothedValue2 > 80){

        //if(now < 1000000){
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


        Serial.print(pen_direction);
        Serial.print(" ");
        Serial.println(count);
        //delay(30);
        if (count > 16) {
          count = 1;
        }

        if (count < 0) {
          count = 16;
        }

      }
      //else{ // now over 
      //mySerial.print(127, BYTE);
      //}
    }
  }
}



void motor(){
  //  if(pen_direction == 1 && last_pen_direction == 0){
  if(pen_direction == 1){

    mySerial.print(110, BYTE);

    /*
    char count[2] = {' ',' '};
     count[1] = 90;
     count[0] = 127;
     //vw_send((uint8_t *)count, 2);
     //vw_wait_tx(); // Wait until the whole message is gone
     
     */

    //Serial.println("->->->->");
    //    mySerial.print(95, BYTE);
    //servo.write(90 + pen_speed*something);

    // 下記のコマンドを入れると、モータが回らなくなります。
    //おそらくdelayしてもattachInterrupt処理が割り込むのでしょうか。
    //わかりません。。
    // delay(1000);
    //   servo.write(90);
  }
  //  else  if(pen_direction == 0 && last_pen_direction == 1){
  else  if(pen_direction == 0){

    mySerial.print(143, BYTE);

    /*
    char count[2] = {
     ' ',' '      };
     count[1] = 160;
     count[0] = 127;
     vw_send((uint8_t *)count, 2);
     vw_wait_tx(); // Wait until the whole message is gone
     */

    //Serial.println("<-<-<-<-");
    //    mySerial.print(160, BYTE);
    //servo.write(90 + pen_speed*something);
    // delay(1000);
    //   servo.write(90);
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


