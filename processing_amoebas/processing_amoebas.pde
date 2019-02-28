import java.util.HashSet;

class Particle extends LParticle {
  int colorId;
  
  public Particle(PVector pos, int colorId) {
    super(pos);
    this.colorId = colorId;
  }
}

final int PARTICLE_COUNT = 1200;
final float INTERACTION_RADIUS = 50;
final float STIFFNESS = 1000;
final float STIFFNESS_NEAR = 5000;
final float REST_DENSITY = 10;
final float VISCOSITY = 0.01;

final Particle particles[] = new Particle[PARTICLE_COUNT];

LiquidSystem<Particle> liquidSystem;

void setup() {
  fullScreen(P2D);
  
  for (int i=0; i < PARTICLE_COUNT; i++) {
    particles[i] = new Particle(new PVector(random(width), random(height)), i);
  }
  
  liquidSystem = new LiquidSystem(particles, width, height,
                                  INTERACTION_RADIUS,
                                  STIFFNESS, STIFFNESS_NEAR,
                                  REST_DENSITY, VISCOSITY); 

  noStroke();
}

void draw() {
  final float dt = 1 / frameRate;
  
  liquidSystem.update(dt);
  
  // Group logic
  for (int i=0; i < particles.length; i++) {
    final Particle p = particles[i];
    
    // random mutation
    if (random(1000) >= 999) {
      p.colorId ++;
    }
  }
  
  // Handle boundaries
  for (int i=0; i < particles.length; i++) {
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

void drawParticles() {
  background(color(0, 0, 0));
  
  for (int i=0; i < particles.length; i++) {   
    final Particle p = particles[i];
    
    final PVector determinant = new PVector(0, 0);
    final ArrayList<Particle> neighbors = liquidSystem.query(p.pos.x, p.pos.y, INTERACTION_RADIUS);
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
  final ArrayList<Particle> query = liquidSystem.query(mouseX, mouseY, INTERACTION_RADIUS);
  final PVector force = new PVector(mouseX - pmouseX, mouseY -pmouseY); 
  for (int k = 0; k < query.size(); k++) {
      final Particle p = query.get(k);     
      p.vel.add(force);
  }
}
