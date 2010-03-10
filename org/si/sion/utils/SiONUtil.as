//----------------------------------------------------------------------------------------------------
// SiON Utilities
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sion.utils {
    import flash.media.*;
    import flash.utils.ByteArray;
    import org.si.sion.module.SiOPMTable;
    import org.si.sion.module.SiOPMWaveTable;
    
    
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
         *  @param dstChannelCount channel count of extracted data. 1 for monoral, 2 for stereo.
         *  @param length The maximum sample count to extract. The length of returning vector is limited by this value.
         *  @param startPosition Start position to extract. -1 to set extraction continuously.
         *  @return extracted data.
         */
        static public function extract(src:Sound, dst:Vector.<Number>=null, dstChannelCount:int=1, length:int=1048576, startPosition:int=-1) : Vector.<Number>
        {
            var wave:ByteArray = new ByteArray(), i:int, imax:int;
            src.extract(wave, length, startPosition);
            if (dst == null) dst = new Vector.<Number>();
            wave.position = 0;
            if (dstChannelCount == 2) {
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
        
        
        /** extract ADPCM data
         *  @param src The ADPCM ByteArray data extracting from. 
         *  @param dst The Vector.<Number> instance to put result. You can pass null to create new Vector.<Number> inside.
         *  @param dstChannelCount channel count of extracted data. 1 for monoral, 2 for stereo.
         *  @return extracted data.
         */
        static public function extractADPCM(src:ByteArray, dst:Vector.<Number>=null, dstChannelCount:int=1) : Vector.<Number>
        {
            var data:int, r0:int, r1:int, i:int, imax:int, 
                predRate:int = 127, output:int = 0;
        
            // chaging ratio table
            var crTable:Vector.<int> = Vector.<int>([1,3,5,7,9,11,13,15,-1,-3,-5,-7,-9,-11,-13,-15]);
            // prediction updating table
            var puTable:Vector.<int> = Vector.<int>([57,57,57,57,77,102,128,153,57,57,57,57,77,102,128,153]);
            
            imax = src.length * 2;
            if (dst == null) dst = new Vector.<Number>();
            dst.length = imax;
            
            for (i=0; i<imax;) {
                data = src.readUnsignedByte();
                r0 = (data >> 4) & 0x0f;
                r1 = data & 0x0f;
                
                predRate = (predRate * crTable[r0]) >> 3;
                output += predRate;
                dst[i] = output * 0.000030517578125;
                predRate = (predRate * puTable[r0]) >> 6;
                     if (predRate < 127)   predRate = 127;
                else if (predRate > 24576) predRate = 24576;
                i++;
                
                predRate = (predRate * crTable[r1]) >> 3;
                output += predRate;
                dst[i] = output * 0.000030517578125;
                predRate = (predRate * puTable[r1]) >> 6;
                     if (predRate < 127)   predRate = 127;
                else if (predRate > 24576) predRate = 24576;
                i++;
            }
            
            return dst;
        }
        
        
        /** Calculate sample length from 16th beat. 
         *  @param bpm Beat per minuits.
         *  @param beat16 Count of 16th beat.
         *  @return sample length.
         */
        static public function calcSampleLength(bpm:Number, beat16:Number=4) : Number
        {
            // 661500 = 44100*60/4
            return beat16 * 661500 / bpm;
        }
        
        
        
        /** Check silent length at the head of Sound.
         *  @param src source Sound
         *  @param threshold threshold level to detect sound.
         *  @return silent length in sample count.
         */
        static public function getHeadSilence(src:Sound, threshold:Number = 0.01) : int
        {
            var wave:ByteArray = new ByteArray(), i:int, imax:int, extracted:int, n:Number;
            
            threshold *= 2;
            
            imax = 1024;
            for (extracted=0; imax==1024; extracted+=1024) {
                wave.length = 0;
                imax = src.extract(wave, 1024);
                wave.position = 0;
                for (i=0; i<imax; i++) {
                    n = wave.readFloat() + wave.readFloat();
                    if (n >= threshold) return extracted + i;
                }
            }
            
            return extracted;
        }
        

        /** Detect distance[ms] of 2 peaks, [estimated bpm] = 60000/getPeakDistance().
         *  @param sample stereo samples, the length must be grater than 59136*2(stereo).
         *  @return distance[ms] of 2 peaks.
         */
        static public function getPeakDistance(sample:Vector.<Number>) : Number
        {
            var i:int, j:int, k:int, idx:int, n:Number, m:Number, envAccum:Number;

            // calculate envelop
            m = envAccum = 0;
            for (i=0, idx=0; i<462; i++) {
                for (n=0, j=0; j<128; j++, idx+=2) n += sample[idx];
                m += n;
                envAccum *= 0.875;
                envAccum += m * m;
                _envelop[i] = envAccum;
                m = n;
            }
            
            // calculate cross correlation and find peak index
            for (i=0, idx=0; i<113; i++) {
                for (n=0, j=0, k=113+i; j<226; j++, k++) n += _envelop[j]*_envelop[k];
                _xcorr[i] = n;
                if (_xcorr[idx] < n) idx = i;
            }
            
            // caluclate bpm 2.9024943310657596 = 128/44.1
            return (113 + idx) * 2.9024943310657596;
        }
        // 461.9375 = 59128/128, 59128 = length for 2 beats on bpm=89.5
        static private var _envelop:Vector.<Number> = new Vector.<Number>(462);
        static private var _xcorr:Vector.<Number> = new Vector.<Number>(113);
        
        
        
        
    // wave table
    //--------------------------------------------------
        /** create Wave table Vector from wave color.
         *  @param color wave color value
         *  @param waveType wave type (the voice number of '%5')
         *  @param dst returning Vector.<Number>. if null, allocate new Vector inside.
         */
        static public function waveColor(color:uint, waveType:int=0, dst:Vector.<Number>=null) : Vector.<Number>
        {
            if (dst == null) dst = new Vector.<Number>(SiOPMTable.SAMPLING_TABLE_SIZE);
            var len:int, bits:int=0;
            for (len=dst.length>>1; len!=0; len>>=1) bits++;
            dst.length = 1<<bits;
            bits = SiOPMTable.PHASE_BITS - bits;
            
            var i:int, imax:int, j:int, gain:int, mul:int, n:Number, nmax:Number, 
                bars:Vector.<Number> = new Vector.<Number>(7),
                barr:Vector.<int> = Vector.<int>([1,2,3,4,5,6,8]),
                log:Vector.<int> = SiOPMTable.instance.logTable,
                waveTable:SiOPMWaveTable = SiOPMTable.instance.getWaveTable(waveType + (color>>>28)),
                wavelet:Vector.<int> = waveTable.wavelet, fixedBits:int = waveTable.fixedBits,
                filter:int = SiOPMTable.PHASE_FILTER, envtop:int = (-SiOPMTable.ENV_TOP)<<3,
                index:int, step:int = SiOPMTable.PHASE_MAX >> bits;
            
            for (i=0; i<7; i++, color>>=4) bars[i] = (color & 15) * 0.0625;

            imax = SiOPMTable.PHASE_MAX;
            nmax = 0;
            for (i=0; i<imax; i+=step) {
                j = i>>bits;
                dst[j] = 0;
                for (mul=0; mul<7; mul++) {
                    index = (((i * barr[mul]) & filter) >> fixedBits);
                    gain = wavelet[index] + envtop;
                    dst[j] += log[gain] * bars[mul];
                }
                n = (dst[j]<0) ? -dst[j] : dst[j];
                if (nmax < n) nmax = n;
            }

            if (nmax < 8192) nmax = 8192
            n = 1/nmax;
            imax = dst.length;
            for (i=0; i<imax; i++) dst[i] *= n;
            return dst;
        }
    }
}

