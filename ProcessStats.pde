class ProcessStats {
  int pid;//int PID; //Who am I?
  int baseAddress; //Where am I?
  int loadTime; //When was I created?
  int startTime; 
  String name; //What is the program?
  int responceTime; //how much time did it pass to run the first instruction?
  int turnarroundTime; //how much time did it pass to run the last instruction?

  ProcessStats(PCB process) {
    pid = process.pid;
    baseAddress = process.baseAddress;
    loadTime = process.loadTime;
    startTime = process.startTime;
    responceTime = startTime - loadTime;
    turnarroundTime = myPC.clock - loadTime;
    name = process.filename;
  }
   
  String toString(){
    String result=":";
    result += sim.int2String(pid);
    result += sim.int2String(loadTime);
    result += sim.int2String(startTime); 
    result += sim.int2String(responceTime);
    result += sim.int2String(turnarroundTime); 
    result += " "+name;
    return result;
  }
}
