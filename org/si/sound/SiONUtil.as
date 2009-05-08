//----------------------------------------------------------------------------------------------------
// SiON Utilities
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------




package org.si.sound {
    import flash.media.*;
    import flash.utils.ByteArray;
    import org.si.sound.module.SiOPMTable;
    
    
    
    
    /** Utilities for SiON */
    public class SiONUtil {
        
    // PCM data serialization (for PCM Data)
    //--------------------------------------------------
        /** Serialize Sound wave */
        static public function serialize(data:Sound, sampleMax:int=1048576) : Vector.<int>
        {
            var wave:ByteArray = new ByteArray();
            var samples:int = data.extract(wave, sampleMax);
            return serializeByteArrayPCM(wave, new Vector.<int>);
        }
        
        
        /** Serialize Vector.<Number> wave */
        static public function serializeVectorPCM(src:Vector.<Number>, dst:Vector.<int>) : Vector.<int>
        {
            var i:int, j:int, imax:int=src.length>>1;
            dst.length = imax;
            for (i=0; i<imax; i++) {
                j = i<<1;
                dst[i] = SiOPMTable.calcLogTableIndex(src[j]);
            }
            return dst;
        }
        
        
        /** Serialize ByteArray wave */
        static public function serializeByteArrayPCM(src:ByteArray, dst:Vector.<int>) : Vector.<int>
        {
            var i:int, imax:int=src.length>>3;
            src.position = 0;
            dst.length = imax;
            for (i=0; i<imax; i++) {
                dst[i] = SiOPMTable.calcLogTableIndex(src.readFloat());
                src.readFloat();
            }
            return dst;
        }
        
        
        
        
    // raw wave data (for Sampler Data)
    //--------------------------------------------------
        /** get raw data from Sound */
        static public function getRawData(data:Sound, channels:int=1, sampleMax:int=1048576) : Vector.<int>
        {
            var wave:ByteArray = new ByteArray();
            var samples:int = data.extract(wave, sampleMax);
            return getRawDataByteArrayPCM(wave, new Vector.<int>, channels);
        }
        
        
        /** get raw data from Vector.<Number> wave */
        static public function getRawDataVectorPCM(src:Vector.<Number>, dst:Vector.<int>, channels:int=1) : Vector.<int>
        {
            var i:int, j0:int, j1:int, imax:int=src.length>>1;
            dst.length = imax;
            if (channels == 2) {
                for (i=0; i<imax; i++) {
                    j0 = i<<1;
                    j1 = j0 + 1;
                    dst[i] = int((src[j0]+1)*32767) + ((int((src[j1]+1)*32767))<<16);
                }
            } else {
                for (i=0; i<imax; i++) {
                    j0 = i<<1;
                    dst[i] = int(src[j0]*32767);
                }
            }
            return dst;
        }
        
        
        /** get raw data from ByteArray wave */
        static public function getRawDataByteArrayPCM(src:ByteArray, dst:Vector.<int>, channels:int=1) : Vector.<int>
        {
            var i:int, imax:int=src.length>>3;
            src.position = 0;
            dst.length = imax;
            if (channels == 2) {
                for (i=0; i<imax; i++) {
                    dst[i] = int((src.readFloat()+1)*32767) + ((int((src.readFloat()+1)*32767))<<16);
                }
            } else {
                for (i=0; i<imax; i++) {
                    dst[i] = int(src.readFloat()*32767);
                    src.readFloat();
                }
            }
            return dst;
        }
    }
}

