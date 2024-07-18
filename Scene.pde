class RayHit
{
     String label;
     float t;
     PVector location;
     PVector normal;
     boolean entry;
     Material material;
     float u, v;
     
     void displayData() {
       println();
       println("t: ", this.t);
       println("location: ", this.location);
       println("normal: ", this.normal);
       println("entry: ", this.entry);
     }
}

interface SceneObject
{
   ArrayList<RayHit> intersect(Ray r);
   
   // Check if the ray origin is inside the object.
   default boolean isInsideObject(ArrayList<RayHit> hits, Ray r)
   {
       return hits.size() > 0 && !(hits.get(0).entry);
   }
}

class Scene
{
   LightingModel lighting;
   SceneObject root;
   int reflections;
   color background;
   PVector camera;
   PVector view;
   float fov;
}
