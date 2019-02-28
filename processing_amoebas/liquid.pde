
class LParticle {
  PVector pos;
  PVector vel;
  float pressure = 0;
  float pNear = 0;
  double gradient = 0;
  
  public LParticle(PVector pos, PVector vel) {
    this.pos = pos.copy();
    this.vel = vel.copy();
  }
  
  public LParticle(PVector pos) {
    this(pos, new PVector(0, 0));
  }
}

class LiquidSystem<P extends LParticle> {
  
  final private P[] particles;
  final private float interactionRadius;
  final private float stiffness;
  final private float stiffnessNear;
  final private float restDensity;
  final private float viscosity;
  final SpatialHashMap<P> spacialHashMap;
  
  final int gridCellW;
  final int gridCellH;
  
  public LiquidSystem(P[] particles, int containerWidth, int containerHeight,
                      float interactionRadius, float stiffness, float stiffnessNear,
                      float restDensity, float viscosity) {
    this.particles = particles;
    this.interactionRadius = interactionRadius;
    this.stiffness = stiffness;
    this.stiffnessNear = stiffnessNear;
    this.restDensity = restDensity;
    this.viscosity = viscosity;
    
    gridCellW = (int)Math.max(interactionRadius / 10, 3);
    gridCellH = (int)Math.max(interactionRadius / 10, 3);
    
    spacialHashMap = new SpatialHashMap<P>(gridCellW, gridCellH, containerWidth, containerHeight);
  }
  
  public ArrayList<P> query(final float x, final float y, final float radius) {
    return spacialHashMap.query(x, y, radius);
  }
  
  public void update(float dt) {
    spacialHashMap.clear();

    // First pass
    for (int i=0; i < particles.length; i++) {
      final P p = particles[i];
    
      // integrate position
      p.pos.add(PVector.mult(p.vel, dt));
    
      spacialHashMap.add(p.pos.x, p.pos.y, p);
      
      // viscosity
      p.vel.mult(1 - viscosity);
    }
      
    // Second pass
    for (int i=0; i < particles.length; i++) {
      final P p = particles[i];
      final ArrayList<P> neighbours = getNeighboursWithGradients(p);
      updatePressures(p, neighbours);
      doubleDensityRelaxation(p, neighbours, dt);
    }
  }
  
  private ArrayList<P> getNeighboursWithGradients(final P p) {
      final ArrayList<P> results = spacialHashMap.query(p.pos.x, p.pos.y, interactionRadius);
      final ArrayList<P> neighbours = new ArrayList<P>();
  
      for (int k = 0; k < results.size(); k++) {
          final P n = results.get(k);
          if (p == n) continue; // Skip itself
          n.gradient = gradient(p.pos, n.pos);
          neighbours.add(n);
      }
  
      return neighbours;
  }

  private double gradient(final PVector a, final PVector b) {
      final double distance = a.dist(b);
      return Math.max(0, 1 - distance / interactionRadius);
  }
  
  private void updatePressures(final P p, final ArrayList<P> neighbours) {
      float density = 0;
      float nearDensity = 0;
  
      for (int k = 0; k < neighbours.size(); k++) {
          final double g = neighbours.get(k).gradient;
          density += g * g;
          nearDensity += g * g * g;
      }
  
      p.pressure = stiffness * (density - restDensity);
      p.pNear = stiffnessNear * nearDensity;
  }
  
  private void doubleDensityRelaxation(final P p, final ArrayList<P> neighbours, final float dt) {
      for (int k = 0; k < neighbours.size(); k++) {
          final P n = neighbours.get(k);
          final double g = n.gradient;
  
          final double magnitude = p.pressure * g + p.pNear * g * g;
  
          final PVector direction = PVector.sub(n.pos, p.pos).normalize();
          final PVector force = PVector.mult(direction, (float)magnitude);
  
          final PVector d = PVector.mult(force, dt * dt);
  
          p.pos.add(PVector.mult(d, -.5));
          n.pos.add(PVector.mult(d, .5));
      }
  }
}
