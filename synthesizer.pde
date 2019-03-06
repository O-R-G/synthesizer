// Synthesizer
// O-R-G
//
// based on tetracono and mtdbt2fx

import processing.pdf.*;

PFont font[];     // array of references to fonts
String fontnames[];         // original source names
int fontSize = 200;
int fontLength;  // length of font[] (computed when filled)
int thisFont; // pointer to font[] of currently selected
int pausedFont; // pointer to font[] where currently paused
int fontLoadStart = 0; // first numbered font to try
int fontLoadEnd = 49; // last numbered font to try 
int fontRangeStart; // pointer to font[], range min
int fontRangeEnd; // pointer to font[], range max
int fontRangeDirection = 1; // only two values, 1 or -1
    
boolean debug = true;
boolean createMTDBT2F4Dbusy = true; // when generating MTDBT2F4Ds

float[] dimensions;
int counter;
float adjustspeeds = 1.0;
float rotationX = 0.0;
float rotationY = 0.0;
float scale = 1.0;
float fov = PI/3.0;
boolean shiftpressed;
boolean saveframe;
boolean paused = false;
String typed = "S";

void setup() {
    createMTDBT2F4D();
    // size(720, 720, P3D);
    size(900, 1600, P3D);
    textSize(fontSize);
    textAlign(CENTER);
    noStroke();
    fill(255);
    updatePerspective(fov);
}

void draw() {
    if (saveframe)
        beginRaw(PDF, "output-####.pdf");

    translate(width/2, height/2);
    rotateY(rotationY);
    rotateX(rotationX);
    scale(scale);
    ambientLight(128, 128, 128);
    directionalLight(128, 128, 128, 0, 0, -1);
    lightFalloff(1, 0, 0);
    lightSpecular(128, 128, 128);
    shininess(2.0);
    ortho();

    // projected ornament
 
    if (paused)
        thisFont = pausedFont;

    background(0);

    for (int i=0; i<fontLength; i++) {
    	updatefont();
	    if (i == fontLength-1)
            fill(255);
	    else 
	        fill(255, 50);
        text(typed, 0, 0, i*5);
    }

    if (saveframe) {
        endRaw();
        saveframe = false;
    }

    if (debug) {
        // println(nf(((counter/30) / 1000) / 60, 2) + ":" + nf(((counter/30) / 1000) % 60, 2));
        println(nf((millis() / 1000) / 60, 2) + ":" + nf((millis() / 1000) % 60, 2));
        if (paused)
            println("** " + pausedFont + " **");
        println(typed);
    }
}

void updatePerspective(float fov) {
    float cameraZ = (height/2.0) / tan(PI*60.0/360.0);
    perspective(fov, float(width)/float(height), cameraZ/10.0, cameraZ*10.0);
}

void mouseDragged() {
    // global 3d controls
    if (shiftpressed) {
        float adjustY = abs(mouseY - height/2);
        scale = map(adjustY, 0, height/2, 0, height/100);   
    } else {
        float adjustX = mouseX - width/2;
        float adjustY = -1 * (mouseY - height/2);
        rotationX = map(adjustY, 0, height/2, 0, PI);
        rotationY = map(adjustX, 0, width/2, 0, PI);
        fov = map(adjustX, 0, width/2, PI/3.0, PI/1.0);   
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
        case '+':
            scale+=0.05;
            break;
        case '_':
            if (scale > 0.05)
                scale-=0.05;
            break;
        case '`':    
            saveframe = true;
            break;
        case ' ':    
	        paused = !paused;
            pausedFont = thisFont;
            break;

        /* type */

        case RETURN:
            typed = "";
            break;
        case ENTER:
            typed = "";
            break;
        case BACKSPACE:
            if (typed.length() > 0) {
                typed = typed.substring(0, typed.length()-1);
            }
            break;
        case DELETE:
            if (typed.length() > 0) {
                typed = typed.substring(0, typed.length()-1);
            }
            break;
        default:
            if (createMTDBT2F4Dbusy) {
                typed = "";
            }
            typed += key;
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

    // textMode(SHAPE); // outline fonts 
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
	// if (!paused) {
		if ((thisFont + fontRangeDirection >= fontRangeStart) && (thisFont + fontRangeDirection <= fontRangeEnd)) {
			thisFont += fontRangeDirection;        
		} else {            
			fontRangeDirection *= -1;
			thisFont += fontRangeDirection;
		}
	// }    		
	textFont(font[thisFont]);
}

