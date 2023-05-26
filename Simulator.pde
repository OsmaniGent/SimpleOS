class Simulator {

  //Graphics related
  static final color lightgreen = #28F741;
  static final color green = #28AD1F;
  static final color darkgreen = #075D32;

  static final color pink = #FFC4F5;
  static final color red = #F22735;
  static final color maroon =#A00606;

  static final color aqua = #62C1FA;
  static final color blue = #4C55EA;
  static final color darkblue = #0A05A7;

  static final color yellow = #FAF026;
  static final color orange = #FC8F00;

  static final color white = #FFFFFF;
  static final color black = #000000;

  static final color lightgray =#CCCCCC;
  static final color gray = #777777;
  static final color darkgray = #333333;

  PFont courierBold;
  PFont courier;

  color CPUoutColor;
  color CPUinColor;
  color busColor;
  color fetchExecute;

  float requestsX, requestsY, requestsW;
  float ramX, ramY, ramW;
  float cpuX, cpuY, cpuW;
  float processTableX, processTableY, processTableW;
  float readyQueueX, readyQueueY, readyQueueW;
  float clockX, clockY, clockW;

  String explanation;

  //Statistics related
  ArrayList<ProcessStats> processStatistics;
  int idleTime;
  int contextSwitchTime;
  int utilisationTime;
  int timesBlocked;
  int requestFails;
  PrintWriter output;

  //Simulation related
  int speed;
  boolean fetch;
  boolean isRunning;
  ArrayList<Request> userRequests;
  static final int SLEEPTIME = 10;

  SOS myOS;
  Hardware myPC;

  Simulator() {
    configureUI();
    isRunning = false;
    fetch = true;
    speed = 20;
    userRequests = new ArrayList<Request> ();
    processStatistics = new ArrayList<ProcessStats>();
    frameRate(30);
    setupRequests();
    requestFails = 0;
    output = createWriter("Simulation.log");
    addToLog("=============== New Simulation ===============");
    addToLog("==============================================\n");
  }

  public void initialise(SOS os, int partitions) {
    addToLog("========== Initialising Simulation ============");
    if (partitions>0) {
      addToLog(" - "+partitions+" fixed partitions selected");
    } else {
      addToLog(" - Variable partitions selected");
    }
    myOS = os;
    myPC = myOS.myPC;
    myPC.bootSystem();
    myOS.startOS(partitions);
    idleTime = 0;
    contextSwitchTime = 0;
    utilisationTime = 0;
    timesBlocked = 0;
    fetchExecute = red;
    addToLog("=========== Simulation Intialised =============");
  }

  private void setupRequests() {
    //FEEL FREE TO EXPERIMENT WITH THIS LIST
    userRequests.add(new Request(3, "program3.exe"));
    userRequests.add(new Request(5, "program2.exe"));
    userRequests.add(new Request(32, "program3.exe"));
    userRequests.add(new Request(40, "program2.exe"));
    userRequests.add(new Request(50, "program1.exe"));
    userRequests.add(new Request(60, "program2.exe"));
    userRequests.add(new Request(70, "program1.exe"));
    userRequests.add(new Request(80, "program2.exe"));
    userRequests.add(new Request(80, "program2.exe"));
    userRequests.add(new Request(80, "program2.exe"));
    userRequests.add(new Request(90, "program2.exe"));
    userRequests.add(new Request(100, "program2.exe"));
    userRequests.add(new Request(61, "program3.exe"));
    userRequests.add(new Request(55, "program3.exe"));
    userRequests.add(new Request(59, "program1.exe"));
    userRequests.add(new Request(60, "program2.exe"));
    userRequests.add(new Request(42, "program3.exe"));
    userRequests.add(new Request(100, "program2.exe"));
    userRequests.add(new Request(61, "program3.exe"));
    userRequests.add(new Request(55, "program3.exe"));
    userRequests.add(new Request(200, "program2.exe"));
    userRequests.add(new Request(150, "program3.exe"));
    userRequests.add(new Request(300, "program2.exe"));
    userRequests.add(new Request(600, "program1.exe"));
    userRequests.add(new Request(620, "program1.exe"));
    userRequests.add(new Request(700, "program2.exe"));
    userRequests.add(new Request(650, "program1.exe"));
    userRequests.add(new Request(800, "program3.exe"));
    userRequests.add(new Request(850, "program2.exe"));
    userRequests.add(new Request(870, "program1.exe"));
    userRequests.add(new Request(900, "program3.exe"));
    userRequests.add(new Request(919, "program2.exe"));
    userRequests.add(new Request(940, "program1.exe"));
    userRequests.add(new Request(1000, "program1.exe"));
    userRequests.add(new Request(1050, "program2.exe"));
    userRequests.add(new Request(1110, "program1.exe"));
    userRequests.add(new Request(1111, "program3.exe"));
    userRequests.add(new Request(1144, "program2.exe"));
    userRequests.add(new Request(1188, "program1.exe"));
    userRequests.add(new Request(1200, "program3.exe"));
    userRequests.add(new Request(1250, "program2.exe"));
  }

  private void configureUI() {
    float firstcolX = 10;
    float firstrowY = 50;
    float secondrowY = 350;
    float dist = 10;
    requestsX = firstcolX;
    requestsY = firstrowY;
    requestsW = 230;
    ramX = firstcolX + requestsW + dist;
    ramY = firstrowY;
    ramW = 1100;
    processTableX = ramX;
    processTableY = secondrowY;
    processTableW = 500;
    cpuX = processTableX + processTableW + dist;
    cpuY = secondrowY;
    cpuW = 100;
    clockX = cpuX+cpuW/2;
    clockY = cpuY+cpuW*3;
    clockW = 100;
    readyQueueX = cpuX + cpuW +dist;
    readyQueueY = secondrowY;
    readyQueueW = 500;

    courierBold = createFont("courbd.ttf", 18);
    courier = createFont("cour.ttf", 18);
  }

  public void loadProgram(String request) {
    addToLog(" - Simulator: A new request to run program "+request+" was registered");
    if (myOS.interruptsEnabled) {
      addToLog(" - Simulator: Interrupts are enabled. Request will be served");
      myOS.runProgram(request);
    } else {
      addToLog(" - Simulator: Interrupts are disabled. Request denied. Will be added to the request queue");
      userRequests.add(new Request(myPC.clock, request));
    }
  }

  public void step() {
    //On the right frame update the simulation
    if (frameCount % speed ==0 && isRunning) {
      oneStep();
    }
    //animate elements that update at every frame
    if (sim.isRunning) {
      drawAnimations();
    }
  }

  public void drawAnimations() {
    drawClock();
  }

  public void oneStep() {
    explanation = "";
    myPC.clock++;
    addToLog("\n========== TIME "+int2String(myPC.clock)+" ===========");
    //fetch cycle
    if (fetch) {
      checkForUnblocking();
      if (!userRequests.isEmpty() && myPC.clock >= userRequests.get(0).time && myOS.interruptsEnabled) {
        loadProgram(userRequests.get(0).filename);
        userRequests.remove(0);
      }
      if(myOS.interruptsEnabled && myOS.roundRobin){
        myOS.processScheduler.call();
      }
      myPC.fetch();
      addToLog(" - Fetched instruction "+myPC.counter+" ("+myPC.IR+") from address "+myPC.MAR+" ("+myPC.baseAddress+"+"+myPC.counter+") of "+myOS.active.filename);
      drawUI();
      //execute cycle
    } else {
      char instruction = myPC.execute();
      addToLog(" - Executed instruction "+myPC.counter+" ("+myPC.IR+") of "+myOS.active.filename);
      if (myOS.active instanceof KernelProcess) {
        if (myOS.active == myOS.idle) {
          idleTime += 2;
        } else {
          contextSwitchTime += 2;
        }
      } else {
        utilisationTime += 2;
      }
      if (instruction == '*' && myOS.active.pid>=myOS.kernelProcesses && myOS.active.startTime ==-1) {
        myOS.active.startTime = myPC.clock;
      }
      if(myPC.counter - myOS.initialCounter >= 2 && !(myOS.active instanceof KernelProcess) && myOS.roundRobin){
        myOS.enableInterrupts();

      }
      if (instruction == '$') {
        if (!(myOS.active instanceof KernelProcess)) {
          processStatistics.add(new ProcessStats(myOS.active));
        }
        myOS.finishProcess();
      } else if (instruction == '@') {
        myOS.blockProcess();
      }
      drawUI();
    }
    //switch fetch
    fetch = !fetch;
  }

  private void drawUI() {
    background(aqua);
    if (fetch) {
      fetchExecute = lightgreen;
      CPUoutColor = white;
      CPUinColor = fetchExecute;
      busColor = lightgreen;
    } else {
      fetchExecute = blue;
      CPUoutColor = white;
      CPUinColor = fetchExecute;
      busColor = black;
    }
    //drawUserInput(10, 40, 18);
    drawRequests(18);
    drawRAM(ramX, ramY, ramW);
    drawProcessTable(18);
    drawCPU();
    drawClock();
    drawQueue(18);
    drawSystemState(width/2, height-300);
  }

  private void checkForUnblocking() {
    if (myOS.interruptsEnabled) {
      for (PCB pcb : myOS.processTable) {
        if (pcb.state == BLOCKED && pcb.blockTime+SLEEPTIME <= myPC.clock) {
          myOS.newProcess = pcb;
          myOS.processAdmiter.call();
          break;
        }
      }
    }
  }

  private int findPI(int address) {
    for (Partition p : myOS.partitionTable) {
      if (address>=p.baseAddress && address<p.baseAddress+p.size) {
        return myOS.partitionTable.indexOf(p);
      }
    }
    return -1;
  }

  private void drawRAM(float x, float y, float w) {
    pushMatrix();
    translate(x, y);
    float sqSize = w / myPC.RAMSizeInBank;
    for (int i=0; i<myPC.RAMBanks; i++) {
      drawRAMBank(i, sqSize, false);
    }
    for (int i=myPC.RAMBanks; i<4; i++) {
      drawRAMBank(i, sqSize, true);
    }
    popMatrix();
  }

  private void drawRAMBank(int bank, float sqSize, boolean empty) {
    int squares = myPC.RAMSizeInBank;
    stroke(0);
    pushMatrix();
    translate(0, 2*bank*sqSize);
    textAlign(CENTER, CENTER);
    if (!empty) {
      for (int i=0; i<squares; i++) {
        int partitionIndex = findPI(bank*myPC.RAMSizeInBank+i);
        if (partitionIndex%2==1) {
          fill(white);
        } else {
          fill(black);
        }
        noStroke();
        rect(i*sqSize, -0.15*sqSize, sqSize, sqSize*1.3);
        if (myPC.MAR == i+bank*myPC.RAMSizeInBank) {
          fill(fetchExecute);
        } else if (myPC.RAM[bank][i]== ' ') fill(white);
        else if (bank == 0 && i<myOS.partitionTable.get(0).size) fill(lightgray);
        else fill(pink);
        stroke(black);
        square(i*sqSize, 0, sqSize);
        fill(0);
        text(myPC.RAM[bank][i], i*sqSize+sqSize/2, sqSize/2);
      }
    } else {
      for (int i=0; i<squares; i++) {
        fill(lightgray);
        stroke(black);
        square(i*sqSize, 0, sqSize);
      }
    }
    popMatrix();
  }

  private void drawProcessTable(int ts) {
    pushMatrix();
    translate(processTableX, processTableY);

    noStroke();
    rectMode(CORNER);
    textSize(ts);
    textFont(courierBold);

    fill(darkgreen);
    rect(0, 0, processTableW, ts*1.2);
    textAlign(CENTER, CENTER);
    fill(white);
    text("PROCESS TABLE", processTableW/2, ts/2-2);

    fill(green);
    rect(0, ts*1.2, processTableW, ts*1.2);
    textAlign(LEFT, CENTER);
    fill(white);
    text(" PID : Counter : State   : Name", 0, ts*1.2+ts/2-2);

    textFont(courier);
    int count =0;
    for (PCB p : myOS.processTable) {
      if (count<7) fill(lightgray);
      else fill(white);
      rect(0, (count+2)*ts*1.2, processTableW, ts*1.2+2);
      if (p.state==NEW) fill(orange);
      else if (p.state==READY) fill(darkgreen);
      else if (p.state==BLOCKED) fill(red);
      else if (p.state==RUNNING) fill(blue);
      else fill(maroon);
      text(p.toString(), 0, (count+2)*ts*1.2+ts/2-2);
      count++;
    }
    popMatrix();
  }

  private void drawCPU() {
    pushMatrix();
    translate(cpuX, cpuY);
    rectMode(CORNER);
    textFont(courierBold);
    stroke(0);
    strokeWeight(5);
    //outer rect of top CPU
    fill(CPUoutColor);
    rect(0, 0, cpuW, cpuW);
    strokeWeight(1);
    fill(CPUinColor);
    //inner rect of top CPU
    rect(cpuW*0.16, cpuW*0.16, cpuW*0.68, cpuW*0.68, 7);
    fill(black);
    pushStyle();
    textSize(50);
    textAlign(CENTER, CENTER);
    text(myPC.IR, cpuW*0.5, cpuW*0.5);
    popStyle();
    triangle(cpuW*0.05, cpuW*0.85, cpuW*0.05, cpuW*0.95, cpuW*0.15, cpuW*0.95);
    pushStyle();
    textAlign(CENTER, CENTER);
    textSize(10);
    strokeWeight(5);
    //interrupts
    if (myOS.interruptsEnabled) {
      fill(green);
      rect(0, cpuW, cpuW, cpuW*0.40);
      fill(black);
      text("Int/pts Enabled", cpuW*0.5, cpuW*1.2);
    } else {
      fill(red);
      rect(0, cpuW, cpuW, cpuW*0.40);
      fill(black);
      text("Int/pts Disabled", cpuW*0.5, cpuW*1.2);
    }
    //counter register
    fill(white);
    rect(0, 1.40*cpuW, cpuW, cpuW*0.20);
    fill(black);
    text("Counter: "+myPC.counter, cpuW*0.5, cpuW*1.5);
    //MAR
    fill(white);
    rect(0, 1.60*cpuW, cpuW, cpuW*0.20);
    fill(black);
    text("MAR: "+myPC.MAR, cpuW*0.5, cpuW*1.7);
    popStyle();
    popMatrix();
  }

  private void drawQueue(int ts) {
    pushMatrix();
    translate(readyQueueX, readyQueueY);

    noStroke();
    rectMode(CORNER);
    textSize(ts);
    textFont(courierBold);

    fill(darkgreen);
    rect(0, 0, readyQueueW, ts*1.2);
    textAlign(CENTER, CENTER);
    fill(white);
    text("READY QUEUE", readyQueueW/2, ts/2-2);

    fill(green);
    rect(0, ts*1.2, readyQueueW, ts*1.2);
    textAlign(LEFT, CENTER);
    fill(white);
    text(" PID : Counter : State   : Name", 0, ts*1.2+ts/2-2);

    int count =0;
    textFont(courier);
    for (PCB p : myOS.readyQueue) {
      fill(white);
      rect(0, (count+2)*ts*1.2, readyQueueW, ts*1.2+2);
      fill(black);
      text(p.toString(), 0, (count+2)*ts*1.2+ts/2-2);
      count++;
    }
    popMatrix();
  }

  private void drawRequests(int ts) {
    pushMatrix();
    translate(requestsX, requestsY);

    noStroke();
    rectMode(CORNER);
    textSize(ts);
    textFont(courierBold);

    fill(darkgreen);
    rect(0, 0, requestsW, ts*1.2);
    textAlign(CENTER, CENTER);
    fill(white);
    text("USER REQUESTS", requestsW/2, ts/2-2);


    fill(green);
    rect(0, ts*1.2, requestsW, ts*1.2);
    textAlign(LEFT, CENTER);
    fill(white);
    text(" time : Name", 0, ts*1.2+ts/2-2);

    textFont(courier);
    int count =0;
    for (int i=0; i<userRequests.size(); i++) {
      if (userRequests.get(i).time <= myPC.clock) {
        if (i == 0) {
          fill(red);
        } else {
          fill(pink);
        }
      } else {
        fill(white);
      }
      rect(0, (count+2)*ts*1.2, requestsW, ts*1.2+2);
      fill(black);
      text(userRequests.get(i).toString(), 0, (count+2)*ts*1.2+ts/2-2);
      count++;
    }
    popMatrix();
  }

  private void drawClock() {
    fill(fetchExecute);
    float inc = (frameCount % speed)*TWO_PI/speed;
    noStroke();
    arc(clockX, clockY, clockW, clockW, -HALF_PI, -HALF_PI+inc, PIE);
    pushStyle();
    textFont(courierBold);
    textSize(clockW*0.4);
    fill(black);
    textAlign(CENTER, CENTER);
    text(myPC.clock, clockX, clockY);
    popStyle();
  }

  public void addToLog(String message) {
    println(message);
    output.println(message);
    explanation += message+"\n";
  }

  public String int2String(int num) {
    String result="";
    if (num<10) {
      result += "     "+num+"    :";
    } else if (num<100) {
      result += "    "+num+"    :";
    } else if (num<1000) {
      result += "   "+num+"    :";
    } else {
      result += "  "+num+"    :";
    }
    return result;
  }

  public void endSimulation() {
    float avLT = 0;
    float avRT = 0;
    float avTT = 0;
    addToLog("======================================");
    addToLog(" - Simulation ended on Time "+myPC.clock);
    addToLog("Statistics:");
    if (processStatistics.isEmpty()) {
      addToLog(" - No statistics");
    } else {
      addToLog(":   PID   : LoadTime : startTim : respTime : TurnTime :     Name");
      for (ProcessStats ps : processStatistics) {
        addToLog(ps.toString());
        avLT += ps.loadTime;
        avRT += ps.responceTime;
        avTT += ps.turnarroundTime;
      }
      avRT /= processStatistics.size();
      avTT /= processStatistics.size();
      avLT /= processStatistics.size();
      addToLog(" - Total requests served     = "+ processStatistics.size());
      addToLog(" - Total requests failed     = "+ requestFails);
      addToLog(" - Average Load Time         = "+ avLT);
      addToLog(" - Average Responce Time     = "+ avRT);
      addToLog(" - Average Turnarround Time  = "+ avTT);
      addToLog(" - Total simulation time     = "+int2String(myPC.clock));
      addToLog(" - Total idle time           = "+int2String(idleTime));
      addToLog(" - Total context switch time = "+int2String(contextSwitchTime));
      addToLog(" - Total utility time        = "+int2String(utilisationTime));
      addToLog(" - Simulation time = idle + CWT + UT +(1?) ["+myPC.clock+" = "+(idleTime+contextSwitchTime+utilisationTime)+" +(1?)]");
    }
    output.flush(); // Writes the remaining data to the file
    output.close(); // Finishes the file
  }

  void drawSystemState(int x, int y) {
    textFont(courierBold);
    fill(black);
    textAlign(CENTER, TOP);
    text(explanation, x, y);
  }
  
  void drawInitialScreen(){
    background(aqua);
    textFont(courierBold);
    fill(black);
    textAlign(CENTER, TOP);
    textSize(30);
    text("[P]ause / un[P]ause the simulation", width/2, 50);
    text("[S]tep the simulation 1 step", width/2, 100);
    text("[Q]uit the simulation, and save results to log", width/2, 150);
  }

}
