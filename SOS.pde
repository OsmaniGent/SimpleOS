public class SOS {
  ArrayList<Partition> partitionTable; //All the partitions of RAM
  ArrayList<PCB> processTable; //All the processes I have
  ArrayList<PCB> readyQueue; //All processes that are ready to run
  Hardware myPC;
  String processTail = "hhhhssss";
  boolean interruptsEnabled = true;
  boolean fixedPartitions = true;

  ///////// KERNEL /////////////////////

  //The kernel code
  KernelProcess idle;
  KernelProcess memoryManager;
  KernelProcess processCreator;
  KernelProcess processAdmiter;
  KernelProcess processScheduler;
  KernelProcess processDeleter;
  KernelProcess processBlocker;
  int kernelProcesses;

  //internal memory of the kernel
  PCB active;
  String request;
  int baseAddressFound;
  PCB newProcess;
  PCB markedForDeletion;
  PCB markedForBlocking;

  /////////////////////////////////////


  SOS(Hardware pc) {
    partitionTable = new ArrayList<Partition>();
    processTable = new ArrayList<PCB>();
    readyQueue = new ArrayList<PCB>();
    myPC = pc;
  }

  public void compileKernel(KernelProcess mManager, KernelProcess pScheduler, KernelProcess pDeleter) {
    sim.addToLog("========== Compiling kernel for OS ============");
    memoryManager = mManager;
    processScheduler = pScheduler;
    processDeleter = pDeleter;

    idle = new KernelProcess(this, "Kernel-idle", "$") {
      public void call() {
        sim.addToLog(" - "+filename+": Waiting for user input");
        os.enableInterrupts();
        os.runProcess(this);
      }

      public void complete() {
        call();
      }
    };

    processCreator = new KernelProcess(this, "Kernel-create", "*$") {
      public void call() {
        sim.addToLog(" - Calling "+filename+" to create a process for "+request);
        disableInterrupts();
        programCounter=0;
        runProcess(this);
      }

      public void complete() {
        os.newProcess = new PCB(os.baseAddressFound, os.request);
        os.processTable.add(os.newProcess);
        String process = myPC.HDD.get(os.request)+os.processTail;
        for (int i=0; i<process.length(); i++) {
          myPC.writeToRAM(os.baseAddressFound+i, process.charAt(i));
        }
        sim.addToLog(" - "+filename+": Created process with pid "+os.newProcess.pid+" for "+os.request);
        os.processAdmiter.call();
      }
    };

    processAdmiter = new KernelProcess(this, "Kernel-admiter", "*$") {
      public void call() {
        sim.addToLog(" - Calling "+filename+" to admit the process "+os.newProcess.pid+" ("+os.newProcess.filename+") to the ready queue");
        programCounter=0;
        os.disableInterrupts();
        os.runProcess(this);
      }

      public void complete() {
        os.readyQueue.add(os.newProcess);
        os.newProcess.state = READY;
        if (os.newProcess.loadTime==-1) os.newProcess.loadTime = myPC.clock;
        sim.addToLog(" - "+filename+": Process with pid "+os.newProcess.pid+" ("+os.newProcess.filename+") was admitted to the READY queue");
        os.processScheduler.call();
      }
    };

    processBlocker = new KernelProcess(this, "Kernel-block", "*$") {
      public void call() {
        os.markedForBlocking = os.active;
        sim.addToLog(" - Calling "+filename+" to block process "+os.markedForBlocking.pid+" ("+os.markedForBlocking.filename+")");
        os.disableInterrupts();
        programCounter=0;
        os.markedForBlocking.blockTime = myPC.clock;
        os.markedForBlocking.programCounter = myPC.counter;
        os.runProcess(this);
      }

      public void complete() {
        os.markedForBlocking.state = BLOCKED;
        os.readyQueue.remove(markedForBlocking);
        sim.addToLog(" - "+filename+": Process with pid "+os.markedForBlocking.pid+" ("+os.markedForBlocking.filename+") was blocked");
        os.processScheduler.call();
      }
    };
    sim.addToLog(" - Memory Manager selected"+memoryManager.filename);
    sim.addToLog(" - Process scheduler selected"+processScheduler.filename);
    sim.addToLog("============ OS kernel compiled ===============\n");
  }

  public void startOS(int p) {
    sim.addToLog("\n  ------------- Booting the OS --------------  ");

    String kernelTail = "ddddhhss";
    //Make the kernel partition
    int kernelPartitionSize = kernelCodeSize + kernelTail.length();
    Partition KernelPartition = new Partition(kernelPartitionSize, 0);
    partitionTable.add(KernelPartition);
    KernelPartition.isFree = false;

    if (p>0) {
      fixedPartitions = true;
      //Make the user partitions (fixed size)
      int partitionSize = (myPC.RAMSize-kernelPartitionSize)/p;
      for (int i=0; i<p; i++) {
        partitionTable.add(new Partition(partitionSize, kernelPartitionSize+i*partitionSize));
      }
    } else {
      
      //Make one user BIG user partition (variable partitions)
      partitionTable.add(new Partition(myPC.RAMSize - kernelPartitionSize, kernelPartitionSize));
    }

    //boot the kernel
    memoryManager.loadToRAM();
    processScheduler.loadToRAM();
    processDeleter.loadToRAM();
    idle.loadToRAM();
    processCreator.loadToRAM();
    processAdmiter.loadToRAM();
    processBlocker.loadToRAM();
    kernelProcesses = processTable.size();
    for (int i=0; i<kernelTail.length(); i++) {
      myPC.writeToRAM(i+kernelCodeSize, kernelTail.charAt(i));
    }
    sim.addToLog("  -------------- OS booted ------------------\n");
    //Start with the idle process
    idle.call();
  }

  public void enableInterrupts() {
    interruptsEnabled = true;
    sim.addToLog(" - Interrupts set to ENABLED");
  }

  public void disableInterrupts() {
    interruptsEnabled = false;
    sim.addToLog(" - Interrupts set to DISABLED");
  }

  public void writeToRAM(int address, char c) {
    myPC.writeToRAM(address, c);
  }

  public char readFromRAM(int address) {
    return myPC.readFromRAM(address);
  }

  public void writeToRegisters(int c, int ba) {
    myPC.counter = c;
    myPC.baseAddress = ba;
  }

  //Prepares to run a program, after pre-empting the current running process
  public void runProgram(String program) {
    request = program;
    memoryManager.call();
  }

  //Sets a process to run, after pre-empting the current running process
  public void runProcess(PCB process) {
    //Preempt the current process
    if (active !=null) {
      active.state = READY;
      active.programCounter = myPC.counter;
      //if a user process add it to the ready Queue
      if (active.pid >= kernelProcesses) {
        readyQueue.add(active);
      }
    }
    //Set the given process as the next to run
    active = process;
    myPC.counter = active.programCounter;
    myPC.baseAddress = active.baseAddress;
    active.state = RUNNING;
    sim.addToLog(" - Set active process "+active.pid+" , counter ="+myPC.counter+", ba = "+myPC.baseAddress);
  }

  public void finishProcess() {
    //Kernel processes
    if (active instanceof KernelProcess) {
      ((KernelProcess)active).complete();
    } else { //User processes
      active.state = TERMINATED;
      markedForDeletion = active;
      processDeleter.call();
    }
  }

  public void blockProcess() {
    processBlocker.call();
  }

  public void erasePartition(Partition p) {
    for (int i=0; i<p.size; i++) {
      writeToRAM(p.baseAddress+i, ' ');
    }
  }
}
