public class PCB {
  //who am I?
  int pid;
  //state
  int state;
  //where in RAM am I?
  int baseAddress;
  //how far have I progressed?
  int programCounter;
  //Which program it is for
  String filename;
  //time the process was admitted to the ready queue first time
  int loadTime;
  //last time it was blocked
  int blockTime;
  //time the process run its first instruction
  int startTime;
  //priority
  int priority;

  PCB(int ba, String fn) {
    pid = pidCounter++;
    state = NEW;
    baseAddress = ba;
    programCounter=0;
    filename = fn;
    loadTime = -1;
    blockTime = -1;
    startTime = -1;
    priority = int(random(6));
  }

  String toString() {
    String result="  ";
    if (pid<10) {
      result += pid+"  :    ";
    } else {
      result += pid+" :    ";
    }
    if (programCounter<10) {
      result += programCounter+"    : ";
    } else {
      result += programCounter+"   : ";
    }
    if (state == NEW)      result += "NEW     ";
    else if (state == READY) result += "READY   ";
    else if (state == RUNNING) result += "RUNNING ";
    else if (state == BLOCKED) result += "BLOCKED ";
    else                result += "TERMINAT";
    result += ": "+filename;
    return result;
  }
}
