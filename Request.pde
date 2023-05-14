public class Request {
  int time;
  String filename;

  Request(int t, String fileName) {
    time = t;
    filename = fileName;
  }

  String toString() {
    String s=" "+time;
    if (time<10) s +="    : ";
    else if (time<100) s +="   : ";
    else if (time<1000) s +="  : ";
    else s +=" : ";
    s += filename;
    return s;
  }
}
