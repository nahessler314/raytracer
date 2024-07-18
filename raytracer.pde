String input =  "data/tests/milestone4/test3.json";
String output = "data/tests/milestone4/test3.png";
int repeat = 0;

int iteration = 0;

// If there is a procedural material in the scene,
// loop will automatically be turned on if this variable is set
boolean doAutoloop = true;

/*// Animation demo:
String input = "data/tests/milestone3/animation1/scene%03d.json";
String output = "data/tests/milestone3/animation1/frame%03d.png";
int repeat = 100;
*/


RayTracer rt;

void setup() {
  size(640, 640);
  noLoop();
  if (repeat == 0)
      rt = new RayTracer(loadScene(input));  
  
}

void draw () {
  background(255);
  if (repeat == 0)
  {
    PImage out = null;
    if (!output.equals(""))
    {
       out = createImage(width, height, RGB);
       out.loadPixels();
    }
    for (int i=0; i < width; i++)
    {
      for(int j=0; j< height; ++j)
      {
        color c = rt.getColor(i,j);
        set(i,j,c);
        if (out != null)
           out.pixels[j*width + i] = c;
      }
    }
    
    // This may be useful for debugging:
    // only draw a 3x3 grid of pixels, starting at (315,315)
    // comment out the full loop above, and use this
    // to find issues in a particular region of an image, if necessary
    /*for (int i = 0; i< 3; ++i)
    {
      for (int j = 0; j< 3; ++j)
         set(315+i,315+j, rt.getColor(315+i,315+j));
    }*/
    
    if (out != null)
    {
       out.updatePixels();
       out.save(output);
    }
    
  }
  else
  {
     // With this you can create an animation!
     // For a demo, try:
     //    input = "data/tests/milestone3/animation1/scene%03d.json"
     //    output = "data/tests/milestone3/animation1/frame%03d.png"
     //    repeat = 100
     // This will insert 0, 1, 2, ... into the input and output file names
     // You can then turn the frames into an actual video file with e.g. ffmpeg:
     //    ffmpeg -i frame%03d.png -vcodec libx264 -pix_fmt yuv420p animation.mp4
     String inputi;
     String outputi;
     for (; iteration < repeat; ++iteration)
     {
        inputi = String.format(input, iteration);
        outputi = String.format(output, iteration);
        if (rt == null)
        {
            rt = new RayTracer(loadScene(inputi));
        }
        else
        {
            rt.setScene(loadScene(inputi));
        }
        PImage out = createImage(width, height, RGB);
        out.loadPixels();
        for (int i=0; i < width; i++)
        {
          for(int j=0; j< height; ++j)
          {
            color c = rt.getColor(i,j);
            out.pixels[j*width + i] = c;
            if (iteration == repeat - 1)
               set(i,j,c);
          }
        }
        out.updatePixels();
        out.save(outputi);
     }
  }
  updatePixels();


}

class Ray
{
     PVector origin;
     PVector direction;
  
     Ray(PVector origin, PVector direction)
     {
        this.origin = origin;
        this.direction = direction;
     }
}

// TODO: Start in this class!
class RayTracer
{
    Scene scene;  
    
    RayTracer(Scene scene)
    {
      setScene(scene);
    }
    
    void setScene(Scene scene)
    {
       this.scene = scene;
    }
    
    color getColor(int x, int y)
    { 
      PVector origin = this.scene.camera;
      
      Ray ray = new Ray(origin, direction(x, y));
      
      try {
        ArrayList<RayHit> hits = this.scene.root.intersect(ray);
        if (hits.size() > 0 && hits.get(0).entry) {
          color impactColor = surfaceColor(hits.get(0), ray.origin);
          
          if (this.scene.reflections > 0) {
            return reflectiveColor(ray, impactColor, 0);
          }
          
          return impactColor;
        }
      }
      catch (Exception e) {
        println(e);
      }
      
      /// this will be the fallback case
      return this.scene.background;
    }
    
    // Viewing direction with camera position/placement and rotation
    PVector direction(int x, int y)
    {
      float w = width; // Width from size() in setup()
      float h = height; // Height from size() in setup()
      PVector globalUpDirection = new PVector(0, 0, 1);
      PVector leftDirection = new PVector();
      PVector upDirection = new PVector();
      
      PVector.cross(globalUpDirection, this.scene.view, leftDirection);
      PVector.cross(this.scene.view, leftDirection, upDirection);
      
      float fovFactor = tan(this.scene.fov / 2.0);
      
      float u = -1 * ((x*1.0)/w - 0.5) * fovFactor; // Horizontal scaling
      float v = -1 * ((y*1.0)/h - 0.5) * fovFactor; // Vertical scaling
      
      return PVector.add(PVector.add(PVector.mult(leftDirection.normalize(), u), PVector.mult(upDirection.normalize(), v)), PVector.mult(this.scene.view, 0.5)).normalize();
    }
    
    // The color of object surface with Phong lighting and simple shadow
    color surfaceColor(RayHit hit, PVector ray_origin)
    {
      return this.scene.lighting.getColor(hit, this.scene, ray_origin);
    }
    
    // The reflection color of ibject surface
    color reflectiveColor(Ray r, color result, int reflectCount)
    {
      int LIMIT = this.scene.reflections;
      ArrayList<RayHit> hits = this.scene.root.intersect(r);
      
      if (hits.size() > 0 && hits.get(0).entry) {
        RayHit hit = hits.get(0);
        float reflectiveness = hit.material.properties.reflectiveness;
        result = surfaceColor(hit, r.origin);
        
        if (reflectiveness == 0)
          return result;
        else if (reflectCount >= LIMIT)
          return scene.background;
        
        PVector impactedPoint = PVector.add(hit.location, PVector.mult(hit.normal, EPS));
        PVector reflectDirection = PVector.sub(PVector.mult(PVector.mult(hit.normal, 2), PVector.dot(hit.normal, PVector.mult(r.direction, -1))), PVector.mult(r.direction, -1)).normalize();
        Ray reflectRay = new Ray(impactedPoint, reflectDirection);
        result = lerpColor(result, reflectiveColor(reflectRay, result, ++reflectCount), reflectiveness);
      }
      else 
        result = scene.background;
      return result;
    }
}
