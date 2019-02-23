import java.util.HashSet;

class Particle {
  PVector pos;
  PVector vel = PVector.random2D();
  float pressure = 0;
  float pNear = 0;
  double gradient = 0;
  int colorId;

  Particle(PVector pos, int colorId) {
    this.pos = pos;
    this.colorId = colorId;
  }
 
}

final int PARTICLE_COUNT = 1200;

final int GRID_CELL_W = 5;
final int GRID_CELL_H = 5;
final float INTERACTION_RADIUS = 50;

final float STIFFNESS = 1000;
final float STIFFNESS_NEAR = 5000;
final float REST_DENSITY = 10;

final float VISCOSITY = 0.01;

final Particle particles[] = new Particle[PARTICLE_COUNT];
SpatialHashMap<Particle> spacialHashMap;

void setup() {
  fullScreen(P2D);
  spacialHashMap = new SpatialHashMap<Particle>(GRID_CELL_W, GRID_CELL_H, width, height);
  
  for (int i=0; i < PARTICLE_COUNT; i++) {
    particles[i] = new Particle(new PVector(random(width), random(height)), i);
  }
  
  noStroke();
}

void draw() {
  final float dt = 1 / frameRate;
  spacialHashMap.clear();
  
  // First pass
  for (int i=0; i < PARTICLE_COUNT; i++) {
    final Particle p = particles[i];

    // integrate position
    p.pos.add(PVector.mult(p.vel, dt));

    spacialHashMap.add(p.pos.x, p.pos.y, p);
    
    // viscosity
    p.vel.mult(1 - VISCOSITY);
    
    // random mutation
    if (random(1000) >= 999) {
      p.colorId ++;
    }
  }
  
  // Second pass
  for (int i=0; i < PARTICLE_COUNT; i++) {
    final Particle p = particles[i];
    final ArrayList<Particle> neighbours = getNeighboursWithGradients(p);
    updatePressures(p, neighbours);

    // perform double density relaxation
    relax(p, neighbours, dt);
  }
  
  // Third pass: boundaries
  for (int i=0; i < PARTICLE_COUNT; i++) {
    final Particle p = particles[i];
    if (p.pos.x < 0) {
      p.pos.x += width;
    }
    if (p.pos.x > width) {
      p.pos.x -= width;
    }
    if (p.pos.y < 0) {
      p.pos.y += height;
    }
    if (p.pos.y > height) {
      p.pos.y -= height;
    }    
  }
  
  // random drag in a group
  if (random(100) >= 50) {
    final Particle p = particles[(int)random(PARTICLE_COUNT)];
    final PVector drag = PVector.mult(PVector.random2D(), random(200));
    int count = 0;
    for (int i=0; i < PARTICLE_COUNT; i++) {
      final Particle p2 = particles[i];
      if (p.colorId == p2.colorId) {
        count ++;
      }
    }
    if (random(count) <= 10) {
      for (int i=0; i < PARTICLE_COUNT; i++) {   
        final Particle p2 = particles[i];
        if (p.colorId == p2.colorId && random(100) >= 80) {
          p2.vel.add(drag);
        }
      }
    }
  }

  drawParticles();
}

ArrayList<Particle> getNeighboursWithGradients(final Particle p) {
    final ArrayList<Particle> results = spacialHashMap.query(p.pos.x, p.pos.y, INTERACTION_RADIUS);
    final ArrayList<Particle> neighbours = new ArrayList<Particle>();

    for (int k = 0; k < results.size(); k++) {
        final Particle n = results.get(k);
        if (p == n) continue; // Skip itself
        n.gradient = gradient(p.pos, n.pos);
        neighbours.add(n);
    }

    return neighbours;
}

double gradient(final PVector a, final PVector b) {
    final double distance = a.dist(b);
    return Math.max(0, 1 - distance / INTERACTION_RADIUS);
}

void updatePressures(final Particle p, final ArrayList<Particle> neighbours) {
    float density = 0;
    float nearDensity = 0;

    for (int k = 0; k < neighbours.size(); k++) {
        final double g = neighbours.get(k).gradient;
        density += g * g;
        nearDensity += g * g * g;
    }

    p.pressure = STIFFNESS * (density - REST_DENSITY);
    p.pNear = STIFFNESS_NEAR * nearDensity;
}

void relax(final Particle p, final ArrayList<Particle> neighbours, final float dt) {
    for (int k = 0; k < neighbours.size(); k++) {
        final Particle n = neighbours.get(k);
        final double g = n.gradient;

        final double magnitude = p.pressure * g + p.pNear * g * g;

        final PVector direction = PVector.sub(n.pos, p.pos).normalize();
        final PVector force = PVector.mult(direction, (float)magnitude);

        final PVector d = PVector.mult(force, dt * dt);

        p.pos.add(PVector.mult(d, -.5));
        n.pos.add(PVector.mult(d, .5));
    }
}

void drawParticles() {
  background(color(0, 0, 0));
  
  for (int i=0; i < PARTICLE_COUNT; i++) {   
    final Particle p = particles[i];
    
    final PVector determinant = new PVector(0, 0);
    final ArrayList<Particle> neighbors = spacialHashMap.query(p.pos.x, p.pos.y, INTERACTION_RADIUS);
    int nClose = 0;
    for (int k = 0; k < neighbors.size(); k++) {
      final Particle n = neighbors.get(k);
      if (n == p) continue;
      final PVector delta = PVector.sub(p.pos, n.pos);
      final float dist = delta.mag();
      if (dist < INTERACTION_RADIUS) {
        determinant.add(delta.normalize());
        nClose ++;
      }
      if (dist < INTERACTION_RADIUS/2 && n.colorId > p.colorId && random(100) >= 90) {
        p.colorId = n.colorId;
      }
    }
    determinant.div(nClose);

    fill(color((p.colorId * 231) % 255, determinant.mag() * 500, determinant.mag() * 100));
    ellipse(p.pos.x, p.pos.y, 1 + determinant.mag() * 10, 1 + determinant.mag() * 10);
  }
}

void mouseDragged() {
  final ArrayList<Particle> query = spacialHashMap.query(mouseX, mouseY, INTERACTION_RADIUS);
  final PVector force = new PVector(mouseX - pmouseX, mouseY -pmouseY); 
  for (int k = 0; k < query.size(); k++) {
      final Particle p = query.get(k);     
      p.vel.add(force);
  }
}
