class Sphere implements SceneObject
{
    PVector center;
    float radius;
    Material material;
    
    Sphere(PVector center, float radius, Material material)
    {
       this.center = center;
       this.radius = radius;
       this.material = material;
    }
    
    ArrayList<RayHit> intersect(Ray r)
    {
        ArrayList<RayHit> result = new ArrayList<RayHit>();
        
        /* Method 1: Using the projection of the sphere center onto the ray
          - Equations => t_p = (c - o).d ; P = o + t_p*d ; t = t_p +/- sqrt(r^2 - x^2)
            Note:
              t_p = scaler value where the ray gets closest to the sphere
              c = sphere center
              r = sphere radius
              o = ray origin
              d = ray direction
              P = the closest point on the ray to the sphere center
              x = |P - c| ; distance from P to sphere center
              t = hit distance from the ray origin
          - If (x <= sphere radius) then the ray hits the sphere, else no hits
          - Apply y(t) = o + t*d to find the intersected coordinates
          - The normal of impacted point = (intersected point) - (sphere center)
        */
        float t_p = PVector.dot(PVector.sub(this.center, r.origin), r.direction);
        float x = PVector.sub(PVector.add(r.origin, PVector.mult(r.direction, t_p)), this.center).mag();
        
        if (x <= this.radius) { // There are 1 or 2 intersecting points between the ray and sphere
          
          ArrayList<Float> ts = new ArrayList<Float>();
          ts.add(t_p - sqrt(this.radius*this.radius - x*x));
          if (x < this.radius)
            ts.add(t_p + sqrt(this.radius*this.radius - x*x));
          
          for (int i = 0; i < ts.size(); i++) {
            if (ts.get(i) > 0) {
              RayHit hit = new RayHit();
              hit.t = ts.get(i);
              hit.location = PVector.add(r.origin, PVector.mult(r.direction, ts.get(i)));
              hit.normal = PVector.sub(hit.location, this.center).normalize();
              hit.material = this.material;
              hit.u = texU(hit.normal.x, hit.normal.y);
              hit.v = texV(hit.normal.z);
              if (i == 0 && PVector.dot(hit.normal, r.direction) < 0)
                hit.entry = true;
              else
                hit.entry = false;
              result.add(hit);
            }
          }
          
          /*
          for (int i = 0; i < ((x < this.radius) ? 2 : 1); i++) {
            RayHit hit = new RayHit();
            if (i == 0) 
              hit.t = t_p + sqrt(this.radius*this.radius - x*x);
            else 
              hit.t = t_p - sqrt(this.radius*this.radius - x*x);
            
            if (hit.t > 0) {
              hit.location = PVector.add(r.origin, PVector.mult(r.direction, hit.t));
              hit.normal = PVector.sub(hit.location, this.center).normalize();
              hit.material = this.material;
              hit.u = texU(hit.normal.x, hit.normal.y);
              hit.v = texV(hit.normal.z);
              hit.entry = false;
              result.add(hit);
            }
          }
          
          
          // Set the entry point where the ray first hit the sphere
          if (result.size() > 0) {
            result.sort(new HitCompare());
            result.get(0).entry = true;
          }*/
        }
        return result;
    }
    
    float texU(float n_x, float n_y)
    {
        return 0.5 + atan2(n_y, n_x) / (2 * PI);
    }
    
    float texV(float n_z)
    {
        return 0.5 - asin(n_z) / PI;
    }
}

class Plane implements SceneObject
{
    PVector center;
    PVector normal;
    float scale;
    Material material;
    PVector left;
    PVector up;
    boolean insidePlaneChecked; // True if inside plane is already checked.
    boolean isInsidePlane; // True if the ray origin is inside/behind a plane.
    
    Plane(PVector center, PVector normal, Material material, float scale)
    {
       this.center = center;
       this.normal = normal.normalize();
       this.material = material;
       this.scale = scale;
       this.insidePlaneChecked = false;
       this.isInsidePlane = false;
    }
    
    ArrayList<RayHit> intersect(Ray r)
    {
        ArrayList<RayHit> result = new ArrayList<RayHit>();
        float dn = PVector.dot(r.direction, this.normal);
        
        if (dn != 0) {
          float t = PVector.dot(PVector.sub(this.center, r.origin), this.normal) / dn;
          PVector y_t = PVector.add(r.origin, PVector.mult(r.direction, t));
          if (t > 0) {
            RayHit hit = new RayHit();
            hit.t = t;
            hit.location = y_t;
            hit.normal = this.normal;
            hit.entry = (dn < 0);
            hit.material = this.material;
            PVector z = new PVector(0,0,1),
                    r_, u_;
            if (hit.normal.equals(z)) {
              r_ = new PVector(0,1,0);
            }
            else {
              r_ = z.cross(this.normal).normalize();
            }
            u_ = hit.normal.cross(r_).normalize();
            PVector d = PVector.sub(hit.location, this.center);
            float x = PVector.dot(d, r_) / this.scale,
                  y = PVector.dot(d, u_) / this.scale;
            hit.u = x - floor(x);
            hit.v = (-y) - floor(-y);
            result.add(hit);
          }
        }     
        return result;
    }
    
    @Override
    boolean isInsideObject(ArrayList<RayHit> hits, Ray r)
    {
        if (insidePlaneChecked)
          return isInsidePlane;
        Ray sub_r = new Ray(r.origin, this.normal);
        ArrayList<RayHit> sub_hits = intersect(sub_r);
        isInsidePlane = sub_hits.size() > 0 && !(sub_hits.get(0).entry);
        insidePlaneChecked = true;
        return isInsidePlane;
    }
}

class Triangle implements SceneObject
{
    PVector v1;
    PVector v2;
    PVector v3;
    PVector normal;
    PVector tex1;
    PVector tex2;
    PVector tex3;
    Material material;
    
    Triangle(PVector v1, PVector v2, PVector v3, PVector tex1, PVector tex2, PVector tex3, Material material)
    {
       this.v1 = v1;
       this.v2 = v2;
       this.v3 = v3;
       this.tex1 = tex1;
       this.tex2 = tex2;
       this.tex3 = tex3;
       this.normal = PVector.sub(v2, v1).cross(PVector.sub(v3, v1)).normalize();
       this.material = material;
    }
    
    ArrayList<RayHit> intersect(Ray r)
    {
        ArrayList<RayHit> result = new ArrayList<RayHit>();
        
        /* Method:
          - Calculate if the ray intersects the plane: t = ((v-o).n) / (d.n)
            Note:
              v = any vertice v1, v2, or v3 (anyother arbitrary point on the plane would work)
              n = normal of the plane, which direction of the normal determines the entry surface of the plane
              o = ray origin
              d = ray direction
              t = hit distance from the ray origin
          - First, ensure d.n is not 0, which d.n = 0 means d and n are orthogonal, where ray is parallel and never hits the plane.
          - If t > 0, then the ray intersects the plane t distance from the ray origin (in front of the camera).
          - If ray intersects the plane, then determine if the intersect point is in the triangle or not.
            - By method PointInTriangle()
            - Use (p = o + t*d) to find the intersect point p, where the ray intersects the plane.
            
            
          - To determine if the intersect point is entry or exit, it's entry when d.n < 0, otherwise it's exit.
            Note: THIS WILL COME IN-USE FOR MILESTONE 2
        */
        
        float dn = PVector.dot(r.direction, this.normal); // The dot product of d and n
        if (dn != 0) {
          float t = PVector.dot(PVector.sub(this.v1, r.origin), this.normal) / dn;
          PVector p = PVector.add(r.origin, PVector.mult(r.direction, t));
          HashMap<String, Float> pair = computeUV(this.v3, this.v1, this.v2, p);
          float w = 1.0 - (pair.get("u") + pair.get("v"));
          
          if ((t > 0) && isPointInTriangle(pair)) {
            RayHit hit = new RayHit();
            hit.t = t;
            hit.location = p;
            hit.normal = this.normal;
            hit.entry = (dn < 0); // Check if the intersect point is an entry or exit
            hit.material = this.material;
            hit.u = texU(pair.get("u"), pair.get("v"), w);
            hit.v = texV(pair.get("u"), pair.get("v"), w);
            result.add(hit);
          }
        }
        return result;
    }
    
    // Determine if the intersect point is located inside the triangle
    Boolean isPointInTriangle(HashMap<String, Float> pair)
    {
      return (pair.get("u") >= 0) && (pair.get("v") >= 0) && (pair.get("u") + pair.get("v") < 1); 
    }
    
    // Find the U and V scaler values that help to determine if the point is inside the triangle
    HashMap<String, Float> computeUV(PVector a, PVector b, PVector c, PVector p)
    {
      HashMap<String, Float> pair = new HashMap<String, Float>();
      PVector e = PVector.sub(b, a);
      PVector g_ = PVector.sub(c, a);
      PVector d = PVector.sub(p, a);
      float denom = (PVector.dot(e, e) * PVector.dot(g_, g_)) - (PVector.dot(e, g_) * PVector.dot(g_, e));
      
      float u = ((PVector.dot(g_, g_) * PVector.dot(d, e)) - (PVector.dot(e, g_) * PVector.dot(d, g_))) / denom;
      float v = ((PVector.dot(e, e) * PVector.dot(d, g_)) - (PVector.dot(e, g_) * PVector.dot(d, e))) / denom;
      pair.put("u", u);
      pair.put("v", v);
      
      return pair; 
    }
    
    float texU(float u, float v, float w)
    {
      return tex1.x*u + tex2.x*v + tex3.x*w;
    }
    
    float texV(float u, float v, float w)
    {
      return tex1.y*u + tex2.y*v + tex3.y*w;
    }
}

class Cylinder implements SceneObject
{
    float radius;
    float height;
    Material material;
    float scale;
    
    Cylinder(float radius, Material mat, float scale)
    {
       this.radius = radius;
       this.height = -1;
       this.material = mat;
       this.scale = scale;
       
       // remove this line when you implement cylinders
       //throw new NotImplementedException("Cylinders not implemented yet");
    }
    
    
    // TODO: Check if the ray/camera origin is inside the cylinder
    Cylinder(float radius, float height, Material mat, float scale)
    {
       this.radius = radius;
       this.height = height;
       this.material = mat;
       this.scale = scale;
    }
    
    ArrayList<RayHit> intersect(Ray r)
    {
        ArrayList<RayHit> result = new ArrayList<RayHit>();
        
        /* Method (a cylinder with radius r, centered at the origin, revolved around z-axis and infinite in height):
          - Change the camera's origin (0,0,0) to anywhere outside the cylinder radius.
          - Cylinder Equation (at origin): (dx^2 + dy^2)*t^2 + (2(ox*dx + oy*dy))*t + (ox^2 + oy^2 - r^2) = 0
            Note:
              t = hit distance from ray origin to cylinder surface
              d = ray direction
              o = ray origin
              r = cylinder radius
          - Simpliy the equation with coefficients: a*t^2 + b*t + c = 0
          - Use quadratic formula to find t: t = (-b +/- sqrt(b^2 - 4*a*c)) / (2*a)
          - Use the discriminant to find the number of intersected points => discriminant = b^2 - 4ac
          - Ensure t > 0, which indicates the intersected points are in front of the camera
          - Use (p = o + t*d) to find the intersect point p
          - The normal n of each point on cylinder surface:
            - n = (px, py, pz) - (0, 0, pz) = (px, py, 0) 
            - Basically, the normal is the intersected point p with pz = 0
            - And normalize the normal
          - For finite cylinder:
            - Create a boudary, where 0 < pz < height, ignore all points p that pz does not belong in the boundary.
            - Find out if the ray intersects the plane (front of the camera): t = ((p - o).n) / (d.n)
              Note: ray intersects the plane front of the camera when t > 0
            - If the ray intersects the plane, find out if the intersected point belongs inside the top/bottom circle plane.
              - Find the intersect point: p = o + t*d
              - If (px^2 + py^2 < r^2), then the intersect point is on the top/bottom circle plane.
        */
        
        // Equation coefficient components
        float a = (r.direction.x*r.direction.x) + (r.direction.y*r.direction.y);
        float b = 2 * (r.origin.x*r.direction.x + r.origin.y*r.direction.y);
        float c = (r.origin.x*r.origin.x + r.origin.y*r.origin.y) - (this.radius*this.radius);
        
        // Check how many points on the ray intersets the sphere by calculating the discriminant
        float discriminant = b*b - 4*a*c;
        int roots = 0;
        if (discriminant > 0.0)
          roots = 2;
        else if (discriminant == 0.0)
          roots = 1;
        
        // Find the ray intersecting point(s) on the side of the cylinder
        int entryPoint = 0;
        for (int i = 0; i < roots; i++) {
          RayHit hit = new RayHit();
          if (i == 0) 
            hit.t = (-1*b + sqrt(discriminant)) / (2*a);
          else 
            hit.t = (-1*b - sqrt(discriminant)) / (2*a);
          
          if (hit.t > 0.0) {
            PVector p = PVector.add(r.origin, PVector.mult(r.direction, hit.t));
            
            // In the case of a cylinder with finite height
            if (this.height > 0.0) {
              if (p.z < 0.0 || p.z > this.height)
                continue;
            }
            
            // Find the entry point
            if (result.size() > 0.0 && hit.t < result.get(entryPoint).t) 
              entryPoint = i;
            
            hit.location = p;
            hit.normal = new PVector(p.x, p.y, 0).normalize();
            hit.material = this.material;
            hit.entry = false;
            result.add(hit);
          }
        }
        
        
        //Find the ray intersecting point(s) on the top/bottom planes of the cylinder 
        if (this.height > 0.0 && roots == 2) { // Since the roots represent number of intersection of the infinite cylinder, 
          // TODO:
          ArrayList<PVector> centers = new ArrayList<PVector>();
          centers.add(new PVector(0, 0, this.height)); // Top circle plane center
          centers.add(new PVector(0, 0, 0)); // Bottom circle plane center
          
          for (int i = 0; i < 2; i++) {
            PVector normal = PVector.sub(centers.get(i), (i == 0)? centers.get(i+1) : centers.get(i-1)).normalize();
            float t = PVector.dot(PVector.sub(centers.get(i), r.origin), normal) / PVector.dot(r.direction, normal);
            PVector p = PVector.add(r.origin, PVector.mult(r.direction, t));
            
            if (t > 0.0 && (p.x*p.x + p.y*p.y) <= (this.radius*this.radius)) {
              // Find the entry point
              if (result.size() > 0.0 && t < result.get(entryPoint).t) 
                entryPoint = i+(result.size() - 1);
              
              RayHit hit = new RayHit();
              hit.t = t;
              hit.location = p;
              hit.normal = normal;
              hit.material = this.material;
              hit.entry = false;
              result.add(hit);
            }
          }
        }
        
        // Set the entry point where the ray first hit the cylinder
        if (result.size() > 0)
          result.get(entryPoint).entry = true;
        
        return result;
    }
}

class Cone implements SceneObject
{
    Material material;
    float scale;
    
    Cone(Material mat, float scale)
    {
        this.material = mat;
        this.scale = scale;
        
        // remove this line when you implement cones
       throw new NotImplementedException("Cones not implemented yet");
    }
    
    ArrayList<RayHit> intersect(Ray r)
    {
        ArrayList<RayHit> result = new ArrayList<RayHit>();
        return result;
    }
   
}

class Paraboloid implements SceneObject
{
    Material material;
    float scale;
    
    Paraboloid(Material mat, float scale)
    {
        this.material = mat;
        this.scale = scale;
        
        // remove this line when you implement paraboloids
       throw new NotImplementedException("Paraboloid not implemented yet");
    }
    
    ArrayList<RayHit> intersect(Ray r)
    {
        ArrayList<RayHit> result = new ArrayList<RayHit>();
        return result;
    }
   
}

class HyperboloidOneSheet implements SceneObject
{
    Material material;
    float scale;
    
    HyperboloidOneSheet(Material mat, float scale)
    {
        this.material = mat;
        this.scale = scale;
        
        // remove this line when you implement one-sheet hyperboloids
        throw new NotImplementedException("Hyperboloids of one sheet not implemented yet");
    }
  
    ArrayList<RayHit> intersect(Ray r)
    {
        ArrayList<RayHit> result = new ArrayList<RayHit>();
        return result;
    }
}

class HyperboloidTwoSheet implements SceneObject
{
    Material material;
    float scale;
    
    HyperboloidTwoSheet(Material mat, float scale)
    {
        this.material = mat;
        this.scale = scale;
        
        // remove this line when you implement two-sheet hyperboloids
        throw new NotImplementedException("Hyperboloids of two sheets not implemented yet");
    }
    
    ArrayList<RayHit> intersect(Ray r)
    {
        ArrayList<RayHit> result = new ArrayList<RayHit>();
        return result;
    }
}
