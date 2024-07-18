import java.util.Comparator;

class HitCompare implements Comparator<RayHit>
{
  int compare(RayHit a, RayHit b)
  {
     if (a.t < b.t) return -1;
     if (a.t > b.t) return 1;
     if (a.entry) return -1;
     if (b.entry) return 1;
     return 0;
  }
}

class Union implements SceneObject
{
  SceneObject[] children;
  Union(SceneObject[] children)
  {
    this.children = children;
  }

  ArrayList<RayHit> intersect(Ray r)
  {
     ArrayList<RayHit> result = new ArrayList<RayHit>();
     ArrayList<RayHit> hits = new ArrayList<RayHit>();
     int depth = 0; // Count the number of objects the ray is currently entered/exited
     for (SceneObject sc : children)
     {
       ArrayList<RayHit> sc_hits = sc.intersect(r);
       depth += (sc.isInsideObject(sc_hits, r))? 1 : 0;
       hits.addAll(sc_hits);
     }
     hits.sort(new HitCompare());
     
     // Determine an "enter" and "exit" point for the union
     for (RayHit hit : hits) {
       if (hit.entry) { // An "enter" intersect point
         if (depth == 0)
           result.add(hit);
         depth++;
       }
       else { // An "exit" intersect point
         if (depth == 1)
           result.add(hit);
         depth--;
       }
     }
     return result;
  }
}

class Intersection implements SceneObject
{
  SceneObject[] elements;
  
  Intersection(SceneObject[] elements)
  {
    this.elements = elements;
  }
  
  ArrayList<RayHit> intersect(Ray r)
  {
     int depth = 0;
     ArrayList<RayHit> hits = new ArrayList<RayHit>();
     ArrayList<RayHit> result = new ArrayList<RayHit>();
     
     for (SceneObject sc : elements) {
       ArrayList<RayHit> sc_hits = sc.intersect(r);
       depth += (sc.isInsideObject(sc_hits, r))? 1 : 0;
       hits.addAll(sc_hits);
     }
     hits.sort(new HitCompare());
     
     // Determine an intersect point of the intersection between the objects 
     for (RayHit hit : hits) {
       if (hit.entry) { // An "enter" intersect point   
         if (depth == elements.length-1) {
           result.add(hit);
         }
         depth++;
       }
       else { // An "exit" intersect point
         if (depth == elements.length)
           result.add(hit);
         depth--;
       }
     }   
     return result;
  }
}

class Difference implements SceneObject
{
  SceneObject a;
  SceneObject b;
  Difference(SceneObject a, SceneObject b)
  {
    this.a = a;
    this.b = b;
  }
  
  ArrayList<RayHit> intersect(Ray r)
  {
    ArrayList<RayHit> hits = new ArrayList<RayHit>();
    ArrayList<RayHit> result = new ArrayList<RayHit>();
    ArrayList<RayHit> a_hits = a.intersect(r);
    ArrayList<RayHit> b_hits = b.intersect(r);
    boolean inside_a = isInsideObject(a_hits, r);
    boolean inside_b = isInsideObject(b_hits, r);
    
    for (RayHit hit : a_hits) {
      hit.label = "a";
      hits.add(hit);
    }
    for (RayHit hit : b_hits) {
      hit.label = "b";
      hits.add(hit);
    }
    hits.sort(new HitCompare());
    
    for (RayHit hit : hits) {
      boolean original_hit_entry = hit.entry; // Store the original hit.entry before possible flip, particularly for hit.label b
      
      // Determine the entry point
      if (!inside_a & !inside_b) { // Inside neither a nor b
        if (hit.label == "a")
          result.add(hit);
      }
      else if (inside_a & inside_b) { // Inside both a and b
        if (hit.label == "b") {
          hit.entry = true;
          hit.normal = PVector.mult(hit.normal, -1);
          result.add(hit);
        }
      }
      
      // Determine the exit point
      if (inside_a & !inside_b) { // Inside a only
        if (hit.label == "a")
          result.add(hit);
        else {
          hit.entry = false;
          hit.normal = PVector.mult(hit.normal, -1);
          result.add(hit);
        }
      }
      
      // Set the next section of the ray after interecting a point on an object,
      // whehter that section will be inside of only a, only b, both, or neither.
      if (hit.label == "a")
        inside_a = original_hit_entry;
      else if (hit.label == "b")
        inside_b = original_hit_entry;
    }   
    return result;
  }
}
