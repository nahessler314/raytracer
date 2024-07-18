class MoveRotation implements SceneObject
{
  SceneObject child;
  PVector movement;
  PVector rotation;
  
  MoveRotation(SceneObject child, PVector movement, PVector rotation)
  {
    this.child = child;
    this.movement = movement;
    this.rotation = rotation;
    
    // remove this line when you implement Movement+Rotation
    //throw new NotImplementedException("Movement+Rotation not implemented yet");
  }
  
  ArrayList<RayHit> intersect(Ray r)
  {
    // TODO: Implement move and rotation of objects
    
    PVector origin = PVector.sub(r.origin, this.movement);
    //println(origin, ", ", r.direction);
    Ray transformedRay = new Ray(origin, r.direction);
    
    //ArrayList<RayHit> result = new ArrayList<RayHit>();
    ArrayList<RayHit> transformedHits = child.intersect(transformedRay);
    for (RayHit hit : transformedHits) {
      hit.location = PVector.mult(hit.location, -1.0);
      //hit.normal = PVector.mult(hit.normal, -1.0);
      hit.displayData();
    }
    if (transformedHits.size() > 0)
      println();
    
    return transformedHits;
  }
}

class Scaling implements SceneObject
{
  SceneObject child;
  PVector scaling;
  
  Scaling(SceneObject child, PVector scaling)
  {
    this.child = child;
    this.scaling = scaling;
    
    // remove this line when you implement Scaling
    throw new NotImplementedException("Scaling not implemented yet");
  }
  
  
  ArrayList<RayHit> intersect(Ray r)
  {
     return child.intersect(r);
  }
}
