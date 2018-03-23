package jp.ac.toyota_ct.analysis_sys;

import jp.ac.toyota_ct.analysis_sys.*;
import java.io.File;
import java.io.RandomAccessFile;
import java.util.Arrays;
import java.math.BigDecimal;


public class preservationDatabase {
    long diskSize = 0;
    int blockSize = 0;
    BigDecimal nextOffset = BigDecimal.ZERO;
    int blockNum = 0;
    int dataStartOffset = 0;
    int index_table_num = 0;
    long index_table [];
    static int databaseHeaderLength = 24;
    static int indexOffset = 512;
    static int byteNum = 8;
    File inputFile;
    RandomAccessFile raf;
    byte[] buf = new byte[4096];

    preservationDatabase(){

    }
    /**
     * reads LogDrive database's information such as
     * diskSize,blockSize,nextOffset,index_table_num,index_table[]
     * @param filename LogDrive file path
     */
    public preservationDatabase(String filename){
	inputFile = new File(filename);
	try {
	    byte index_table_binary [];
	    byte[] database_header = new byte[databaseHeaderLength];
	    raf = new RandomAccessFile(inputFile, "r");

	    // reads data_header between 0 and 24 byte
	    int len = raf.read(database_header,0,databaseHeaderLength);

	    diskSize = setDiskSize(database_header);
	    blockSize = setBlockSize(database_header);
	    nextOffset = setNextOffset(database_header);

	    // calculates offset that begins records
	    dataStartOffset = (int)(diskSize / blockSize * byteNum + indexOffset);

	    // calculates the number of blocks
	    index_table_num = (int)(diskSize / blockSize);

	    // alloc index_table
	    index_table = new long [index_table_num];
	    index_table_binary = new byte [index_table_num * 8];

	    // reads index_table after 512 byte in LogDrive database
	    raf.seek(indexOffset);
	    raf.read(index_table_binary, 0 , index_table_num * 8);

	    byte[] buf = new byte[8];
	    for(int i = 0 ; i < index_table_num ; i++){
		buf = Arrays.copyOfRange(index_table_binary, i*8, i*8+8);
		index_table[i] = convertBinaryToInt(buf);
	    }
	} catch (Exception e) {
	    e.printStackTrace();
	    return;
	}
    }

    private long convertBinaryToInt(byte[] in){
	long bnum = 0;
	for(int i =7; i >= 0; i--) {
	    bnum = (bnum << 8) + (in[i] & 0xff);
	}
	return bnum;
    }

    public int getdataStartOffset(){
	return dataStartOffset;
    }

    public long getDiskSize(){
	return diskSize;
    }

    public int getBlockSize(){
	return blockSize;
    }

    public BigDecimal getNextOffset(){
	return nextOffset;
    }


    private long setDiskSize(byte[] in){
	long bnum = 0;
	for(int i =7; i >= 0; i--) {
	    //System.out.format("in[%d] = %02x %15d\n", i, in[i], in[i]);
	    //System.out.format("in[%d] & 0xff = %02x %15d\n", i, in[i] & 0xff, in[i] & 0xff);
	    //System.out.format("bnum = %15d\n", bnum);
	    //System.out.format("bnum << 8 = %15d\n", bnum<<8);
	    bnum = (bnum << 8) + (in[i] & 0xff);
	}
	return bnum;
    }

    private int setBlockSize(byte[] in){
	int bnum = 0;
	for(int i =15; i >= 8; i--) {
	    bnum = (bnum << 8) + (in[i] & 0xff);
	}
	return bnum;
    }

    private BigDecimal setNextOffset(byte[] in){
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

    /**
     * returns the number of logged records that are stored in specified LBA.
     * @param blockNum or LBA
     * @return the number of logged records on the LBA
     */
    public int getNumOfRecord(int blockNum){
	//BigDecimal next = BigDecimal.ZERO;
	int count = 0;
	byte e_header [] = new byte[preservationRecord.entryHeaderLength];
	long next2;

	if(index_table[blockNum] == 0){
	    return 0;
	}
	//next.valueOf(index_table[blockNum]);
	//next2 = index_table[blockNum];
	BigDecimal next = new BigDecimal(index_table[blockNum]);
	//System.out.println("LongValue = " + index_table[blockNum]);
	//System.out.println("BigDecimal = " + next.longValue());
	try {
	    while(next.longValue() != 0){
		//while(next2 != 0){
		//System.out.println("seek next.longValue()");
		raf.seek(next.longValue());
		//System.out.println("seeked next.longValue()");
		//raf.seek(next2);
		//System.out.println("read next.longValue()");
		raf.read(e_header, 0, preservationRecord.entryHeaderLength);
		//System.out.println("finsh read next.longValue()");
		preservationRecord pr = new preservationRecord(e_header);
		//System.out.println("set Next Big Decimal");
		next = pr.getNextOffset();
		//System.out.println("setted Next Big Decimal");
		//System.out.println("LongValue = " + index_table[blockNum]);
		//System.out.println("BigDecimal = " + next.longValue());
		//next2 = pr.getNextOffset().longValue();
		count++;
	    }
	} catch (Exception e) {
	    e.printStackTrace();
	    return 0;
	}
	//System.out.println("finish getNumOfRecord");
	return count;
    }

    /**
     * returns records of the i_th records on the LBA指定したブロック番号の最新のものからpos番目のレコードを返す
     * @param blockNum or LBA
     * @param pos (if pos=3, returns the 3rd records of the LBA)
     * @return preservationRecord instance
     */
    public preservationRecord getRecord(int blockNum, int pos){
	//BigDecimal next = BigDecimal.ZERO;
	byte e_header [] = new byte[preservationRecord.entryHeaderLength];
	byte e_data [] = new byte[this.blockSize];
	preservationRecord pr = null;
	//System.out.println("Start getRecord");

	if(index_table[blockNum] == 0){
	    System.out.println("index_table[blockNum]=0");
	    return null;
	}
	//next.valueOf(index_table[blockNum]);
	BigDecimal next = new BigDecimal(index_table[blockNum]);
	try {
	    while(next.longValue() != 0 & pos >= 0){
		raf.seek(next.longValue());
		raf.read(e_header, 0, preservationRecord.entryHeaderLength);
		pr = new preservationRecord(e_header);
		raf.seek(next.longValue() + preservationRecord.entryHeaderLengthActualSize);
		raf.read(e_data, 0, pr.getSize());
		pr.setData(e_data);
		next = pr.getNextOffset();
		pos--;
	    }
	} catch (Exception e) {
	    return null;
	}
	//System.out.println("Finish getRecord");
	return pr;
    }

    /**
     * This method is used in convertSequenceFileFromLdLocal.
     *
     *  if you need to read all records at an LBA, you need to add
     *  preservationHeader.entryHederLengthActualSize and pr.getSize() 
     *  repeatedly until the last record.  
     *
     * @param seqOffset; beginning of the record
     * @return preservationRecord
     */
    public preservationRecord getRecordSequence(BigDecimal seqOffset){
	BigDecimal next;
	byte e_header [] = new byte[preservationRecord.entryHeaderLength];
	byte e_data [] = new byte[this.blockSize];

	preservationRecord pr = null;
	try {
	    raf.seek(seqOffset.longValue());
	    raf.read(e_header, 0, preservationRecord.entryHeaderLength);
	    pr = new preservationRecord(e_header);
	    raf.seek(seqOffset.longValue() + preservationRecord.entryHeaderLengthActualSize);
	    raf.read(e_data, 0, pr.getSize());
	    pr.setData(e_data);
	} catch (Exception e) {
	    System.out.println(preservationRecord.entryHeaderLengthActualSize);
	    return null;
	}
	return pr;
    }
}
