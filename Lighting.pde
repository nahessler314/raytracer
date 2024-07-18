class Light
{
   PVector position;
   color diffuse;
   color specular;
   Light(PVector position, color col)
   {
     this.position = position;
     this.diffuse = col;
     this.specular = col;
   }
   
   Light(PVector position, color diffuse, color specular)
   {
     this.position = position;
     this.diffuse = diffuse;
     this.specular = specular;
   }
   
   color shine(color col)
   {
       return scaleColor(col, this.diffuse);
   }
   
   color spec(color col)
   {
       return scaleColor(col, this.specular);
   }
}

class LightingModel
{
    ArrayList<Light> lights;
    LightingModel(ArrayList<Light> lights)
    {
      this.lights = lights;
    }
    color getColor(RayHit hit, Scene sc, PVector viewer)
    {
      color hitcolor = hit.material.getColor(hit.u, hit.v);
      color surfacecol = lights.get(0).shine(hitcolor);
      PVector tolight = PVector.sub(lights.get(0).position, hit.location).normalize();
      float intensity = PVector.dot(tolight, hit.normal);
      return lerpColor(color(0), surfacecol, intensity);
    }
  
}

class PhongLightingModel extends LightingModel
{
    color ambient;
    boolean withshadow;
    PhongLightingModel(ArrayList<Light> lights, boolean withshadow, color ambient)
    {
      super(lights);
      this.withshadow = withshadow;
      this.ambient = ambient;
    }
    color getColor(RayHit hit, Scene sc, PVector viewer)
    {
      color hitcolor = hit.material.getColor(hit.u, hit.v);
      
      // Calculate component ambient
      color i_a = amb(hitcolor);
      color comp_ambient = multColor(i_a, hit.material.properties.ka);
      
      // Calculate components diffuse and specular
      color comp_diffuse = color(0);
      color comp_specular = color(0);
      for (Light li : lights) {
        boolean isShadow = false; // Determine if the impacted point is blocked or shadowed from the light.
        
        // Check if the shadow is turned on from the input file
        if (this.withshadow)
          isShadow = shadowCheck(hit, li.position, sc);
        
        if (!isShadow) {
          PVector L = PVector.sub(li.position, hit.location).normalize(); // Vector direction from impacted point to the light.
          
          // Summation of the component diffuse
          color i_d = li.shine(hitcolor);
          float sub_comp_1 = PVector.dot(L, hit.normal); // Sub-component 1 = (L . N)
          color current_diffuse = multColor(i_d, hit.material.properties.kd * sub_comp_1);
          comp_diffuse = addColors(comp_diffuse, current_diffuse);
          
          // Summation of the component specular
          color i_s = li.spec(hitcolor);
          PVector R = PVector.sub(PVector.mult(PVector.mult(hit.normal, 2), sub_comp_1), L).normalize();
          PVector V = PVector.sub(viewer, hit.location).normalize();
          float sub_comp_2 = pow(PVector.dot(R, V), hit.material.properties.alpha); // Sub-component 2 = (R . V)^alpha
          color current_specular = multColor(i_s, hit.material.properties.ks * sub_comp_2);
          comp_specular = addColors(comp_specular, current_specular);
        }
      }
      
      return addColors(comp_ambient, addColors(comp_diffuse, comp_specular));
    }
    
    // Scaling the surface color by this.ambient color
    color amb(color col)
    {
      return scaleColor(col, this.ambient);
    }
    
    // Check if impacted point is blocked from the light source from other objects.
    boolean shadowCheck(RayHit impactedPoint, PVector lightPosition, Scene sc)
    {
      /*
       - Since the impacted point location will always be on the surface, by using the impacted point location
       as the origin of the shadow ray, the ray will always hit the surface of the current object.
       - In able to handle this issue, we raise the impacted point location by EPS value, 0.01.
           - To raise the point, we use the ray equation, p = o + t*d
               - p = new origin (srOrigin)
               - o = impacted point location (impactedPoint.location)
               - t = scaler to raise the point (EPS)
               - d = direction to raise the point (impactedPoint.normal)
      */
      PVector pointToLightVector = PVector.sub(lightPosition, impactedPoint.location); // Vector from impacted point to the light.
      float maxt = pointToLightVector.mag(); // Distance from the light source to impacted point
      PVector L = pointToLightVector.normalize(); // Unit vector from impacted point to the light.
      PVector srOrigin = PVector.add(impactedPoint.location, PVector.mult(L, EPS)); // Shadow Ray Origin, which is the adjusted impacted point location
      Ray sr = new Ray(srOrigin, L); // Shadow Ray from the raised impacted point location to direction of the light
      ArrayList<RayHit> hits = sc.root.intersect(sr); // Stores blocking hits of objects that block the light from the impacted point
      
      if (hits.size() > 0 && hits.get(0).t < maxt)
        return true;
      
      return false;
    }
}
