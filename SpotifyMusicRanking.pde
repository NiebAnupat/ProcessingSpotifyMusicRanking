
import org.json.*;
import java.net.*;
import java.io.*;
import java.util.*;
import processing.core.PApplet;

class MusicTrack {
    private String name;
    private int popularity;
    
    public MusicTrack(String name, int popularity) {
        this.name = name;
        this.popularity = popularity;
    }
    
    public String getName() {
        return name;
    }
    
    public int getPopularity() {
        return popularity;
    }
    
    public void setName(String name) {
        this.name = name;
    }
    
    public void setPopularity(int popularity) {
        this.popularity = popularity;
    }
}

class BarData {
    private String name;
    private int popularity;
    private int r;
    private int g;
    private int b;
    private int x;
    private int y;
    private float targetWidth;
    private float currentWidth;
    private float animSpeed = 0.1;
    
    public BarData(String name, int popularity, int x, int y) {
        this.name = name;
        this.popularity = popularity;
        this.x = x;
        this.y = y;
        this.r = (int) random(0, 255);
        this.g = (int) random(0, 255);
        this.b = (int) random(0, 255);
        this.targetWidth = map(popularity, 0, maxPopularity, 0, 75);
        this.currentWidth = 0;
    }
    
    public String getName() {
        return name;
    }
    
    public int getPopularity() {
        return popularity;
    }
    
    public void setName(String name) {
        this.name = name;
    }
    
    public void setPopularity(int popularity) {
        this.popularity = popularity;
        this.targetWidth = map(popularity, 0, maxPopularity, 0, 75);
    }
    
    public int getR() {
        return r;
    }
    
    public int getG() {
        return g;
    }
    
    public int getB() {
        return b;
    }
    
    public int getX() {
        return x;
    }
    
    public int getY() {
        return y;
    }
    
    public void animate() {
        currentWidth = lerp(currentWidth, targetWidth, animSpeed);
    }
    
    public float getCurrentWidth() {
        return currentWidth;
    }
}

String token;
MusicTrack top10List[] = new MusicTrack[10];
BarData barData[] = new BarData[10];
int barWidth = 100;
int maxPopularity = 100;
int chartWidth = 800;
int chartHeight = 600;
int loadingFrame = 0;
int loadingFrames = 40; // number of frames in the loading animation

int startPhase = 0;

public void settings() {
    size(chartWidth + (chartWidth / 2), chartHeight + (chartHeight / 2));
}

void setup() {
    background(255);
    getNewToken(); // Get initial token
    frameRate(30);
    
}
void draw() {
    background(255);
    drawHeader();
    
    switch(startPhase) {
        case 0:
            drawLoading();
            if (loadingFrame == loadingFrames - 1) {
                startPhase++;;
            }
            break;
        case 1:
            initBarData();
            startPhase++;
            break;
        case 2:
            drawChart();
            break;
    }
    
    
}

void keyPressed() {
    if (key == 'r') {
        startPhase = 0;
    }
}

void drawHeader() {
    textSize(20);
    textAlign(CENTER);
    
    String date = String.format("Last updated : %tF", new Date());
    textSize(14);
    fill(50);
    text(date,(int) textWidth(date) - (((int) textWidth(date)) / 2) + 10, 20);
    
    fill(0);
    textSize(30);
    text("Top 10 Music From Spotify", width / 2,(height - chartHeight) / 2 - 90);
    textSize(18);
    text("Popularity calculated by Spotify's algorhythm", width / 2,(height - chartHeight) / 2 - 60);
    textSize(15);
    text("Press 'r' to refresh data", width / 2,(height - chartHeight) / 2 - 30);
    textSize(18);
    textAlign(LEFT);
}


void drawLoading() {
    // draw loading animation
    float loadingAngle = map(loadingFrame, 0, loadingFrames, 0, TWO_PI);
    float loadingSize = map(sin(loadingAngle), -1, 1, 10, 50);
    noFill();
    stroke(0);
    strokeWeight(3);
    ellipse(width / 2, height / 2, loadingSize, loadingSize);
    
    fill(0);
    textSize(20);
    textAlign(CENTER);
    text("Loading...", width / 2, height / 2 + 50);
    
    //update loading animation frame
    loadingFrame = (loadingFrame + 1) % loadingFrames;
    
}

void drawChart() {
    // draw bar chart
    for (int i = 0; i < barData.length; i++) {
        fill(barData[i].getR(), barData[i].getG(), barData[i].getB());
        rect(barData[i].getX(), barData[i].getY(), 75, chartHeight / 10);
        
        fill(0);
        text(barData[i].getName(), barData[i].getX() + barWidth + 10, barData[i].getY() + chartHeight / 20);
        
        // animate bar chart
        barData[i].animate();
        
        fill(barData[i].getR(), barData[i].getG(), barData[i].getB());
        rect(barData[i].getX() + barWidth + 10, barData[i].getY() + chartHeight / 20 + 10, barData[i].getCurrentWidth() * 10, 20);
        
        fill(250);
        text(String.format("Popularity : %d", barData[i].getPopularity()),barData[i].getX() + barWidth + 10 + barData[i].getCurrentWidth() * 10 / 2, barData[i].getY() + chartHeight / 20 + 10 + 15);
    }
}


void initBarData() {
    fetchData();
    // fill barData with data
    int startX = (width - chartWidth) / 2; // calculate X coordinate of the starting position
    int startY = (height - chartHeight) / 2; // calculate Y coordinate of the starting position
    int barHeight = chartHeight / 10; // calculate height ofeach bar
    int barSpacing = 10; // spacing between bars
    int barX = startX; // X coordinate of the bar
    int barY = startY; // Y coordinate of the bar
    for (int i = 0; i < top10List.length; i++) {
        barData[i] = new BarData(top10List[i].getName(), top10List[i].getPopularity(), barX, barY);
        barY += barHeight + barSpacing;
    }
}

void fetchData() {
    try {        
        var connection = (HttpURLConnection)new URL("https://api.spotify.com/v1/playlists/37i9dQZEVXbMDoHDwVN2tF/tracks?limit=10&fields=items(track(name%2Cpopularity))").openConnection();
        connection.setRequestMethod("GET");
        connection.setRequestProperty("Authorization", "Bearer " + token);
        var responseCode = connection.getResponseCode();
        if (responseCode == HttpURLConnection.HTTP_UNAUTHORIZED) {
            println("Error: Unauthorized");
            getNewToken(); // Get new token and try again
        } else if (responseCode == HttpURLConnection.HTTP_OK) {
            InputStream inputStream = connection.getInputStream();
            
            // read all the text returned 
            Scanner scanner = new Scanner(inputStream).useDelimiter("\\A");
            String response = scanner.hasNext() ? scanner.next() : "";
            scanner.close();
            
            // parseJSON
            org.json.JSONObject data = new org.json.JSONObject(response);
            org.json.JSONArray items = data.getJSONArray("items");
            
            // fill top10List with data
            for (int i = 0; i < items.length(); i++) {
                org.json.JSONObject item = items.getJSONObject(i);
                org.json.JSONObject track = item.getJSONObject("track");
                top10List[i] = new MusicTrack(track.getString("name"), track.getInt("popularity"));
            }
            
            
        } else {
            println("Error: Response code " + responseCode);
        }
        
    } catch(Exception e) {
        println("Error  : " + e.getMessage());
    } 
    
}

void getNewToken() {
    
    try {
        var connection = (HttpURLConnection) new URL("https://accounts.spotify.com/api/token").openConnection();
        connection.setRequestMethod("POST");
        connection.setDoOutput(true);
        
        //Spotify - Client Credentials flow
        String clientId = "b0fefeb78fd24f4290299ea8c2ea5779";
        String clientSecret = "0a7a45f73fc64f43a4413449eb07cf9d";
        String auth = clientId + ":" + clientSecret;
        String encodedAuth = Base64.getEncoder().encodeToString(auth.getBytes());
        
        // set headers
        connection.setRequestProperty("Authorization", "Basic " + encodedAuth);
        connection.setRequestProperty("Content-Type", "application/x-www-form-urlencoded");
        
        String urlParameters = "grant_type=client_credentials";
        DataOutputStream wr = new DataOutputStream(connection.getOutputStream());
        wr.writeBytes(urlParameters);
        wr.flush();
        wr.close();
        
        var responseCode = connection.getResponseCode();
        if (responseCode == HttpURLConnection.HTTP_OK) {
            var inputStream = connection.getInputStream();
            var response = new BufferedReader(new InputStreamReader(inputStream)).readLine();
            var data = new org.json.JSONObject(response);
            token = data.getString("access_token");
        } else {
            println("Error: Response code " + responseCode);
        }
    } catch(Exception e) {
        println("Error  : " + e.getMessage());
    }
    
}
