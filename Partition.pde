public class Partition {
  //base address
  int baseAddress;
  //size
  int size;
  //is it free?
  boolean isFree;

  Partition(int s, int ba) {
    baseAddress = ba;
    size = s;
    isFree = true;
  }
}
