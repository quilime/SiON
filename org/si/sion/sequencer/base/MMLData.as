//----------------------------------------------------------------------------------------------------
// MML data class
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.sequencer.base {
    import org.si.sion.module.SiOPMWaveTable;
    import org.si.sion.module.SiOPMPCMData;
    import org.si.sion.module.SiOPMSamplerData;
    import org.si.sion.module.SiOPMTable;
    
    
    /** MML data class. MMLData > MMLSequenceGroup > MMLSequence > MMLEvent (">" meanse "has a"). */
    public class MMLData
    {
    // valiables
    //--------------------------------------------------
        /** Sequence group */
        public var sequenceGroup:MMLSequenceGroup;
        /** Global sequence */
        public var globalSequence:MMLSequence;
        
        /** default BPM */
        public var defaultBPM:int;
        /** default FPS */
        public var defaultFPS:int;
        /** Title */
        public var title:String;
        /** Author */
        public var author:String;
        
        /** wave tables */
        public var waveTables:Vector.<SiOPMWaveTable>;
        /** pcm data (log-transformed) */
        public var pcmData:Vector.<SiOPMPCMData>;
        /** wave data */
        public var samplerData:Vector.<SiOPMSamplerData>;
        
        /** system commands can not be parsed. Examples are for mml string "#ABC5{def}ghi;".<br/>
         *  the array elements are Object. and it has properties of ...<br/>
         *  command: command name. this always starts with "#". ex) command = "#ABC"
         *  number:  number after command. ex) number = 5
         *  content: content inside {...}. ex) content = "def"
         *  postfix: number after command. ex) postfix = "ghi"
         */
        public var systemCommands:Array;
        
        
        
        
    // properties
    //--------------------------------------------------
        
        
        
        
    // constructor
    //--------------------------------------------------
        function MMLData()
        {
            sequenceGroup = new MMLSequenceGroup();
            globalSequence = new MMLSequence();
            
            defaultBPM = 120;
            defaultFPS = 60;
            title = "";
            author = "";
            
            waveTables  = new Vector.<SiOPMWaveTable>(SiOPMTable.WAVE_TABLE_MAX);
            pcmData     = new Vector.<SiOPMPCMData>(SiOPMTable.PCM_DATA_MAX);
            samplerData = new Vector.<SiOPMSamplerData>(SiOPMTable.SAMPLER_DATA_MAX);
            systemCommands = [];
        }
        
        
        
        
    // operation
    //--------------------------------------------------
        /** Clear all parameters and free all sequence groups. */
        public function clear() : void
        {
            var i:int, imax:int;
            
            sequenceGroup.free();
            globalSequence.free();
            
            defaultBPM = 120;
            defaultFPS = 60;
            title = "";
            author = "";
            
            for (i=0; i<SiOPMTable.WAVE_TABLE_MAX; i++)   { if (waveTables[i])  { waveTables[i].free();  waveTables[i] = null; } }
            for (i=0; i<SiOPMTable.PCM_DATA_MAX; i++)     { if (pcmData[i])     { pcmData[i].free();     pcmData[i] = null; } }
            for (i=0; i<SiOPMTable.SAMPLER_DATA_MAX; i++) { if (samplerData[i]) { samplerData[i].free(); samplerData[i] = null; } }
            systemCommands.length = 0;
        }
        
        
        /** Register all tables before processing audio. */
        public function regiter() : void
        {
            SiOPMTable.instance.stencilCustomWaveTables = waveTables;
            SiOPMTable.instance.stencilPCMData          = pcmData;
            SiOPMTable.instance.stencilSamplerData      = samplerData;
        }
        
        
        /** Set wave table data refered by %4.
         *  @param index wave table number.
         *  @param data Vector.<Number> wave shape data ranged from -1 to 1.
         *  @return created data instance
         */
        public function setWaveTable(index:int, data:Vector.<Number>) : SiOPMWaveTable
        {
            index &= SiOPMTable.WAVE_TABLE_MAX-1;
            var i:int, imax:int=data.length;
            var table:Vector.<int> = new Vector.<int>(imax);
            for (i=0; i<imax; i++) table[i] = SiOPMTable.calcLogTableIndex(data[i]);
            waveTables[index] = SiOPMWaveTable.alloc(table);
            return waveTables[index];
        }
        
        
        /** Set PCM data rederd from %7.
         *  @param index PCM data number.
         *  @param data Vector.<Number> wave data. This type ussualy comes from render().
         *  @param isDataStereo Flag that the wave data is stereo or monoral.
         *  @param samplingOctave Sampling frequency. The value of 5 means that "o5a" is original frequency.
         *  @return created data instance
         *  @see #org.si.sion.SiONDriver.render()
         */
        public function setPCMData(index:int, data:Vector.<Number>, isDataStereo:Boolean=true, samplingOctave:int=5) : SiOPMPCMData
        {
            index &= SiOPMTable.PCM_DATA_MAX-1;
            
            var i:int, j:int, imax:int;
            var pcm:Vector.<int>;
            if (isDataStereo) {
                imax = data.length>>1;
                pcm = new Vector.<int>(imax);
                for (i=0; i<imax; i++) {
                    j = i<<1;
                    pcm[i] = SiOPMTable.calcLogTableIndex(data[j]);
                }
            } else {
                imax = data.length;
                pcm = new Vector.<int>(imax);
                for (i=0; i<imax; i++) {
                    pcm[i] = SiOPMTable.calcLogTableIndex(data[i]);
                }
            }
            pcmData[index] = SiOPMPCMData.alloc(pcm, samplingOctave);
            return pcmData[index];
        }
        
        
        /** Set sampler data refered by %10.
         *  @param index note number. 0-127 for bank0, 128-255 for bank1.
         *  @param data Vector.<Number> wave data. This type ussualy comes from SiONDriver.render().
         *  @param isOneShot True to set "one shot" sound. The "one shot" sound ignores note off.
         *  @param channelCount 1 for monoral, 2 for stereo.
         *  @return created data instance
         *  @see #org.si.sion.SiONDriver.render()
         */
        public function setSamplerData(index:int, data:Vector.<Number>, isOneShot:Boolean=true, channelCount:int=2) : SiOPMSamplerData
        {
            index &= SiOPMTable.SAMPLER_DATA_MAX-1;
            samplerData[index] = new SiOPMSamplerData(data, isOneShot, channelCount);
            return samplerData[index];
        }
    }
}


