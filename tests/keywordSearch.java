package jp.ac.toyota_ct.analysis_sys;

import java.io.*;
import java.security.*;
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
 * String search in HashDB
 *
 * @author Yoshida Koki
 *
 * @param args[0] keyword string  (e.g., test)
 * @param args[1] HashDB file in HDFS (e.g., /preservation-vm-1.md5)
 * @param args[2] Output directory in HDFS (e.g., /results)
 * 
 */
public class keywordSearch{
    static class keyMapper extends Mapper<BytesWritable, BytesWritable, Text, NullWritable>{
	byte[] stb;
	String str;

	public void setup(Context context) throws IOException, InterruptedException{
	    Configuration conf = context.getConfiguration();
	    str = conf.get("word");
	    stb = str.getBytes("UTF-8");
	}

	public void map(BytesWritable key, BytesWritable value, Context context) throws IOException, InterruptedException {
	    ByteControl bc = new ByteControl(key.getBytes());
	    Text keyOut = new Text(),
		value_out = new Text();
	    byte[] data = value.getBytes();

	    for(int i=0 ; i < (bc.getSize() - stb.length + 1) ; i++){
		for(int j=0 ; j < stb.length ; j++){
		    if(data[i + j] == stb[j]){
			if(j == stb.length - 1){
			    keyOut.set(String.valueOf(bc.getSec()) + "," + String.valueOf(bc.getNsec()) + ","+ bc.getBlockNum().toString() + "," + String.valueOf(bc.getSize()));
			    context.write(keyOut, NullWritable.get());
			}
		    }else{
			break;
		    }
		}
	    }
	}
    }

    public static class keyReducer extends Reducer<Text, NullWritable, Text, NullWritable> {
	public void reduce(Text key, NullWritable values, Context context) throws IOException, InterruptedException {
	    context.write(key, values);
	}
    }

    public static void main(String [] args) throws Exception{
	long start = System.currentTimeMillis();
	Configuration conf= new Configuration();
	conf.set("word", args[0]);
	Job job = new Job(conf);
	job.setJarByClass(keywordSearch.class);
	job.setInputFormatClass(SequenceFileInputFormat.class);
	//job.setOutputFormatClass(SequenceFileOutputFormat.class);
	job.setMapperClass(keyMapper.class);
	job.setReducerClass(keyReducer.class);
	job.setOutputKeyClass(Text.class);
	job.setOutputValueClass(NullWritable.class);
	FileInputFormat.addInputPath(job, new Path(args[1]));
	FileOutputFormat.setOutputPath(job, new Path(args[2]));
	job.waitForCompletion(true);
	long stop = System.currentTimeMillis();
	System.out.println((stop - start)+":ms");
    }
}

