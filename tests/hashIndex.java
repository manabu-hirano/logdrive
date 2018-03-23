package jp.ac.toyota_ct.analysis_sys;

import java.io.*;
import java.util.*;
import jp.ac.toyota_ct.analysis_sys.*;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.conf.*;
import org.apache.hadoop.io.*;
import org.apache.hadoop.io.BytesWritable;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.lib.input.SequenceFileInputFormat;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;
import org.apache.hadoop.mapreduce.lib.output.SequenceFileOutputFormat;
import org.apache.hadoop.util.*;
import java.math.BigDecimal;

/**
 * Creates HashDB file on HDFS cluster from SequenceFile.
 * You can confirm the output by the command such as 
 * hadoop fs -text /preservation-vm-1.md5
 * @author Takase Hayate
 * @since 2014/11/6
 *
 * @param args[0] Input SequenceFile in HDFS (e.g., /preservation-vm-1.seq)
 * @param args[1] Output SequenceFile in HDFS (e.g., /preservation-vm-1.md5); If the file exists, you will enconter the error, so you need to delete the file first.
 *
 */

public class hashIndex {


    static private int sectorSize = 512, blockSize = 4096;
    //static private int sectorSize = 4096, blockSize = 4096;

    static class HashMapper extends Mapper<BytesWritable, BytesWritable, Text, Text>{
	private final String HashName = "MD5";

	public void map(BytesWritable key, BytesWritable value, Context context) throws IOException, InterruptedException {
	    Text keyOut = new Text(), valueOut = new Text();
	    byte[] sector = new byte[sectorSize];
	    byte[] block = new byte[blockSize];
	    byte[] v = value.getBytes();
	    HashAlgorithm h = new HashAlgorithm(HashName);
	    ByteControl bc = new ByteControl(key.getBytes());
	    String val = null;

	    block = Arrays.copyOf(v, blockSize);

	    for(int i = 0; i < bc.getSecNum(); i++) {

                Arrays.fill(sector, (byte)0x00); // deltes previous data
                sector = Arrays.copyOfRange(block, sectorSize*i, sectorSize*(i+1));
                if(i == 0)
		    val = h.toHashValue(sector);
                else
		    val = val + "," + h.toHashValue(sector);
	    }

	    // key is a sequence of hash values separated by comma.
	    keyOut.set(val);
	    // value consits of TimeSpec(sec)，TimeSpec(nsec)，BlockNumber，DataSize
	    valueOut.set(String.valueOf(bc.getSec()) + "," + String.valueOf(bc.getNsec()) +
			 ","+ bc.getBlockNum().toString() + "," + String.valueOf(bc.getSize()));
	    // If sector is filled with all same byte character (0x00, etc.), 
	    // skip transmit this (key, value) pair
	    int j = 0;
	    byte tmp = sector[0];
	    for (j = 1; j < sectorSize; j++) {
                if( tmp != sector[j] ) break;
	    }

	    if(j == sectorSize) {
                // the sector is filled with all same byte
                //System.out.println("Skip searching the sector filled with " + String.format("%02X", tmp));
	    } else {
		context.write(keyOut, valueOut);
	    }
	    bc.reset();
	}
    }

    public static class HashReducer extends Reducer<Text, Text, Text, Text> {
	public void reduce(Text key, Text values, Context context) throws IOException, InterruptedException {
	    context.write(key, values);
	}
    }

    public static void main(String [] args) throws Exception {
        long start = System.currentTimeMillis();
        Job job = new Job();
        job.setJarByClass(hashIndex.class);
        job.setJobName("Create HashIndex");
        job.setInputFormatClass(SequenceFileInputFormat.class);
        job.setOutputFormatClass(SequenceFileOutputFormat.class);
        job.setMapperClass(HashMapper.class);
        job.setReducerClass(HashReducer.class);
        job.setOutputKeyClass(Text.class);
        job.setOutputValueClass(Text.class);
        FileInputFormat.addInputPath(job, new Path(args[0]));
        FileOutputFormat.setOutputPath(job, new Path(args[1]));
        job.waitForCompletion(true);
        long stop = System.currentTimeMillis();
        System.out.println((stop - start)+":ms");
    }
}
