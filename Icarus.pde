import processing.video.*;
import org.apache.http.HttpEntity;
import org.apache.http.HttpResponse;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.impl.client.DefaultHttpClient;

DefaultHttpClient httpClient;
Capture videoIn;
Map cached;
int pixelCount;
boolean videoOverlay = true;
int iconSize = 25;

void setup() {
  size(800,600);
  background(0);
  cached = new HashMap();

  videoIn = new Capture(this, width, height);
  videoIn.settings();

  noStroke();
  pixelCount = ceil(width / iconSize) * (ceil(height / iconSize) + 1);
}

boolean showingWall = false;
boolean beingAwesome = false;

// Do this.  All the time.
void draw() {
  if (!showingWall) {
    image(videoIn, 0, 0);
  }
  else {
    if (beingAwesome) {
      beAwesome();
    } 
    else {
      refreshWall(); 
    }
    if (videoOverlay) {
      tint(64, 130);
      image(videoIn, 0, 0);
      noTint();
    }
  }

  fill(mouseColour());
  ellipse(mouseX, mouseY, 75, 75);
}


boolean cachify = false;
void beAwesome() {
  int x = 0;
  int y = 0;
  showingWall = true;
  beingAwesome = true;
  boolean cachifyThisLoop = false;
  for (int i = 0; i < pixelCount - 1; i++) {
    int cx = x + floor(iconSize / 2);
    int cy = y + floor(iconSize / 2);

    if (cy <= height) {
      color c = videoIn.pixels[cx + (cy * width)];
      String roundedColour = roundColour(c);

      if (cached.containsKey(roundedColour)) {
        if (((ArrayList)cached.get(roundedColour)).size() >= 5) {
          image( (PImage)((ArrayList)cached.get(roundedColour)).get(i%5), x, y, iconSize, iconSize);
        } 
        else {
          print ("That thing happened again with " + roundedColour);
          print(cached.get(roundedColour));
          fill(c);
          rect(x, y, iconSize, iconSize);
        }
      } 
      else {
        if (!cachify && !cachifyThisLoop) {
          cachify = true;
          cachifyColour(roundedColour);
          cachifyThisLoop = true;
        }
        fill(c);
        rect(x, y, iconSize, iconSize);
      }
    }

    x += iconSize;
    if (x > width) {
      x = 0;
      y += iconSize;
    } 
  }
}

void refreshWall() {
  int x = 0;
  int y = 0;

  for (int i = 0; i < pixelCount; i++) {
    image((PImage)theImages.get(i%theImages.size()), x, y, iconSize, iconSize); 
    x += iconSize;
    if (x > width) {
      y += iconSize;
      x = 0;
    }
  }  
}

void cachifyColour(String colourStr) {
  if (cached.containsKey(colourStr)) {
    return;
  }

  ArrayList colourSet = new ArrayList();
  colourSet.add(colourStr);
  ArrayList urls = getImages(colourSet);

  ArrayList imagecache = new ArrayList();
  for (int i = 0; i < 5; i++) {
    imagecache.add((PImage)loadImage((String)urls.get(i)));
  }
  cached.put(colourStr, imagecache);
  cachify = false;
}

ArrayList theImages;
void showWall() {
  showingWall = true;
  int x = 0;
  int y = 0;

  ArrayList images = new ArrayList();

  if (colourSet.size() == 1 && cached.containsKey(colourSet.get(0))) {
    images = (ArrayList)cached.get(colourSet.get(0)); 
  } 
  else if (colourSet.size() == 1) {
    // Special case:  If showing the mosaic in one colour, cache the images.
    ArrayList urls = getImages(colourSet);
    ArrayList imagecache = (ArrayList)cached.get(colourSet.get(0));
    for (int i = 0; i < urls.size(); i++) {
      imagecache.add((PImage)loadImage((String)urls.get(i)));
    }
    cached.put(colourSet.get(0), imagecache);
    images = imagecache;
  } 
  else {
    ArrayList urls = getImages(colourSet);
    images = new ArrayList();
    for (int i = 0; i < urls.size(); i++) {
      images.add((PImage)loadImage((String)urls.get(i)));
    } 
  }

  theImages = images;

  if (images.size() == 0) {
    println("No images for colour : ");
    println(colourSet);
    return; 
  }
  for (int i = 0; i < pixelCount; i++) {
    image((PImage)images.get(i%images.size()), x, y, iconSize, iconSize);

    x += iconSize;
    if (x > width) {
      y += iconSize;
      x = 0;
    }
  }
}

// Get a collection of images that corresponds to a set of colours.
ArrayList getImages(ArrayList colourSet) {
  httpClient = new DefaultHttpClient();
  ArrayList urls = new ArrayList();
  String url = "http://piximilar.hackdays.tineye.com/rest/";
  try {
    ArrayList postData = new ArrayList();
    postData.add(new BasicNameValuePair("method", "color_search"));

    for (int i = 0; i < colourSet.size(); i++) {
      if (!cached.containsKey(colourSet.get(i))) {
        cached.put(colourSet.get(i), new ArrayList());
      }
      postData.add(new BasicNameValuePair("colors[" + i + "]", (String)colourSet.get(i)));
      postData.add(new BasicNameValuePair("weights[" + i + "]", Integer.toString(100/colourSet.size()) ));
    }

    HttpPost httpPost = new HttpPost(url);  
    httpPost.setEntity(new UrlEncodedFormEntity(postData));
    HttpResponse r = httpClient.execute(httpPost);
    HttpEntity en = r.getEntity();

    ByteArrayOutputStream stream = new ByteArrayOutputStream();
    if( en != null ) en.writeTo( stream );

    Pattern filenames = Pattern.compile("[0-9]+.jpg");
    String s = stream.toString();

    Matcher m = filenames.matcher(s);

    while(m.find()) {
      urls.add("http://piximilar.hackto.tineye.com/collection/?filepath=" + m.group());
    }
    httpClient.getConnectionManager().shutdown();

  } 
  catch( Exception e ) { 
    e.printStackTrace(); 
  }
  return urls;
}

color mouseColour() {
  return videoIn.pixels[mouseX + (mouseY * width)];  
}

int magicInt = 64;

String roundColour(color c) {
  String h = hex(c, 6);
  int r = floor(red(c)/magicInt) * magicInt;
  int g = ( floor(green(c)/magicInt) * magicInt) ;
  int b =  (floor(blue(c)/magicInt) * magicInt);

  return Integer.toString(r) + "," + Integer.toString(g) + "," + Integer.toString(b);
}

ArrayList colourSet = new ArrayList();
void mousePressed() {
  beingAwesome = false;
  if (colourSet.size() == 5) {
    colourSet.remove(0); 
  }
  colourSet.add(hex(mouseColour(), 6));

  showWall();
}

// Precache a bunch of images.  Like a jerk who is making a lot of API requests.
void beAJerk() {
  int r = 0;
  int g = 0;
  int b = 0;
  int magicInt = 64;
  for (r = 0; r < 255; r+= magicInt) {
    for (g = 0; g < 255; g+= magicInt) {
      for (b = 0; b < 255; b += magicInt) {
        println(Integer.toString(r) + "," + Integer.toString(g) + "," + Integer.toString(b));
        cachifyColour(Integer.toString(r) + "," + Integer.toString(g) + "," + Integer.toString(b));
      }
    }
  }
}

void keyPressed() {
  if (key == 'c') {
    colourSet = new ArrayList();
    showingWall = false;
    beingAwesome = false; // Oh for shame.
  } 
  
  // Precache a ton of images.  Feel a little bad about it for
  // hammering the API.
  if (key == 'j') {
    beAJerk();
  }

  // Hold on to your socks, things will get awesome if you
  // do this.
  if (key == 'f') {
    println("To The Awesome!");
    beAwesome(); // !! 
  }

  // Deeebug
  if (key == 'x') {
    print (cached.keySet()); 
  }

  // Change the colour-reproduction accuracy.
  if (key == '+') {
    magicInt /= 2; 
    println(magicInt);
  }

  if (key == '-') {
    magicInt *= 2; 
    println(magicInt);
  }

  if (key == 'q') {
    videoOverlay = !videoOverlay; 
  }
  
  // Pause/Resume the video feed
  if (key == 's') {
     keepReading = !keepReading; 
  }
  
  // Switch to tiny tiles
  if (key == 't') {
    iconSize = 25;
    pixelCount = ceil(width / iconSize) * (ceil(height / iconSize) + 1);
  }

  // Switch to standard sized tiles
  if (key == 'y') {
    iconSize = 75;
    pixelCount = ceil(width / iconSize) * (ceil(height / iconSize) + 1);
  }
}

boolean keepReading = true;
void captureEvent(Capture videoIn) {
  if (keepReading) {
    videoIn.read(); 
  }
}
