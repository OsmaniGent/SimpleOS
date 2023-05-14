public class MManager extends KernelProcess {
  int sum = 0;
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
      if(i >1 && os.partitionTable.get(i).isFree && os.partitionTable.get(i-1).isFree){
        int newSize = os.partitionTable.get(i-1).size + os.partitionTable.get(i-1).size;
        os.partitionTable.get(i-1).size = newSize;
        os.partitionTable.remove(i);
        i--;
      }
      if (os.partitionTable.get(i).isFree && os.partitionTable.get(i).size >= processSize) {
        os.baseAddressFound = os.partitionTable.get(i).baseAddress;
        os.partitionTable.get(i).isFree = false;
os.partitionTable.get(i).size = processSize;
 sum += os.partitionTable.get(i-1).size;
        
       
      if(myPC.RAMSize - sum - kernelCodeSize > os.partitionTable.get(i).size){
        os.partitionTable.add(new Partition(myPC.RAMSize-os.partitionTable.get(i).size, os.baseAddressFound+processSize));
        }
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
      int temp = 200;
      int s = 0;
      for( int i =0; i < os.readyQueue.size(); i++){
        String file = os.readyQueue.get(i).filename;
      int processSize = myPC.HDD.get(file).length()+os.processTail.length()-os.readyQueue.get(i).programCounter;
      
      if(processSize < temp){
        temp = processSize;
        s = i;
      }
      }
      PCB found = os.readyQueue.get(s);
      os.readyQueue.remove(found);
      sim.addToLog(" - "+filename+": Selected process with PID "+found.pid);
      os.runProcess(found);
    } else {
      sim.addToLog(" - "+filename+": Did not find a user process. Running idle");
      os.idle.call();
    }
  }
}
