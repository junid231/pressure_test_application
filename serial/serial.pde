import processing.serial.*;
import g4p_controls.*;


// The serial port:
Serial myPort;       
String val;
String data = "S";

PFont font;
int COLS = 16;
int ROWS = 16;
int cellSize = 40;
int[][] Values = new int[ROWS][COLS];
int[][] zeroing_values = new int[ROWS][COLS];
int[][] final_values = new int[ROWS][COLS]; 
int value_sum;
 
color c = color( 256, 64, 64);
color buffc = color(0, 0, 0);
color value_color;
int value_c;
boolean definite_color = true;
boolean view_minus = false;
boolean stop = false;
boolean sum_minus = false;
//String[] viridis;
String[] magma;

int max=84;
int min=0;

//settings window
GWindow settings_window = null;
int set_min = 0;
GSpinner spn_min;

void setup(){
    //초기 영점조절 값 = 0
    for (int j = 0; j < COLS; j++) {
        for (int i = ROWS-1; i >= 0; i--) {
            zeroing_values[j][i] = 0;
        }
    }
    size(1000, 800);
    //시리얼 통신
    printArray(Serial.list());
    myPort = new Serial(this, "COM7", 9600);
    //viridis = loadStrings("viridis_85.txt");
    magma = loadStrings("magma_85.txt");
    //settings window
    createGUI();
}

void draw(){
    
    background(230, 230, 255);
    //color bar가 위치할 자리
    fill(255);
    noStroke();
    rect(0, height - 50, width, 50);
    //color bar옆 정사각형
    fill(c);
    noStroke();
    rect( 10, height - 40, 30, 30);
    //color bar 그리기
    int at=50;
    stroke(200);
    for ( int els= 84; els >=0; els--) {
        //fill( unhex(viridis[els]) );
        fill( unhex(magma[els]) );
        rect( at, height - 40, 8, 30);
        at+=8;
    }
    printValues();
    //mouse on시 왼쪽 정사각형의 색이 마우스가 위치한 색으로 전환
    //mouse on시 해당 색의 value가 출력되도록 설정
    if (mouseY > height - 40 && mouseY < height - 10 && mouseX > 50 && mouseX < 730){
        buffc = get(mouseX, mouseY);
        if (buffc != color(200, 200, 200)){//회색 출력 방지 조건
            c = get(mouseX, mouseY);
            
            int index_c = 84-((mouseX-50)/8);
            if (index_c > 45){
                fill(200);
            } else {
                fill(0);
            }
            if (definite_color){
                value_c = int(map(index_c, 0, 84, 0, 4095));
            } else {
                value_c = int(map(index_c, 0, 84, min, max));
            }
            font = createFont("Arial", 16, true);
            textFont(font, 15);
            textAlign(CENTER);
            text(value_c, 25, height-20);

        }
        
    }
    //시리얼 통신
    myPort.write(data);
    while (myPort.available() > 0) {
        int xByte = myPort.readChar();
        if (xByte == 'H'){
            xByte = myPort.read();
            xByte = myPort.readChar();
            receiveMap();
        } else {
            println("Communication Error: Could not receive H");
        }
    }
    
    //합계 표시
    fill(#fcfdbf);
    stroke(0);
    rect(800, 150, 150, 30);
    fill(0);
    font = createFont("Arial", 16, true);
    textFont(font, 20);
    textAlign(CENTER);
    text("Summed value", 875, 140);
    textFont(font, 18);
    textAlign(CENTER);
    text(value_sum, 875, 170);
    

    
}
//receiveRow, receiveMap은 serial통신 관련 코드
void receiveRow(int i){
    int x = 0;
    while (x < ROWS){
        int HighByte = myPort.read();
        int LowByte = myPort.read();
        int high = byte(HighByte) & 0xFF;
        int low = byte(LowByte) & 0xFF;

        int val = 4096 - ((low << 8) + high);
        if (val < 0){
            println(val);
        }
        Values[x][i] = val;
        x++;
    }
    char xbyte = myPort.readChar();
    if (xbyte != '\n'){
        println("Communication Error");
    }
}

void receiveMap(){
    int y = 0;
    while (y < COLS){
        char xbyte = myPort.readChar();
        if (xbyte == 'M'){
            int int_xbyte = myPort.read();
            int xint = int_xbyte & 0xFF;
            if (xint == ROWS){
                int_xbyte = myPort.read();
                int_xbyte = int_xbyte & 0xFF;
                receiveRow(int_xbyte);
            }
        }
        y++;
    }
}
//값 출력용 함수
void printValues() {
    delay(30);
    if (!stop){
        value_sum = 0;
        for (int j = 0; j < COLS; j++) {       
            for (int i = ROWS-1; i >= 0; i--) { 
                //zeroing code    
                final_values[j][i] = Values[j][i]-zeroing_values[j][i];
                println(final_values[j][i], max); 
                // threshold
                if (final_values[j][i] < set_min && final_values[j][i] >= 0){ 
                    final_values[j][i] = 0;
                }       
                if (!view_minus && final_values[j][i]<0){
                    final_values[j][i] = 0;
                }
                //minus value관련 
                if (!sum_minus && final_values[j][i] >= 0){
                    value_sum+=final_values[j][i];
                } else if (sum_minus){
                    value_sum+=final_values[j][i];
                }
                
            }
        }
    }
    
    //min max 값 찾는 코드 (red scale에서 사용)
    int max_vals[] = {};
    int min_vals[] = {};
    for(int i=0; i<16; i++){
        max_vals = append(max_vals, max(final_values[i]));
        min_vals = append(min_vals, min(final_values[i]));
    }
    max = max(max_vals);
    min = min(min_vals);

    for (int j=0; j < COLS; j++){
        for (int i = ROWS-1; i >=0; i--){
            
            //16*16의 바둑판 설정                          
            
            //viridis scale
            //value_color = int(map(final_values[j][i], min, max, 0, 84)); //(상대값)
            //fill(unhex(viridis[value_color]));
            
            //magma scale
            //value_color = int(map(final_values[j][i], min, max, 0, 84)); //(상대값)
            
            //color mode
            if (definite_color){
                value_color = int(map(final_values[j][i], 0, 4095, 0, 84)); //절대값 범위 설정
            } else {
                value_color = int(map(final_values[j][i], min, max, 0, 84)); //(상대값)
            }                
            
            //threshold setting error 방지코드
            if (value_color < 0){
                value_color = 0;
            }
            fill(unhex(magma[value_color]));
            stroke(0);
            rect(i*cellSize+80, j*cellSize+80, cellSize, cellSize);
            //16*16칸에 해당하는 각 값들
            if (value_color > 45){
                fill(200);
            } else {
                fill(0);
            }
            
            font = createFont("Arial", 16, true);
            textFont(font, 18);
            textAlign(CENTER);
            text(final_values[j][i], i*cellSize+100, j*cellSize+108);
        }
    }
}
//새 창의 기본 세팅 설정
void set_min_max(PApplet appc, GWinData data){
    appc.background(230, 230, 255);
}
//threshold 설정 창 설정
void handleTextEvents(GEditableTextControl source, GEvent event) { 
  if (source == spn_min && event == GEvent.CHANGED) {
    println("Spinner on panel value: " + spn_min.getValue());
    this.set_min = spn_min.getValue();
  } 
}
//세팅 창 열기 버튼 설정
void btn_settings_click(GButton source, GEvent event){
    if (settings_window == null){
        create_window();
    } else {
        settings_window.setVisible(!settings_window.isVisible());
    }
}
//see minus value 버튼 설정
void set_minus_click(GButton source, GEvent event){
    if (view_minus == false){
        view_minus = true;
    } else {
        view_minus = false;
    }
    
}
//stop/continue 버튼 설정
void stop_continue_click(GButton source, GEvent event){
    if(stop == false){
        stop = true;
    } else {
        stop = false;
    }
} 
//Sum minus 버튼 설정
void sum_minus_click(GButton source, GEvent event){
    if (sum_minus == false){
        sum_minus = true;
    } else {
        sum_minus = false;
    }
}
//세팅의 zeroing 버튼 설정
void click_zeroing(GButton source, GEvent event){
    for (int j = 0; j < COLS; j++) {
        for (int i = ROWS-1; i >= 0; i--) {
            zeroing_values[j][i] = Values[j][i];
        }
    }
}
//세팅의 set default 버튼 설정
void click_default(GButton source, GEvent event){
    for (int j = 0; j < COLS; j++) {
        for (int i = ROWS-1; i >= 0; i--) {
            zeroing_values[j][i] = 0;
        }
    }
}
//세팅의 relative color 버튼 설정
void click_relative(GButton source, GEvent event){
    if (event == GEvent.CLICKED){
        definite_color = false;
    }
}
//세팅의 definite color 버튼 설정
void click_definite(GButton source, GEvent event){
    if (event == GEvent.CLICKED){
        definite_color = true;
    }
}
//새창의 구성요소 설정  
void create_window() {
    settings_window = GWindow.getWindow(this, "settings", 50, 50, 300, 300, JAVA2D);
    PApplet appc = settings_window;
  
    GLabel label1 = new GLabel(appc, 20, 40, 120, 38);
    label1.setText("lower threshold\n(0 ~ 4095)");
    label1.setTextAlign(GAlign.CENTER, GAlign.CENTER);
    label1.setOpaque(true);



    spn_min = new GSpinner(appc, 20, 80, 120, 20);

    spn_min.setLimits(set_min, 0, 4095, 1);

    settings_window.setActionOnClose(G4P.HIDE_WINDOW);
    settings_window.addDrawHandler(this, "set_min_max");
    
    GButton set_default = new GButton(appc, 160, 120, 120, 20);
    set_default.setText("Set default");
    set_default.addEventHandler(this, "click_default");

    GButton zeroing = new GButton(appc, 20, 120, 120, 20);
    zeroing.setText("Zeroing"); 
    zeroing.addEventHandler(this, "click_zeroing"); 

    GButton relative = new GButton(appc, 160, 170, 120, 20);
    relative.setText("Relative color");
    relative.addEventHandler(this, "click_relative");

    GButton definite = new GButton(appc, 20, 170, 120, 20);
    definite.setText("Definite color");
    definite.addEventHandler(this, "click_definite");
}
//기존창의 구성요소 설정
void createGUI() {
    G4P.messagesEnabled(false);
    G4P.setGlobalColorScheme(GCScheme.CYAN_SCHEME);
    G4P.setMouseOverEnabled(false);
    G4P.setDisplayFont("Arial", G4P.PLAIN, 16);
    surface.setTitle("Pressure test application");
    GButton btnAWTwindow = new GButton(this, 0, 0, 160, 30);
    btnAWTwindow.setText("Settings");
    btnAWTwindow.addEventHandler(this, "btn_settings_click");
    GButton sum_minus_values = new GButton(this, 800, 200, 160, 30);
    sum_minus_values.setText("Sum minus values");
    sum_minus_values.addEventHandler(this, "sum_minus_click");
    GButton see_minus_values = new GButton(this, 800, 250, 160, 30);
    see_minus_values.setText("See minus values");
    see_minus_values.addEventHandler(this, "set_minus_click");
    GButton stop_button = new GButton(this, 800, 300, 160, 30);
    stop_button.setText("Stop/Continue");
    stop_button.addEventHandler(this, "stop_continue_click");
    

}