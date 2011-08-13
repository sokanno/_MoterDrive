//libraries
#include <IRremote.h>
#include <SoftwareSerial.h>

//// pin numbers //////////////////////
#define checkPinA 2
#define checkPinB 3
#define rxPin 4
#define txPin 5
#define sensorPin1 A0
#define sensorPin2 A1
#define RECV_PIN 11
///////////////////////////////////////


//for motor drive function
int count = 0;
int pen_direction = 0;
int motorSpeedBack = 20;
int motorSpeedFront = 25;

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

  irrecv.enableIRIn();

  //割り込み
  attachInterrupt(1, rotary, CHANGE);

  pinMode(rxPin, INPUT);
  pinMode(txPin, OUTPUT);
  pinMode(checkPinA, INPUT);
  pinMode(checkPinB, INPUT);
  pinMode(sensorPin1, INPUT);
  pinMode(sensorPin2, INPUT);
}

// メインループ ///////////////////////////////////////////
void loop(){

  ir(); //赤外線処理関数


  //距離センサの値を平均化
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

// インタラプタ起動時 //////////////////////////////////////
void rotary(){
  if(!remoteMode){ //ドライブモード

    if(smoothedValue1 > 60){
      if(smoothedValue2 > 60){       
        motor(checkPinA, checkPinB);       
      }
      else {
        mySerial.print(127 + motorSpeedFront, BYTE);
        delay(3000);
      }
    }
    else {
      mySerial.print(127 - motorSpeedBack, BYTE);
      delay(3000);
    }
  }

  else { //リモートモード
    mySerial.print(127, BYTE); //停止
  }    
}

// モーター関係の処理 /////////////////////////////////////
void motor(int pinA, int pinB){
  if(digitalRead(pinA) == HIGH){
    if(digitalRead(pinB) == HIGH){
      count++;
      pen_direction = 1;
    }
    else{
      count--;
      pen_direction = 0;
    }
  }
  if(digitalRead(pinA) == LOW){
    if(digitalRead(pinB) == LOW){
      count++;
      pen_direction = 1;
    }
    else{
      count--;
      pen_direction = 0;
      delay(100);
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

  //drive
  if(pen_direction == 1){
    mySerial.print(127 - motorSpeedBack, BYTE);
  }
  else  if(pen_direction == 0){
    mySerial.print(127 + motorSpeedFront, BYTE);
  }
}


// リモコン処理 //////////////////////////////////////////
void ir() {
  if (irrecv.decode(&results)) {
    irState = results.value;
    irrecv.resume();
  }
  else{
    irState = 0;
  }

  if(irState == 19613){ //電源ボタン
    remoteMode = true; //強制停止
  }
  else if(irState == 21661){ //”フォト”ボタン
    remoteMode = false; //ドライブモードon
  }
}


// Meanフィルタによるスムージング ///////////////////////////
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

