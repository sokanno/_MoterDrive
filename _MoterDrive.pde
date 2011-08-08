//testing with rotary encoder
//振り子の回転方向にあわせてモータを回すことで振り子の回転を助長するためのスケッチ
//そこまではできたっぽい
//ただ、振り子の回転方向が変わった瞬間だけ、少し回るってのができない。

#include <IRremote.h>
#include <SoftwareSerial.h>  // ライブラリの導入

#define rxPin 4
#define txPin 5
#define ledPin 13

SoftwareSerial mySerial =  SoftwareSerial(rxPin, txPin);


int RECV_PIN = 11;
int checkPinA = 2;
int checkPinB = 3;
int count = 0;
int pen_direction = 0;
int last_pen_direction = 0;
int motorValue;
int irState;
long now = 0;



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

  // watch present
  //now++;

}

void rotary(){
  if(!remoteMode){

    //if(now < 1000000){
      if(digitalRead(checkPinA) == HIGH){
        if(digitalRead(checkPinB) == HIGH){
          count++;
          pen_direction = 1;
          motor();
          //last_pen_direction = pen_direction; 
        }
        else{
          count--;
          pen_direction = 0;
          motor();
          //last_pen_direction = pen_direction; 
        }
      }

      if(digitalRead(checkPinA) == LOW){
        if(digitalRead(checkPinB) == LOW){
          count++;
          pen_direction = 1;
          motor();
          //last_pen_direction = pen_direction;
        }
        else{
          count--;
          pen_direction = 0;
          motor();
          //last_pen_direction = pen_direction;      
        }
      }

      Serial.print(pen_direction);
      Serial.print(" ");
      Serial.println(count);

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



void motor(){
  //if(pen_direction == 1 && last_pen_direction == 0){
  if(pen_direction == 1){
    //Serial.println("->->->->");
    mySerial.print(100, BYTE);
    //servo.write(90 + pen_speed*something);

    // 下記のコマンドを入れると、モータが回らなくなります。
    //おそらくdelayしてもattachInterrupt処理が割り込むのでしょうか。
    //わかりません。。
    // delay(1000);
    //   servo.write(90);
  }
  // else  if(pen_direction == 0 && last_pen_direction == 1){
  else  if(pen_direction == 0){
    //Serial.println("<-<-<-<-");
    mySerial.print(155, BYTE);
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






