public class FirstComeFirstServed extends KernelProcess {
  FirstComeFirstServed(SOS sos, String n, String c) {
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
      int index = 0;
      int old = os.readyQueue.get(0).loadTime;
       for (int i = 1; i < os.readyQueue.size(); i++) {
       if (os.readyQueue.get(i).loadTime < old ) {
            old = os.readyQueue.get(i).loadTime;
            index = i;
        }
    }
      PCB found = os.readyQueue.get(index);
      os.readyQueue.remove(found);
      sim.addToLog(" - "+filename+": Selected process with PID "+found.pid);
      os.runProcess(found);
    } else {
      sim.addToLog(" - "+filename+": Did not find a user process. Running idle");
      os.idle.call();
    }
  }
}

////////////////////////////////////////////////////////////////////////////
public class PriorityQueue extends KernelProcess {
  PriorityQueue(SOS sos, String n, String c) {
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
    int max = Integer.MIN_VALUE;
      int index = -1;
      
    if (!os.readyQueue.isEmpty()) {
      
   for (int i = 0; i < os.readyQueue.size(); i++) {
       int num = os.readyQueue.get(i).priority;
       if (num > max) {
            max = num;
            index = i;
        }
    }
       

      PCB found = os.readyQueue.get(index);
      os.readyQueue.remove(found);
      sim.addToLog(" - "+filename+": Selected process with PID "+found.pid+ "with priority"+ found.priority);
      os.runProcess(found);
    } else {
      sim.addToLog(" - "+filename+": Did not find a user process. Running idle");
      os.idle.call();
    }
  }
}


/////////////////////////////////////////////////////////////////////////////


public class ShortestJobFirst extends KernelProcess {
  ShortestJobFirst(SOS sos, String n, String c) {
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
      int s = -1;
      for( int i =0; i < os.readyQueue.size(); i++){
        String file = os.readyQueue.get(i).filename;
      int processSize = myPC.HDD.get(file).length()+os.processTail.length()-os.readyQueue.get(i).programCounter;
      
      if(processSize < temp){
        temp = processSize;
        s = i;
      }
      }
      if(s != -1){
      PCB found = os.readyQueue.get(s);
      os.readyQueue.remove(found);
      sim.addToLog(" - "+filename+": Selected process with PID "+found.pid);
      os.runProcess(found);
      }
    } else {
      sim.addToLog(" - "+filename+": Did not find a user process. Running idle");
      os.idle.call();
    }
  }
}
////////////////////////////////////////////////////////////////////////////////////////
public class FirstFit extends KernelProcess {
  FirstFit(SOS sos, String n, String c) {
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
  int processSize = myPC.HDD.get(os.request).length() + os.processTail.length();
  for (int i = 1; i < os.partitionTable.size(); i++) {
    if (os.partitionTable.get(i).isFree && os.partitionTable.get(i).size >= processSize) {
      os.baseAddressFound = os.partitionTable.get(i).baseAddress;
      
      if (os.partitionTable.get(i).size > processSize) {
        // Existing partition is larger than the process size, create a new partition
        os.partitionTable.get(i).isFree = false;
        
        int size = os.partitionTable.get(i).size;
        os.partitionTable.get(i).size = processSize;
        
        // Calculate the index where the new partition should be inserted
        int insertIndex = i + 1;
        int newPartitionSize = size - processSize;
        int newPartitionBaseAddress = os.baseAddressFound + processSize;
        
        // Insert the new partition at the appropriate index
        os.partitionTable.add(insertIndex, new Partition(newPartitionSize, newPartitionBaseAddress));
      } else {
        // Existing partition is exactly the same size as the process, allocate it
        os.partitionTable.get(i).isFree = false;
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

///////////////////////////////////////////////////////////////////////////////////////////////

public class WorstFit extends KernelProcess {

  public WorstFit(SOS sos, String n, String c) {
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
    int partitionLengthFound = 0;
    int processSize = myPC.HDD.get(os.request).length()+os.processTail.length();
    int partitionIndexFound = -1;
    for (int i=1; i<os.partitionTable.size(); i++) {
      Partition current = os.partitionTable.get(i);
      if (current.isFree && current.size >= processSize && (current.size > partitionLengthFound || partitionLengthFound == 0)) {
        os.baseAddressFound = current.baseAddress;
        partitionLengthFound = current.size;
        partitionIndexFound = i;
      }
    }
    if (os.baseAddressFound==-1) {
      sim.addToLog(" - "+filename+": Did not find a free partition. Request is ignored");
      sim.requestFails++;
      os.processScheduler.call();
    } else {
      Partition partitionFound = os.partitionTable.get(partitionIndexFound);
      partitionFound.isFree = false;
      if (partitionFound.size > processSize) {
        int newPartitionSize = partitionFound.size - processSize;
        int newPartitionBaseAddress = partitionFound.baseAddress + processSize;
        partitionFound.size = processSize;
        os.partitionTable.add(partitionIndexFound+1, new Partition(newPartitionSize, newPartitionBaseAddress));
      }
      sim.addToLog(" - "+filename+": Found a free partition with base address "+os.baseAddressFound);
      os.processCreator.call();
    }
  }
}
//////////////////////////////////////////////////////
public class BestFit extends KernelProcess {

  public BestFit(SOS sos, String n, String c) {
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
    int foundPartitionIndex = -1;
    int foundPartitionLength = 0;
    int processSize = myPC.HDD.get(os.request).length()+os.processTail.length();
    for (int i = 1; i < os.partitionTable.size(); i++) {
      Partition current = os.partitionTable.get(i);
      if (current.isFree && current.size >= processSize && (current.size < foundPartitionLength || foundPartitionLength == 0)) {
        os.baseAddressFound = current.baseAddress;
        foundPartitionLength = current.size;
        foundPartitionIndex = i;
      }
    }
    
    if (os.baseAddressFound == -1) {
      sim.addToLog(" - "+filename+": No free partition found. Request has been ignored");
      sim.requestFails++;
      os.processScheduler.call();
    } else {
      Partition foundPartition = os.partitionTable.get(foundPartitionIndex);
      foundPartition.isFree = false;
    
      if (foundPartition.size > processSize) {
        int newPartitionSize = foundPartition.size - processSize;
        int newPartitionBaseAddress = foundPartition.baseAddress + processSize;
        foundPartition.size = processSize;
        os.partitionTable.add(foundPartitionIndex + 1, new Partition(newPartitionSize, newPartitionBaseAddress));
      }
    
      sim.addToLog(" - "+filename+": A free partition has been found with the base address "+os.baseAddressFound);
      os.processCreator.call();
    }
  }
}
//////////////////////////////////////////////////////
public class NextFit extends KernelProcess {

  int previousBaseAddress;

  public NextFit(SOS sos, String n, String c) {
    super(sos, n, c);
    previousBaseAddress = 0;
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
    int searchIndex;
    for (searchIndex = 1; searchIndex < os.partitionTable.size(); searchIndex++) {
        if (searchIndex == os.partitionTable.size() - 1)
          break;
        else if (os.partitionTable.get(searchIndex).baseAddress <= previousBaseAddress && os.partitionTable.get(searchIndex + 1).baseAddress > previousBaseAddress)
          break;
        }
    for (int i = searchIndex; i < os.partitionTable.size(); i++) {
      Partition current = os.partitionTable.get(i);
      if (current.isFree && current.size >= processSize) {
        os.baseAddressFound = current.baseAddress;
        previousBaseAddress = current.baseAddress;
        current.isFree = false;
        if (current.size > processSize) {
          int newPartitionSize = current.size - processSize;
          int newPartitionBaseAddress = current.baseAddress + processSize;
          current.size = processSize;
          os.partitionTable.add(i + 1, new Partition(newPartitionSize, newPartitionBaseAddress));
        }
        break;
      }
    }
    if (os.baseAddressFound == -1) {
      for (int i = 0; i < searchIndex; i++) {
        Partition current = os.partitionTable.get(i);
        if (current.isFree && current.size >= processSize) {
          os.baseAddressFound = current.baseAddress;
          previousBaseAddress = current.baseAddress;
          current.isFree = false;
          if (current.size > processSize) {
            int newPartitionSize = current.size - processSize;
            int newPartitionBaseAddress = current.baseAddress + processSize;
            current.size = processSize;
            os.partitionTable.add(i + 1, new Partition(newPartitionSize, newPartitionBaseAddress));
          }
        break;
        }
      }
    }
    if (os.baseAddressFound == -1) {
      sim.addToLog(" - "+filename+": No free partition found. Request has been ignored");
      sim.requestFails++;
      os.processScheduler.call();
    } else {
      sim.addToLog(" - "+filename+": A free partition has been found with the base address "+os.baseAddressFound);
      os.processCreator.call();
    }
  }
}

public class CoalesceProcessDeleter extends KernelProcess{
  
  CoalesceProcessDeleter(SOS os, String name, String code){
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
        
        System.out.println("Current partitionTable status:");
        for (Partition partition : os.partitionTable) {
          System.out.println("Base Address: " + partition.baseAddress + ", Size: " + partition.size + ", Is Free: " + partition.isFree);
        }
        
        os.processScheduler.call();
      }
}

 
