public class Hardware {
  /*Instruction set
   * = any normal instruction like add, sub, load, etc
   @ = block process for 10 clock tics
   $ = system call for exit
   d = some data like variables , constants etc (static)
   an example of a program: **********$ddddd
   */

  //RAM
  char[][] RAM;
  int RAMBanks;
  int RAMSizeInBank;
  int RAMSize;

  //CPU registers
  int counter;
  int baseAddress;
  char IR; //Instruction register
  int MAR; //Memory Address Register

  //HDD
  HashMap<String, String> HDD;

  //clock
  int clock;

  Hardware(int banks, int banksize) {
    sim.addToLog("=============== Setting PC ===================");
    RAMBanks = constrain(banks, 1, 4);
    RAMSizeInBank = constrain(banksize, 20, 100);
    RAMSize = RAMBanks * RAMSizeInBank;
    RAM = new char[RAMBanks][RAMSizeInBank];
    HDD = new HashMap<String, String>();
    sim.addToLog(" - RAM banks = "+RAMBanks);
    sim.addToLog(" - RAM bank size = "+RAMSizeInBank);
    sim.addToLog(" - Available memory "+RAMSize+" characters");
    sim.addToLog("================= PC ready ====================\n");
  }

  public void bootSystem() {
    RAMinit();
    clock = 0;
    counter = 0;
    baseAddress = 0;
    mountHDD();
    sim.addToLog(" - PC booted");
  }

  public void mountHDD() {
    HDD.put("program1.exe", "***$ddddd");
    HDD.put("program2.exe", "*****@*****$ddd");
    HDD.put("program3.exe", "*****@***@*****$dddddddd");
    HDD.put("program4.exe", "*$");
  }

  public void fetch() {
    MAR = baseAddress + counter;
    IR = readFromRAM(MAR);
  }

  public char execute() {
    switch(IR) {
    case '*':
      counter++;
      break;
    case '@':
      counter++;
      break;
    case '$':
      break;
    default:
    }
    return IR;
  }

  private void RAMinit() {
    for (int i=0; i<RAMBanks; i++) {
      for (int j=0; j<RAMSizeInBank; j++) {
        RAM[i][j] = ' ';
      }
    }
  }

  public void writeToRAM(int address, char x) {
    int bank = address / RAMSizeInBank;
    int position = address % RAMSizeInBank;
    RAM[bank][position] = x;
  }

  public char readFromRAM(int address) {
    int bank = address / RAMSizeInBank;
    int position = address % RAMSizeInBank;
    return RAM[bank][position];
  }
}
