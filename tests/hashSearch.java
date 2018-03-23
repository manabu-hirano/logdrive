package jp.ac.toyota_ct.analysis_sys;

import java.io.*;
import java.util.*;
import java.net.URI;
import jp.ac.toyota_ct.analysis_sys.*;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.conf.*;
import org.apache.hadoop.io.*;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.lib.input.SequenceFileInputFormat;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;
import org.apache.hadoop.mapreduce.lib.output.TextOutputFormat;
import org.apache.hadoop.fs.FSDataInputStream;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.util.*;

/**
 * Sequential search in HashDB file (i.e., the output of hashIndex.class)
 *
 * @author Takase Hayate
 * @since 2014/12/4
 *
 * @param args[0] target file path in local file system (e.g., /tmp/test.txt)
 * @param args[1] HashDB file in HDFS (e.g., /preservation-vm-1.md5)
 * @param args[2] Output directory in HDFS (e.g., /results)
 * @param args[3] THIS OPTION IS NOT USED IN CURRENT IMPLEMENTATION BECAUSE WE SAMPLE HashDB IN ADVANCE; If you specify this option, you can use values in 0 < x <= 1. No option means no sampling. (e.g., 0.005 means sampling search in 0.5%)
 *
 */
public class hashSearch {

    //static private int sectorSize=4096;
    static private int sectorSize=512;

    static private Double SamplingRate = 1.0;
    static private Random rands = new Random();

    static class SearchMapper extends Mapper<Text, Text, Text, NullWritable>{
	private String[] hashList;
	private int strSize = 0;

	public void setup(Context context) throws IOException, InterruptedException {
	    Configuration conf = context.getConfiguration();
	    String size = conf.get("size");
	    strSize = Integer.parseInt(size);
	    System.out.println("HashList size is " + strSize);
	    hashList = new String[strSize];
	    for(int i=0; i<strSize; i++) {
                hashList[i] = new String(conf.get(String.valueOf(i)));
                System.out.println(i+","+hashList[i]);
	    }
	}

	public void map(Text key, Text value, Context context) throws IOException, InterruptedException {
	    // Simple Random Sampling
	    if( rands.nextDouble() <= SamplingRate ) {
		Text keyOut = new Text();
		//System.out.println(key);
		String k;
		StringTokenizer st = new StringTokenizer(key.toString(), ",");
		ByteControl bc = new ByteControl(value.toString());
		//System.out.println(bc.getSecNum());
		for(int a = 0; a < bc.getSecNum(); a++) {
		    k = String.valueOf(st.nextToken());
		    for(int j = 0; j < strSize; j++) {
                        if (hashList[j].equals(k)) {
			    keyOut.set(value);
                        }
		    }
		}
		context.write(keyOut, NullWritable.get());
	    }
	}
    }


    public static class SearchReducer extends Reducer<Text, NullWritable, Text, NullWritable> {
	public void reduce(Text key, Iterable<NullWritable> values, Context context) throws IOException, InterruptedException {
	    context.write(key, NullWritable.get());
	}
    }


    public static void main(String [] args) throws Exception {
        long start = System.currentTimeMillis();
        Configuration conf= new Configuration();
        HashAlgorithm h = new HashAlgorithm("MD5");
        int FileSize = 0, listSize = 0;
	
	// Setup sampling rate
	if (args.length == 4) {	
	    SamplingRate = Double.parseDouble(args[3]);
	} else {
	    // No sampling
	    SamplingRate = 1.0;
	}
	System.out.printf("Sampling rate is set to: %f \n", SamplingRate);


        FileInputStream input = new FileInputStream(args[0]);
        byte[] sector = new byte[sectorSize];
        FileSize = (int) new File(args[0]).length();
        listSize = FileSize/sectorSize + 1;
        if( FileSize % sectorSize == 0 ) { listSize--; } // IMPORTANT!
        //conf.set("size", String.valueOf(listSize));
        int i = 0, j = 0;
        while(input.read(sector) != -1) {
	    // If sector is filled with all same byte character (0x00, etc.), skip searching the sector
	    byte tmp = sector[0];
	    for (j=1; j<sectorSize; j++) {
		if( tmp != sector[j] ) break;
	    }

	    if( j==sectorSize ) {
		// the sector is filled with all same byte
		//System.out.println("Skip searching the sector filled with " + String.format("%02X", tmp));
	    } else {
		conf.set(String.valueOf(i), h.toHashValue(sector));
		//System.out.println("Added hash:" + h.toHashValue(sector));
		i++;
	    }
	    Arrays.fill(sector, (byte)0x00);         // clear slack space
        }
	System.out.println("# of valid hash is: " + i);

        listSize = i;
        if ( listSize == 0 ) {
	    System.out.println("The file does not contain valid sectors");
	    return;
        }
        conf.set("size", String.valueOf(listSize));
        Job job = new Job(conf, "Search Hash Database");
        job.setJarByClass(hashSearch.class);
        job.setInputFormatClass(SequenceFileInputFormat.class);
        job.setMapperClass(SearchMapper.class);
        job.setReducerClass(SearchReducer.class);
        job.setOutputKeyClass(Text.class);
        job.setOutputValueClass(NullWritable.class);
        FileInputFormat.addInputPath(job, new Path(args[1]));
        FileOutputFormat.setOutputPath(job, new Path(args[2]));
        job.waitForCompletion(true);
        long stop = System.currentTimeMillis();
        System.out.println((stop-start)+":ms");
    }
}
