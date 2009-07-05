//----------------------------------------------------------------------------------------------------
// SiON Utilities
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sion.utils {
    import flash.media.*;
    import flash.utils.ByteArray;
    import org.si.sion.module.SiOPMTable;
    
    
    /** Utilities for SiON */
    public class SiONUtil {
    // PCM data transformation (for PCM Data %7)
    //--------------------------------------------------
        /** logarithmical transformation of Sound data. The transformed datas type is Vector.<int>. This data is used for PCM sound module (%7).
         *  @param src The Sound data transforming from. 
         *  @param dst The Vector.<int> instance to put result. You can pass null to create new Vector.<int> inside.
         *  @param sampleMax The maximum sample count to transforme. The length of transformed data is limited by this value.
         *  @return logarithmical transformed data.
         */
        static public function logTrans(data:Sound, dst:Vector.<int>=null, sampleMax:int=1048576) : Vector.<int>
        {
            var wave:ByteArray = new ByteArray();
            var samples:int = data.extract(wave, sampleMax);
            return logTransByteArray(wave, dst);
        }
        
        
        /** logarithmical transformation of Vector.<Number> wave data. The transformed datas type is Vector.<int>. This data is used for PCM sound module (%7).
         *  @param src The Vector.<Number> wave data transforming from. This ussualy comes from SiONDriver.render().
         *  @param isDataStereo Flag that the wave data is stereo or monoral.
         *  @param dst The Vector.<int> instance to put result. You can pass null to create new Vector.<int> inside.
         *  @return logarithmical transformed data.
         */
        static public function logTransVector(src:Vector.<Number>, isDataStereo:Boolean=true, dst:Vector.<int>=null) : Vector.<int>
        {
            var i:int, j:int, imax:int;
            if (dst == null) dst = new Vector.<int>();
            if (isDataStereo) {
                imax=src.length>>1;
                dst.length = imax;
                for (i=0; i<imax; i++) {
                    j = i<<1;
                    dst[i] = SiOPMTable.calcLogTableIndex(src[j]);
                }
            } else {
                imax=src.length;
                dst.length = imax;
                for (i=0; i<imax; i++) {
                    dst[i] = SiOPMTable.calcLogTableIndex(src[i]);
                }
            }
            return dst;
        }
        
        
        /** logarithmical transformation of ByteArray wave data. The transformed datas type is Vector.<int>. This data is used for PCM sound module (%7).
         *  @param src The ByteArray wave data transforming from. This is ussualy from Sound.extract().
         *  @param dst The Vector.<int> instance to put result. You can pass null to create new Vector.<int> inside.
         *  @return logarithmical transformed data.
         */
        static public function logTransByteArray(src:ByteArray, dst:Vector.<int>=null) : Vector.<int>
        {
            var i:int, imax:int=src.length>>3;
            src.position = 0;
            if (dst == null) dst = new Vector.<int>();
            dst.length = imax;
            for (i=0; i<imax; i++) {
                dst[i] = SiOPMTable.calcLogTableIndex(src.readFloat());
                src.readFloat();
            }
            return dst;
        }
        
        
        
        
    // wave data
    //--------------------------------------------------
        /** put Sound.extract() result into Vector.<Number>. This data is used for sampler module (%10).
         *  @param src The Sound data extracting from. 
         *  @param dst The Vector.<Number> instance to put result. You can pass null to create new Vector.<Number> inside.
         *  @param channelCount channel count of extracted data. 1 for monoral, 2 for stereo.
         *  @param sampleMax The maximum sample count to extract. The length of returning vector is limited by this value.
         *  @return extracted data.
         */
        static public function extract(src:Sound, dst:Vector.<Number>=null, channelCount:int=1, sampleMax:int=1048576) : Vector.<Number>
        {
            var wave:ByteArray = new ByteArray(), i:int, imax:int;
            src.extract(wave, sampleMax);
            if (dst == null) dst = new Vector.<Number>();
            wave.position = 0;
            if (channelCount == 2) {
                // stereo
                imax = wave.length >> 2;
                dst.length = imax;
                for (i=0; i<imax; i++) {
                    dst[i] = wave.readFloat();
                }
            } else {
                // monoral
                imax = wave.length >> 3;
                dst.length = imax;
                for (i=0; i<imax; i++) {
                    dst[i] = (wave.readFloat() + wave.readFloat()) * 0.6;
                }
            }
            return dst;
        }
        
        
        /** Calculate sample length from 16th beat. */
        static public function calcSampleLength(bpm:Number, beat16:Number) : Number
        {
            // 661500 = 44100*60/4
            return beat16 * 661500 / bpm;
        }
    }
}

