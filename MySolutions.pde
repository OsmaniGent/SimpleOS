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


//public class Scheduler extends KernelProcess {
//  Scheduler(SOS sos, String n, String c) {
//    super(sos, n, c);
//  }

//  public void call() {
//    sim.addToLog(" - Calling "+filename+" to find for a process to run");
//    os.disableInterrupts();
//    programCounter=0;
//    os.runProcess(this);
//  }

//  public void complete() {
//    os.enableInterrupts();
//    if (!os.readyQueue.isEmpty()) {
//      int temp = 200;
//      int s = 0;
//      for( int i =0; i < os.readyQueue.size(); i++){
//        String file = os.readyQueue.get(i).filename;
//      int processSize = myPC.HDD.get(file).length()+os.processTail.length()-os.readyQueue.get(i).programCounter;
      
//      if(processSize < temp){
//        temp = processSize;
//        s = i;
//      }
//      }
//      PCB found = os.readyQueue.get(s);
//      os.readyQueue.remove(found);
//      sim.addToLog(" - "+filename+": Selected process with PID "+found.pid);
//      os.runProcess(found);
//    } else {
//      sim.addToLog(" - "+filename+": Did not find a user process. Running idle");
//      os.idle.call();
//    }
//  }
//}

///////////////////////////////////////////////////////////////////////////////////////////////

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
  int processSize = myPC.HDD.get(os.request).length() + os.processTail.length();
  int worstfit= -1;
  int index = -1;
  for (int i = 1; i < os.partitionTable.size(); i++) {
    if (os.partitionTable.get(i).isFree && os.partitionTable.get(i).size >= processSize) {
      
      
       if (os.partitionTable.get(i).size > worstfit) {
          worstfit = os.partitionTable.get(i).size;
          index = i;
        }
    }
  }
       if(index != -1){   
               
      if (os.partitionTable.get(index).size > processSize) {
        // Existing partition is larger than the process size, create a new partition
        os.partitionTable.get(index).isFree = false;
        os.baseAddressFound = os.partitionTable.get(index).baseAddress;
        
        int size = os.partitionTable.get(index).size;
        os.partitionTable.get(index).size = processSize;
        
        // Calculate the index where the new partition should be inserted
        int insertIndex = index + 1;
        int newPartitionSize = size - processSize;
        int newPartitionBaseAddress = os.baseAddressFound + processSize;
        
        // Insert the new partition at the appropriate index
        os.partitionTable.add(insertIndex, new Partition(newPartitionSize, newPartitionBaseAddress));
      } else {
        // Existing partition is exactly the same size as the process, allocate it
        os.partitionTable.get(index).isFree = false;
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

//////////////////////////////////////////////////////
 // next fit algorithm
 //int lastAllocatedPartitionIndex = 0;
 // private void nextFit(int processSize) {
 //for (int i = lastAllocatedPartitionIndex + 1; i < os.partitionTable.size(); i++) {
 //     if (os.partitionTable.get(i).isFree && os.partitionTable.get(i).size >= processSize) {
 //       os.baseAddressFound = os.partitionTable.get(i).baseAddress;

 //       if (os.partitionTable.get(i).size > processSize) {
 //         // Existing partition is larger than the process size, create a new partition
 //         os.partitionTable.get(i).isFree = false;

 //         int size = os.partitionTable.get(i).size;
 //         os.partitionTable.get(i).size = processSize;

 //         // Calculate the index where the new partition should be inserted
 //         int insertIndex = i + 1;
 //         int newPartitionSize = size - processSize;
 //         int newPartitionBaseAddress = os.baseAddressFound + processSize;

 //         // Insert the new partition at the appropriate index
 //         os.partitionTable.add(insertIndex, new Partition(newPartitionSize, newPartitionBaseAddress));
 //       } else {
 //         // Existing partition is exactly the same size as the process, allocate it
 //         os.partitionTable.get(i).isFree = false;
 //       }

 //       lastAllocatedPartitionIndex = i;
 //       break;
 //     }

 //     // Wrap around to the beginning of the partition table
 //     if (i == os.partitionTable.size() - 1) {
 //       i = 0;
 //     }
 //   }
 // }
