// Synthesizer
// O-R-G
//
// based on tetracono and mtdbt2fx

/*

    currently working on 3d output to .obj 
    use geomerative library to convert letter to a shape
    then get the points of that shape
    construct a 3d TRIANGLES mesh by drawing straight lines
    from point on one letter to matching point on second letter
    
    need to use .obj library to output file
    or use .dxf and then convert, but not ideal
    tried rhino but that seems too involved
    and better to use this so that looks exactly correct
    
    for another day ...

    https://forum.processing.org/one/topic/points-on-svg-shape
    https://n-e-r-v-o-u-s.com/tools/obj/

*/

import processing.pdf.*;
import processing.dxf.*;
import processing.sound.*;

SinOsc[] sines;         // sine wave oscillators
float[] frequencies;    // frequencies mapped to alphabet

PFont font[];           // references to fonts
String fontnames[];     // original source names
int fontSize = 100;
int fontLength;  // length of font[] (computed when filled)
int thisFont; // pointer to font[] of currently selected
int pausedFont; // pointer to font[] where currently paused
int fontLoadStart = 0; // first numbered font to try
int fontLoadEnd = 49; // last numbered font to try 
int fontRangeStart; // pointer to font[], range min
int fontRangeEnd; // pointer to font[], range max
int fontRangeDirection = 1; // only two values, 1 or -1
int counter;
int z = 0;
    
float[] dimensions;
float adjustspeeds = 1.0;
float rotationX = 0.0;
float rotationY = 0.0;
float scale = 1.0;
float fov = PI/3.0;
float wind = 0.0;

boolean debug = true;
boolean windy = false;
boolean createMTDBT2F4Dbusy = true; // when generating MTDBT2F4Ds
boolean shiftpressed;
boolean saveframe;
boolean pdf_3d = false;
boolean dxf_3d = false;
boolean paused = false;
boolean is_3d = true;
String typed = "";

void setup() {
    createMTDBT2F4D();
    size(720, 720, P3D);
    // size(900, 1600, P3D);    // vertical monitor
    textSize(fontSize);
    textAlign(CENTER, CENTER);
    noStroke();
    fill(255);
    updatePerspective(fov);
    init_sines(26);
    init_frequencies(26);
}

void draw() {

    if (saveframe)
        if (pdf_3d)
            beginRaw(PDF, "out/pdf/3d-####.pdf");           
        else if (dxf_3d)
            beginRaw(DXF, "out/dxf/3d-####.dxf");
        else
            beginRecord(PDF, "out/pdf/2d-####.pdf");    

    translate(width/2, height/2, 0);
    wind *= 1/1.001;
    rotateY(rotationY);
    rotateX(rotationX + wind);
    scale(scale);

    ambientLight(128, 128, 128);
    directionalLight(128, 128, 128, 0, 0, -1);
    lightFalloff(1, 0, 0);
    lightSpecular(128, 128, 128);
    shininess(2.0);
    ortho();
    
    if (paused)
        thisFont = pausedFont;

    // projected ornament

    background(0);

    // w/ 3d functionality ON
    if (is_3d) {
      for (int i=0; i<fontLength; i++) {
      	updatefont();
          z = (i - fontLength/2) * 5;
  	    if (i == fontLength-1)
          fill(255);
  	    else 
  	      fill(255, 50);
        text(typed, 0, 0, z);
      }
    }
    
    // w/ 3d functionality OFF, only 2D view
    else {
      int i = 0;
      updatefont();
      z = (i - fontLength/2) * 5;
      fill(255);
      text(typed, 0, 0, z);
    }

    if (saveframe) {
        if (pdf_3d || dxf_3d)
            endRaw();
        else
            endRecord();
        saveframe = false;
    }

    if (debug) {
        // println(nf(((counter/30) / 1000) / 60, 2) + ":" + nf(((counter/30) / 1000) % 60, 2));
        // println(nf((millis() / 1000) / 60, 2) + ":" + nf((millis() / 1000) % 60, 2));
        if (paused)
            println("** " + pausedFont + " **");
        // println(typed);
        // println(rotationX + " : " + rotationY);
    }
}

void updatePerspective(float fov) {
    float cameraZ = (height/2.0) / tan(PI*60.0/360.0);
    perspective(fov, float(width)/float(height), cameraZ/10.0, cameraZ*10.0);
}

void mouseDragged() {
    // global 3d controls
    if (is_3d == true) { 
      
      if (shiftpressed) {
        float adjustY = abs(mouseY - height/2);
        scale = map(adjustY, 0, height/2, 0, height/100);   
        update_amplitude(typed, map(scale, 0, 2.0, 0.0, 1.0));
      } else {
        float adjustX = mouseX - width/2;
        float adjustY = -1 * (mouseY - height/2);
        rotationX = map(adjustY, 0, height/2, 0, PI);
        rotationY = map(adjustX, 0, width/2, 0, PI);
        // float pan = map(adjustX, 0, width/2, -1.0, 1.0);
        // update_pan(typed, pan);
        fov = map(adjustX, 0, width/2, PI/3.0, PI/1.0);
      }
      
    }
}

void keyPressed() {
    if (key == CODED) {
        if (keyCode == SHIFT) {
            shiftpressed = true;
        }
    }
    switch(key) {

        /* control */

        case '=':
            adjustspeeds++;
            break;
        case '-':
            if (adjustspeeds > 1.0)
                adjustspeeds--;
            break;
        case '!':
            windy=!windy;
            if (windy) 
                wind = 10.0;
            else 
                wind = 0.0;
            break;
        case '`':    
            saveframe = true;
            break;
        case ' ':    
	        paused = !paused;
            pausedFont = thisFont;
            if (paused)
                stop_sines(typed);
            else
                play_sines(typed);
            break;
        case '2': 
          is_3d = !is_3d;
          if (is_3d == false) {
            rotationX = 0.0;
            rotationY = 0.0;
            z = 0;
            stop_sines(typed);
          } else {
            play_sines(typed);
          }
          break;

        /* type */

        case RETURN:
        case ENTER:
            for (int i=typed.length()-1; i>=0; i--)
                stop_sine(i);
            typed = "";
            break;
        case BACKSPACE:
        case DELETE:
            if (typed.length() > 0) {
                typed = typed.substring(0, typed.length()-1);
                int i = typed.length();
                stop_sine(i);
            }
            break;
        default:
            if (createMTDBT2F4Dbusy) {
                typed = "";
            }

            // valid letter? convert to uppercase
                
            int key_in_range = 0;  
            if (int(key) >= 65 && int(key) <= 90)
                key_in_range = int(key);        
            else if (int(key) >= 97 && int(key) <= 122)
                key_in_range = key-32;          
            if (key_in_range != 0) {
                typed += char(key_in_range);
                int i = typed.length()-1;
                if (!paused) {
                    set_frequency(i, ascii_to_index(key_in_range));
                    play_sine(i);
                }
            }
            break;
    }
}

void keyReleased() {
    shiftpressed = false;
}

void createMTDBT2F4D() {

    String fontDataFolder = "fonts/"; 

    // createFont() works either from data folder or from installed fonts
    // renders with installed fonts if in regular JAVA2D mode
    // the fonts installed in sketch data folder make it possible to export standalone app
    // but the performance seems to suffer a little. also requires appending extension .ttf
    // biggest issue is that redundantly named fonts create referencing problems
    // outline fonts look crisp, but run slow
    // .vlw fonts run fast, but are bitmapped
        
    if (pdf_3d || dxf_3d)
        textMode(SHAPE);    // outline fonts 
    else
        textMode(MODEL);    // .vlw texture fonts
      
    int fontLoadLimit = fontLoadEnd - fontLoadStart;
    font = new PFont[fontLoadLimit];
    fontnames = new String[fontLoadLimit];
    fontLength = 0; // reset
    
    for ( int i = 0; i < fontLoadLimit; i++ ) {
        String fontStub = fontDataFolder + "/mtdbt2f4d-" + i + ".ttf"; // from sketch /data

        if ( createFont(fontStub, fontSize, true) != null ) {
            font[fontLength] = createFont(fontStub, fontSize, true);
            fontnames[fontLength] = "mtdbt2f4d-" + i;
            if (debug) {
                println("/mtdbt2f4d-" + i + ".ttf" + " ** OK **");
            }
        fontLength++;
        }
    }

    fontRangeStart = 0;
    fontRangeEnd = fontLength-1;
    thisFont = fontRangeStart;

    if (debug) {
        println("###################################");
        println("fontRangeStart = " + fontRangeStart);
        println("fontRangeEnd = " + fontRangeEnd);
        println("fontLoadLimit = " + fontLoadLimit);
        println("fontLength = " + fontLength);
        println("font.length = " + font.length);
        println("###################################");
        println("** init complete -- " + fontLength + " / " + font.length + " **");
    }
    createMTDBT2F4Dbusy = false;
}

void updatefont() {
  if ((thisFont + fontRangeDirection >= fontRangeStart) && (thisFont + fontRangeDirection <= fontRangeEnd)) {			
    thisFont += fontRangeDirection;        
  } else {            
    fontRangeDirection *= -1;
		thisFont += fontRangeDirection;
	}
	textFont(font[thisFont]);
}

/*

    build frequencies[] and map to alphabet
    build sines[], an array of oscillators (static)
    then set frequency of next sines[] when key is pressed
    based on mapping from ascii code to index of frequencies[]

*/

void init_sines(int count) {

    // build placeholder array of sine oscillator objects
    // static for practical, but could be a list 

    sines = new SinOsc[count];

    for (int i=0; i<count; i++) {
        sines[i] = new SinOsc(this);
    }

    printArray(sines);
}

void init_frequencies(int count) {

    // build array of sine oscillator frequencies
    // mapped to the capital letters of the alphabet
    // [0-25]

    frequencies = new float[count];

    for (int i=0; i<count; i++) {
        frequencies[i] = 440*5/(i+1);
    }

    printArray(frequencies);
}

int ascii_to_index(int index) {

    // take ascii code in range
    // convert to corresponding index in frequencies[]
    // ascii -- lc 97-122, uc 65-90
    // function expects only values between 65-90
    // as key is converted from lc -> uc in keyDown
    // subtract 65 to correspond to sines[]

    index-=65;
    return index;
}

void set_frequency(int i, int index) {

    // use ascii_to_index to address frequencies[]
    // assign existing sine a frequency based on key

    sines[i] = new SinOsc(this);
    sines[i].freq(frequencies[index]);
}

void play_sine(int i) {
    sines[i].play();
}

void stop_sine(int i) {
    sines[i].stop();
}

void play_sines(String typed) {
    int i = 0;
    while (i < typed.length()) {
        play_sine(i);
        i++;
    }
}

void stop_sines(String typed) {
    int i = 0;
    while (i < typed.length()) {
        stop_sine(i);
        i++;
    }
}

void update_amplitude(String typed, float amplitude) {
    int i = 0;
    while (i < typed.length()) {
        sines[i].amp(amplitude);
        i++;
    }
}

void update_pan(String typed, float pan) {
    int i = 0;
    while (i < typed.length()) {
        sines[i].pan(pan);
        i++;
    }
}
