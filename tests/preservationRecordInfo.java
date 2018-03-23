package jp.ac.toyota_ct.analysis_sys;

import java.math.BigDecimal;

/**
 * Disk information 
 *  TODO: This class is under development for now
 *
 * @author Seishiro Ikeda
 * @since 2017/07/28
 *
 */
public class preservationRecordInfo {

    /**
     * saves diskSizeByte, diskSizeSector, sectorSize, computerId
     */
    private BigDecimal diskSizeByte = BigDecimal.ZERO;
    private BigDecimal diskSizeSector = BigDecimal.ZERO;
    private BigDecimal sectorSize = BigDecimal.ZERO;
    private BigDecimal computerId = BigDecimal.ZERO;
    public static int infoLength = 32;

    /**
     * sets disk information
     * @param in byte array obtained from the surveillance system
     */
    preservationRecordInfo(byte[] in){
        diskSizeByte = setDiskSizeByte(in);
        diskSizeSector = setDiskSizeSector(in);
        sectorSize = setSectorSize(in);
        computerId = setComputerId(in);
    }

    public void reset(){
        diskSizeByte = BigDecimal.ZERO;
        diskSizeSector = BigDecimal.ZERO;
        sectorSize = BigDecimal.ZERO;
        computerId = BigDecimal.ZERO;
    }

    public BigDecimal getDiskSizeByte(){
        return diskSizeByte;
    }

    public BigDecimal getDiskSizeSector(){
        return diskSizeSector;
    }

    public BigDecimal getSectorSize(){
        return sectorSize;
    }

    public BigDecimal getComputerId(){
        return computerId;
    }

    /**
     * returns the disk size in byte
     * @return disk size in byte
     */
    private BigDecimal setDiskSizeByte(byte[] in){
        BigDecimal diskSizeByte = BigDecimal.ZERO;
        BigDecimal oneByte = BigDecimal.valueOf(256);
        for (int i = 7; i >= 0; i--) {
	    diskSizeByte = diskSizeByte.multiply(oneByte);
	    diskSizeByte = diskSizeByte.add(BigDecimal.valueOf(in[i] & 0xff));
        }
        return diskSizeByte;
    }

    /**
     * returns the disk size in the number of sectors
     * @return the number of sectors
     */
    private BigDecimal setDiskSizeSector(byte[] in){
        BigDecimal diskSizeSector = BigDecimal.ZERO;
        BigDecimal oneByte = BigDecimal.valueOf(256);
        for (int i = 15; i >= 8; i--) {
	    diskSizeSector = diskSizeSector.multiply(oneByte);
	    diskSizeSector = diskSizeSector.add(BigDecimal.valueOf(in[i] & 0xff));
        }
        return diskSizeSector;
    }

    /**
     * returns sector size
     * @return sector size
     */
    private BigDecimal setSectorSize(byte[] in){
        BigDecimal sectorSize = BigDecimal.ZERO;
        BigDecimal oneByte = BigDecimal.valueOf(256);
        for (int i = 23; i >= 16; i--) {
	    sectorSize = sectorSize.multiply(oneByte);
	    sectorSize = sectorSize.add(BigDecimal.valueOf(in[i] & 0xff));
        }
        return sectorSize;
    }

    /**
     * Identification number of a computer (NOT IMPLEMENTED YET)
     * @return computer ID
     */
    private BigDecimal setComputerId(byte[] in){
        BigDecimal computerId = BigDecimal.ZERO;
        BigDecimal oneByte = BigDecimal.valueOf(256);
        for (int i = 31; i >= 24; i--) {
	    computerId = computerId.multiply(oneByte);
	    computerId = computerId.add(BigDecimal.valueOf(in[i] & 0xff));
        }
        return computerId;
    }
}
