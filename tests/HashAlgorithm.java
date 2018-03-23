package jp.ac.toyota_ct.analysis_sys;

import java.security.*;
import java.util.*;
import java.io.*;

/**
 * Hash algorithm for sector-hash
 * @author Takase Hayate
 * @author Yoshida Koki
 */

class HashAlgorithm {

    public MessageDigest md = null;
    private static boolean DEBUG = false;

    /*
     * You can specify the following values as algorithm
     *  MD2, MD5, SHA, SHA-256, SHA-384, SHA-512
     */
    public HashAlgorithm(String algorithmName) {
	try {
	    md = MessageDigest.getInstance(algorithmName);
	} catch (NoSuchAlgorithmException e) {
	    e.printStackTrace();
	}
    }

    /*
     * creates hash values from byte array
     */
    public String toHashValue(byte[] b) throws IOException{
	byte[] digest;

	md.update(b);
	digest = md.digest();

	if(DEBUG) {
	    System.out.println(b.length);
	    for (int i = 0; i < b.length; i++) {
		System.out.print(Integer.toHexString(b[i] & 0xff));
	    }
	    System.out.println();
	    System.out.println("MD5: "+toEncryptedString(digest));
	}
		
	return toEncryptedString(digest);
    }

    /*
     * returns hex strings of byte array (notice: not encrypted)
     */
    public String toEncryptedString(byte[] bytes) {
	StringBuilder sb = new StringBuilder();
	for (byte b : bytes) {
	    String hex = String.format("%02x", b);
	    sb.append(hex);
	}
	return sb.toString();
    }

}
