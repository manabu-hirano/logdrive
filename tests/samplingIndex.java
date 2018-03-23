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
import org.apache.hadoop.mapreduce.lib.output.SequenceFileOutputFormat;
import org.apache.hadoop.fs.FSDataInputStream;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.util.*;

/**
 * Creates sampled HashDB from original HashDB
 *
 * @author Manabu Hirano
 * @since 2017/11/15
 * @param args[0] Input HashDB file in HDFS (e.g., /preservation-vm-1.md5)
 * @param args[1] Output HashDB file in HDFS (e.g., /preservation-vm-1.md5-0.005)
 * @param args[2] Samplig rate (0 < x <= 1); No option means no sampling (i.e., sampling rate is set to 1.0). e.g., 0.005 means to create HashDB in sampling rate of 0.5%
 */
public class samplingIndex {

    static class SamplingMapper extends Mapper<Text, Text, Text, Text>{

	private Double SamplingRate = 0.0;
	private Random rands = new Random();

	public void setup(Context context) throws IOException, InterruptedException {
	    Configuration conf = context.getConfiguration();
	    String sr = conf.get("SamplingRate");
	    SamplingRate = Double.parseDouble(sr);
	}

	public void map(Text key, Text value, Context context) throws IOException, InterruptedException {
	    // Simple Random Sampling
	    if( rands.nextDouble() <= SamplingRate ) {
		context.write(key, value);
	    }
	}
    }


    public static class SamplingReducer extends Reducer<Text, Text, Text, Text> {
	public void reduce(Text key, Text values, Context context) throws IOException, InterruptedException {
	    context.write(key, values);
	}
    }


    public static void main(String [] args) throws Exception {
        long start = System.currentTimeMillis();
        Configuration conf= new Configuration();
	Double SamplingRate = 0.0;
	
	// Setup sampling rate
	if (args.length == 3) {	
	    SamplingRate = Double.parseDouble(args[2]);
	} else {
	    // No sampling
	    SamplingRate = 0.0;
	}
	System.out.printf("Sampling rate is set to: %f\n", SamplingRate);
	conf.set("SamplingRate",String.valueOf(SamplingRate));
	System.out.println("String is " + conf.get("SamplingRate"));
        Job job = new Job(conf, "Sampling Hash Database");
        job.setJarByClass(samplingIndex.class);
        job.setInputFormatClass(SequenceFileInputFormat.class);
	job.setOutputFormatClass(SequenceFileOutputFormat.class);
        job.setMapperClass(SamplingMapper.class);
        job.setReducerClass(SamplingReducer.class);
        job.setOutputKeyClass(Text.class);
        job.setOutputValueClass(Text.class);
        FileInputFormat.addInputPath(job, new Path(args[0]));
        FileOutputFormat.setOutputPath(job, new Path(args[1]));
        job.waitForCompletion(true);
        long stop = System.currentTimeMillis();
        System.out.println((stop-start)+":ms");
    }
}
