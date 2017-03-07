package mutex;
import java.util.*;
import dist.*;
import clocks.*;
public class RAMutex extends dist.Process implements Lock {  
    public int myts;
    public LamportClock c = new LamportClock();
    LinkedList<Integer> pendingQ = new LinkedList<Integer>();
    public int numOkay = 0;
    public RAMutex(Linker initComm) {
        super(initComm);
        myts = Integer.MAX_VALUE;
    }
    public synchronized void requestCS() {
        c.tick();
        myts = c.getValue();
        broadcastMsg("request", myts);
        numOkay = 0;
        while (numOkay < N-1)
            myWait(); 
    }
    public synchronized void releaseCS() {
        myts = Integer.MAX_VALUE;
        while (!pendingQ.isEmpty()) 
            sendMsg(pendingQ.remove(), "okay", c.getValue());
    }
    public Boolean okayCS() {
        if(myts == Integer.MAX_VALUE || numOkay <N-1) return false;
        return true;
    }
    public synchronized void handleMsg(Msg m, int src, String tag) {
        int timeStamp = m.getMessageInt();
        c.receiveAction(src, timeStamp);
        if (tag.equals("request")) {
            if ((timeStamp < myts) || ((timeStamp == myts) && (src < myId)))
                sendMsg(src, "okay", c.getValue());
            else
                pendingQ.add(src);
        } else if (tag.equals("okay")) 
            numOkay++;
    }
}
