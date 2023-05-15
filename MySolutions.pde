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
//    int max = Integer.MIN_VALUE;
//      int index = -1;
      
//    if (!os.readyQueue.isEmpty()) {
      
//   for (int i = 0; i < os.readyQueue.size(); i++) {
//       int num = os.readyQueue.get(i).priority;
//       if (num >= max) {
//            max = num;
//            index = i;
//        }
//    }
       

//      PCB found = os.readyQueue.get(index);
//      os.readyQueue.remove(found);
//      sim.addToLog(" - "+filename+": Selected process with PID "+found.pid+ "with priority"+ found.priority);
//      os.runProcess(found);
//    } else {
//      sim.addToLog(" - "+filename+": Did not find a user process. Running idle");
//      os.idle.call();
//    }
//  }
//}
