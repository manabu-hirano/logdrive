package jp.ac.toyota_ct.analysis_sys;

import java.util.*;
import java.nio.ByteBuffer;
import java.math.BigDecimal;

/**
 * Byte-level manipulation class 
 * @author Takase Hayate
 * @author Yoshida Koki
 */

public class ByteControl{
    private final int indexSize = 32;
    private final int blockSize = 4096;
    private final int sectorSize = 4096;

    /**
     * Obtains dataSize，sec，nsec，blockNum from header
     * minSector is the minimum number of sectors
     */
    private int dataSize = 0, minSector = 0;
    private long sec = 0, nsec = 0;
    BigDecimal blockNum = BigDecimal.ZERO;

    ByteControl(byte[] in){
	dataSize = setSize(in);
	blockNum = setBlockNum(in);
	sec = setSec(in);
	nsec = setNsec(in);
	getMinSectorNum();
    }

    ByteControl(String in){
	StringTokenizer st = new StringTokenizer(in, ",");
        st.nextToken(); st.nextToken(); st.nextToken();
        dataSize = Integer.parseInt(st.nextToken());
        getMinSectorNum();
    }

    public void reset(){
	dataSize = 0;
	minSector = 0;
	sec = 0;
	nsec = 0;
	blockNum = BigDecimal.ZERO;
    }

    public int getSize(){
	return dataSize;
    }

    public BigDecimal getBlockNum(){
	return blockNum;
    }

    public long getSec(){
	return sec;
    }

    public long getNsec(){
	return nsec;
    }

    public int getSecNum(){
	return minSector;
    }

    /**
     * Calculates the minimum number of sector
     */
    private void getMinSectorNum(){
	if(dataSize <= sectorSize){
	    minSector = 1;
	}else if(dataSize <= sectorSize*2){
	    minSector = 2;
	}else if(dataSize <= sectorSize*3){
	    minSector = 3;
	}else if(dataSize <= sectorSize*4){
	    minSector = 4;
	}else if(dataSize <= sectorSize*5){
	    minSector = 5;
	}else if(dataSize <= sectorSize*6){
	    minSector = 6;
	}else if(dataSize <= sectorSize*7){
	    minSector = 7;
	}else{
	    minSector = 8;
	}
    }

    private int setSize(byte[] in){
	int size = 0;
	size = (size << 8) + (in[25] & 0xff);
	size = (size << 8) + (in[24] & 0xff);
	return size;
    }

    /**
     * TimeSpec
     */
    private long setSec(byte[] in){
	long s = 0;
	for(int i = 3; i >= 0; i--)
	    s = (s << 8) + (in[i] & 0xff);
	return s;
    }

    /**
     * TimeSpec in nanosecond
     */
    private long setNsec(byte[] in){
	long ns = 0;
	for(int i = 11; i >= 8; i--)
	    ns = (ns << 8) + (in[i] & 0xff);
	return ns;
    }

    /**
     *  Block number (LBA)
     */
    private BigDecimal setBlockNum(byte[] in){
	// long bnum = 0;
	BigDecimal bnum = BigDecimal.ZERO;
	BigDecimal oneByte = BigDecimal.valueOf(256);
	for(int i =23; i >= 16; i--) {
	    // bnum = (bnum << 8) + (in[i] & 0xff);
	    bnum = bnum.multiply(oneByte);
	    bnum = bnum.add(BigDecimal.valueOf(in[i] & 0xff));
	}
	return bnum;
    }
}
