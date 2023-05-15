public abstract class KernelProcess extends PCB {
  String code;
  SOS os;

  KernelProcess(SOS os, String n, String c) {
    super(-1, n);
    code = c;
    this.os = os;
    kernelCodeSize += code.length();
  }

  public void loadToRAM() {
    baseAddress = kernelBaseAddress;
    for (int i=0; i<code.length(); i++) {
      os.writeToRAM(i+baseAddress, code.charAt(i));
    }
    state = READY;
    os.processTable.add(this);
    kernelBaseAddress += code.length();
    sim.addToLog(" - "+filename+" loaded at address "+baseAddress);
  }

  public abstract void call();

  public abstract void complete();
}

////////////////////////////////////////////

public class MManager extends KernelProcess {
  MManager(SOS sos, String n, String c) {
    super(sos, n, c);
  }

  public void call() {
    sim.addToLog(" - Calling "+filename+" to find a free partition for the program  "+os.request);
    os.disableInterrupts();
    programCounter=0;
    os.runProcess(this);
  }

  public void complete() {
    os.baseAddressFound = -1;
    int processSize = myPC.HDD.get(os.request).length()+os.processTail.length();
    for (int i=1; i<os.partitionTable.size(); i++) {
      if (os.partitionTable.get(i).isFree && os.partitionTable.get(i).size >= processSize) {
        os.baseAddressFound = os.partitionTable.get(i).baseAddress;
        os.partitionTable.get(i).isFree = false;
        
        int size = os.partitionTable.get(i).size;
        os.partitionTable.get(i).size = processSize;
        
        //if(myPC.RAMSize - (os.baseAddressFound + processSize) >0){
    os.partitionTable.add(new Partition(size-processSize , os.baseAddressFound + processSize));
   //}
        break;
      }
    }
    if (os.baseAddressFound==-1) {
      sim.addToLog(" - "+filename+": Did not find a free partition. Request is ignored");
      sim.requestFails++;
      os.processScheduler.call();
    } else {
      sim.addToLog(" - "+filename+": Found a free partition with base address "+os.baseAddressFound);
      os.processCreator.call();
    }
  }
}

///////////////////////////////////////////

public class Scheduler extends KernelProcess {
  Scheduler(SOS sos, String n, String c) {
    super(sos, n, c);
  }

  public void call() {
    sim.addToLog(" - Calling "+filename+" to find for a process to run");
    os.disableInterrupts();
    programCounter=0;
    os.runProcess(this);
  }

  public void complete() {
    os.enableInterrupts();
    if (!os.readyQueue.isEmpty()) {
      PCB found = os.readyQueue.get(0);
      os.readyQueue.remove(found);
      sim.addToLog(" - "+filename+": Selected process with PID "+found.pid);
      os.runProcess(found);
    } else {
      sim.addToLog(" - "+filename+": Did not find a user process. Running idle");
      os.idle.call();
    }
  }
}

//////////////////////////////////////////////
public class ProcessDeleter extends KernelProcess{
  
  ProcessDeleter(SOS os, String name, String code){
    super(os, name, code);  
  }
  
  public void call() {
        sim.addToLog(" - Calling "+filename+" to delete process "+os.markedForDeletion.pid+" ("+os.markedForDeletion.filename+")");
        os.disableInterrupts();
        programCounter=0;
        os.active = this;
        os.active.state = RUNNING;
        myPC.counter =programCounter;
        myPC.baseAddress = baseAddress;
      }

      public void complete() {
        int ba = os.markedForDeletion.baseAddress;
        for (int i=1; i<os.partitionTable.size(); i++) {
          if (ba == os.partitionTable.get(i).baseAddress) {
            os.erasePartition(os.partitionTable.get(i));
            os.partitionTable.get(i).isFree = true;
            
            if( i != os.partitionTable.size()){
              if(os.partitionTable.get(i+1).isFree){
                os.partitionTable.get(i).size +=os.partitionTable.get(i+1).size;
                os.partitionTable.remove(os.partitionTable.get(i+1));
              }
            }
            if(i != 1){
              if(os.partitionTable.get(i-1).isFree){
                os.partitionTable.get(i-1).size +=os.partitionTable.get(i).size;
                os.partitionTable.remove(os.partitionTable.get(i));
              }
            }
            
            
            os.processTable.remove(os.markedForDeletion);
            break;
          }
        }
        sim.addToLog(" - "+filename+": Process with pid "+os.markedForDeletion.pid+" ("+os.markedForDeletion.filename+") was deleted");
        os.processScheduler.call();
      }
}
