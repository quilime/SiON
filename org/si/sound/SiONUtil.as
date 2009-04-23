//----------------------------------------------------------------------------------------------------
// SiON Utilities
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------




package org.si.sound {
    import flash.media.*;
    import flash.utils.ByteArray;
    import org.si.sound.module.SiOPMTable;
    
    
    
    
    public class SiONUtil {
        
    // PCM data serialization
    //--------------------------------------------------
        /** Serialize Sound wave */
        static public function serializeSound(data:Sound, sampleMax:int=1048576) : Vector.<int>
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
        
        
        
        
    // raw wave data
    //--------------------------------------------------
        /** get raw data from Sound */
        static public function getRawData(data:Sound, channels:int=1, sampleMax:int=1048576) : Vector.<int>
        {
            var wave:ByteArray = new ByteArray();
            var samples:int = data.extract(wave, sampleMax);
            return rawdataByteArrayPCM(wave, new Vector.<int>, channels);
        }
        
        
        /** get raw data from Vector.<Number> wave */
        static public function rawdataVectorPCM(src:Vector.<Number>, dst:Vector.<int>, channels:int=1) : Vector.<int>
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
        static public function rawdataByteArrayPCM(src:ByteArray, dst:Vector.<int>, channels:int=1) : Vector.<int>
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
        

    // Wave shaper
    //--------------------------------------------------
        /** wave shaper for Vector.<Number> */
        static public function waveShapeVector(src:Vector.<Number>, distortion:Number) : void
        {
            var coef:Number = 2 * distortion / (1-distortion),
                c1:Number = 1 + coef;
            var i:int, imax:int=src.length, n:Number;
            for (i=0; i<imax; i++) {
                n = src[i];
                src[i] = c1 * n / (1 + coef * ((n<0) ? -n : n));
            }
        }
        
        
        /** wave shaper for ByteArray */
        static public function waveShapeByteArray(src:ByteArray, distortion:Number) : void
        {
            var coef:Number = 2 * distortion / (1-distortion),
                c1:Number = 1 + coef;
            var i:int, imax:int=src.length>>3, n:Number;
            for (i=0; i<imax; i++) {
                src.position = i;
                n = src.readFloat();
                src.position = i;
                src.writeFloat(c1 * n / (1 + coef * ((n<0) ? -n : n)));
            }
        }
        
        
        /** wave shaper for raw data */
        static public function waveShapeRawData(src:Vector.<int>, channels:int, distortion:Number) : void
        {
            var coef:Number = 2 * distortion / (1-distortion),
                c1:Number = (1 + coef) * 32768;
            var i:int, imax:int=src.length, n:Number;
            if (channels == 2) {
                for (i=0; i<imax; i++) {
                    n = (src[i] & 65535) * 0.000030517578125 - 1;
                    src[i] = int(c1 * n / (1 + coef * ((n<0) ? -n : n))) + 32768;
                    n = (src[i] >> 16) * 0.000030517578125 - 1;
                    src[i] += (int(c1 * n / (1 + coef * ((n<0) ? -n : n))) + 32768)<<16;
                }
            } else {
                for (i=0; i<imax; i++) {
                    n = src[i] * 0.000030517578125;
                    src[i] = int(c1 * n / (1 + coef * ((n<0) ? -n : n)));
                }
            }
        }
        
        
    }
}

