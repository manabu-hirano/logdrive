package jp.ac.toyota_ct.analysis_sys;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.Arrays;
import java.math.BigDecimal;

public class preservationRecord {

    /**
     * dataSize，sec，nsec，blockNum, flags are obtained from header
     */
    private int dataSize = 0;
    private long sec = 0, nsec = 0;
    // private long nextOffset = 0;
    private BigDecimal nextOffset = BigDecimal.ZERO;
    private int flags = 0;
    private byte recordData [];
    private byte recordHeader [];
    public static int entryHeaderLength = 27;   // but stored in 32 byte structure
    public static int entryHeaderLengthActualSize = 32;

    preservationRecord(byte[] in){
        dataSize = setSize(in);
        nextOffset = setNextOffset(in);
        sec = setSec(in);
        nsec = setNsec(in);
        flags = setFlags(in);
        recordHeader = new byte[entryHeaderLengthActualSize];
        recordHeader = Arrays.copyOfRange(in,0,entryHeaderLengthActualSize);
    }

    public void reset(){
        dataSize = 0;
        sec = 0;
        nsec = 0;
        // nextOffset = 0;
        nextOffset = BigDecimal.ZERO;
    }

    public int getSize(){
        return dataSize;
    }

    public BigDecimal getNextOffset(){
        return nextOffset;
    }

    public long getSec(){
        return sec;
    }

    public long getNsec(){
        return nsec;
    }

    public int getFlags(){
        return flags;
    }

    /**
     * Check the flags of header
     * Flag is {read, write, disk information}
     */
    public boolean getReadFlag(){
        if (flags == 2) {
	    return true;
        } else {
	    return false;
        }
    }

    public boolean getWriteFlag(){
        if (flags == 1) {
	    return true;
        } else {
	    return false;
        }
    }

    public boolean getInfoFlag(){
        if (flags == 4) {
	    return true;
        } else {
	    return false;
        }
    }

    /**
     * return its sector data
     * @return byte array
     */
    public byte[] getData(){
        return recordData;
    }

    /**
     * return its header
     * @return byte array
     */
    public byte[] getHeader(int blocknumber){
        byte[] buf = new byte[8];

	// Change endian
        buf = ByteBuffer.allocate(8).order(ByteOrder.LITTLE_ENDIAN).putInt(blocknumber).array();
        byte[] c = new byte[entryHeaderLengthActualSize];
	
        System.arraycopy(recordHeader, 0, c, 0, 16);  // Unix time
        System.arraycopy(buf, 0, c, 16, 8);           // LBA(Offset is overwritten)
        System.arraycopy(recordHeader, 24, c, 24, 8); // Size
        return c;
    }

    /**
     * returns size of its data sector
     * @return size in byte
     */
    private int setSize(byte[] in){
        int size = 0;
        size = (size << 8) + (in[25] & 0xff);
        size = (size << 8) + (in[24] & 0xff);
        return size;
    }

    /**
     * returns next offset of the linked list
     * @return offset in byte
     */
    private BigDecimal setNextOffset(byte[] in){
        // long bnum = 0;
        BigDecimal bnum = BigDecimal.ZERO;
        BigDecimal oneByte = BigDecimal.valueOf(256);
        for(int i =23; i >= 16; i--) {
	    // bnum = (bnum << 8) + (in[i] & 0xff);
	    bnum = bnum.multiply(oneByte);
	    bnum = bnum.add(BigDecimal.valueOf(in[i] & 0xff));
	    // System.out.println("" + (in[i] & 0xff) + " , " + bnum);
        }
        return bnum;
    }

    /**
     * TimeSpec
     */
    private long setSec(byte[] in){
        long s = 0;
        for(int i = 7; i >= 0; i--) {
	    s = (s << 8) + (in[i] & 0xff);
        }
        return s;
    }

    /**
     * TimeSpec in nanosecond
     */
    private long setNsec(byte[] in){
        long ns = 0;
        for(int i = 15; i >= 8; i--) {
	    ns = (ns << 8) + (in[i] & 0xff);
        }
        return ns;
    }

    /**
     * Flags in header {read, write, disk information}
     */
    private int setFlags(byte[] in){
        int flags = 0;
        flags = (flags << 8) + (in[26] & 0xff);
        return flags;
    }

    /**
     * set data sector
     * @param byte array
     */
    public void setData(byte[] data){
        recordData = new byte[dataSize];
        recordData = Arrays.copyOfRange(data,0,dataSize);
    }
}
