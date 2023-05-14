final int NEW = 0;
final int READY = 1;
final int RUNNING = 2;
final int BLOCKED = 3;
final int TERMINATED = 4;

int kernelCodeSize = 0;
int kernelBaseAddress = 0;
int pidCounter = 0;

Hardware myPC;
SOS doorsOS;
Simulator sim;

void setup() {
  size(1400, 1024);
  randomSeed(0);
  frameRate(30);
  sim = new Simulator();
  myPC = new Hardware(4, 100);
  doorsOS = new SOS(myPC);
  doorsOS.compileKernel(new MManager(doorsOS, "Kernel-mManager", "$"), //MemManager First
    new Scheduler(doorsOS, "Kernel-pScheduler", "$"),                  //Then Scheduler
    new ProcessDeleter(doorsOS, "Kernel-delete", "$"));                //Finally deleter

  sim.initialise(doorsOS, 10);  // num of fixed Partitions. 0=variable partitions
}

void draw() {
  if (myPC.clock<1 && !sim.isRunning) {
    sim.drawInitialScreen();
  } else {
    sim.step();
  }
}

void keyPressed() {
  if (key == CODED) {
    if (keyCode == LEFT) {
      sim.speed +=5;
    } else if (keyCode == RIGHT) {
      sim.speed -=5;
    }
    sim.speed = constrain(sim.speed, 1, 30);
  } else {
    if (key=='P' || key=='p') {
      sim.isRunning = !sim.isRunning;
    } else if (key=='S' || key=='s') {
      sim.oneStep();
      sim.drawAnimations();
    } else if (key=='Q' || key == 'q') {
      sim.endSimulation();
      exit();
    } else if (key=='1') {
      sim.loadProgram("program1.exe");
    } else if (key=='2') {
      sim.loadProgram("program2.exe");
    } else if (key=='3') {
      sim.loadProgram("program3.exe");
    }
  }
}
