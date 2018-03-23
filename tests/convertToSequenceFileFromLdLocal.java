package jp.ac.toyota_ct.analysis_sys;

import java.io.File;
import java.io.FileWriter;
import java.io.BufferedWriter;
import java.io.PrintWriter;
import java.io.IOException;
import java.net.URI;
import java.math.BigDecimal;
import jp.ac.toyota_ct.analysis_sys.*;
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.BytesWritable;
import org.apache.hadoop.io.IOUtils;
import org.apache.hadoop.io.SequenceFile;

/**
 * Converts a LogDrive database file into SequenceFile in HDFS cluster.
 *
 * @author Koki Yoshida
 * @since 2016/03/31
 *
 */

public class convertToSequenceFileFromLdLocal {
    /**
     * @param args[0] Input LogDrive file path in local file system "e.g., /benchmark/preservation-vm-1.img"
     * @param args[1] Output SequenceFile path in HDFS "e.g. /preservation-vm-1.seq")
     * @param args[2] Info file path in local file system "e.g., /tmp/preservation-vm-1.info"
     * @return
     */
    public static void main(String[] args) throws IOException {
        //int counttest;
        //long sectest;
        BigDecimal offset = BigDecimal.ZERO;
        int dataSize = 0;
        int i = 0;
        int j = 0;
        int k = 0;
        String inputFileName = args[0];
        String outputFileName = args[1];
        String outputCSV = args[2];
        Configuration conf = new Configuration();
        long sec_min=0;
        long nsec_min=0;
        long sec_max=0;
        long nsec_max=0;
        long sec_current, nsec_current;

        FileSystem fs = FileSystem.get(URI.create(outputFileName), conf);
        Path path = new Path(outputFileName);
        byte[] header  = new byte[preservationRecord.entryHeaderLengthActualSize];
        byte[] data;
        BytesWritable key = new BytesWritable(),
	    value = new BytesWritable();
        SequenceFile.Writer writer = null;

        preservationDatabase pd = new preservationDatabase(inputFileName);
        File file = new File(outputCSV);
        PrintWriter pw = new PrintWriter(new BufferedWriter(new FileWriter(file)));
        pw.println("disksize, blocksize, nextoffset, sec_min, nsec_min, sec_max, nsec_max");

        try{
	    writer = SequenceFile.createWriter(fs,  conf,  path, key.getClass(), value.getClass());
                
	    while(i<pd.getDiskSize()/pd.getBlockSize()) {
		// If the element has record
		if (pd.getNumOfRecord(i) != 0) {
		    dataSize = pd.getRecord(i, j).getSize();
		    header = pd.getRecord(i, j).getHeader(i);

		    // Save the oldest timestamp
		    sec_current = pd.getRecord(i,j).getSec();
		    nsec_current = pd.getRecord(i,j).getNsec();
		    if( sec_min == 0 && sec_max == 0 ) {
			sec_min = sec_max = sec_current;
			nsec_max = nsec_min = nsec_current;
		    } else {
			//System.out.println("Current: " +sec_current + ",Min:"+sec_min+",Max:"+sec_max);
			if( sec_min > sec_current || (sec_min == sec_current && nsec_min > nsec_current)) {
			    sec_min = sec_current;
			    nsec_min = nsec_current;
			    //System.out.println("updated sec_min:" + sec_min);
			}
			if( sec_max < sec_current || (sec_max == sec_current && nsec_max < nsec_current)) {
			    sec_max = sec_current;
			    nsec_max = nsec_current;
			    //System.out.println("updated sec_max:" + sec_min);
			}
		    }

		    key.set(header, 0, preservationRecord.entryHeaderLengthActualSize);
		    data = new byte[dataSize];
		    data = pd.getRecord(i, j).getData();
		    value.set(data, 0, dataSize);
		    writer.append(key, value);
		    offset = pd.getRecord(i, j).getNextOffset();
		    k++;
		}
		while(offset.longValue() != 0) {
		    dataSize = pd.getRecordSequence(offset).getSize();
		    header = pd.getRecordSequence(offset).getHeader(i);
		    key.set(header, 0, preservationRecord.entryHeaderLengthActualSize);
		    data = new byte[dataSize];
		    data = pd.getRecordSequence(offset).getData();
		    value.set(data, 0, dataSize);
		    writer.append(key, value);
		    offset = pd.getRecordSequence(offset).getNextOffset();
		    j++;
		    k++;
		}
		i++;
		j = 0;
	    }

        }finally{
	    IOUtils.closeStream(writer);
	    pw.println(String.valueOf(pd.getDiskSize())+","+String.valueOf(pd.getBlockSize())+","+String.valueOf(pd.getNextOffset())+","+sec_min+","+nsec_min+","+sec_max+","+nsec_max);
	    pw.close();
        }

    }
}
