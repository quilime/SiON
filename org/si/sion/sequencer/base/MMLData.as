//----------------------------------------------------------------------------------------------------
// MML data class
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.sequencer.base {
    import org.si.sion.module.SiOPMWaveTable;
    import org.si.sion.module.SiOPMWavePCMTable;
    import org.si.sion.module.SiOPMWavePCMData;
    import org.si.sion.module.SiOPMWaveSamplerTable;
    import org.si.sion.module.SiOPMWaveSamplerData;
    import org.si.sion.module.SiOPMTable;
    import org.si.sion.module._siopm_module_internal;
    
    
    /** MML data class. MMLData > MMLSequenceGroup > MMLSequence > MMLEvent (">" meanse "has a"). */
    public class MMLData
    {
    // namespace
    //--------------------------------------------------
        use namespace _sion_sequencer_internal;
        
        
        
        
    // valiables
    //--------------------------------------------------
        /** Sequence group */
        public var sequenceGroup:MMLSequenceGroup;
        /** Global sequence */
        public var globalSequence:MMLSequence;
        
        /** default FPS */
        public var defaultFPS:int;
        /** Title */
        public var title:String;
        /** Author */
        public var author:String;
        /** @private [sion sequencer internal] default BPM of this data */
        _sion_sequencer_internal var _initialBPM:BeatPerMinutes;
        
        /** wave tables */
        protected var waveTables:Vector.<SiOPMWaveTable>;
        /** pcm data (log-transformed) */
        protected var pcmData:Vector.<SiOPMWavePCMTable>;
        /** wave data */
        protected var sampleTable:SiOPMWaveSamplerTable;
        
        /** @private [sion sequencer internal] system commands that can not be parsed */
        _sion_sequencer_internal var _systemCommands:Array;
        
        
        
        
    // properties
    //--------------------------------------------------
        /** sequence count */
        public function get sequenceCount() : int { return sequenceGroup.sequenceCount; }
        
        
        /** Beat per minutes, 0 when this data depends on driver's BPM. */
        public function set bpm(t:Number) : void {
            _initialBPM = (t>0) ? (new BeatPerMinutes(t, 44100)) : null;
        }
        public function get bpm() : Number {
            return (_initialBPM) ? _initialBPM.bpm : 0;
        }
        
        
        /** system commands that can not be parsed. Examples are for mml string "#ABC5{def}ghi;".<br/>
         *  the array elements are Object. and it has properties of ...<br/>
         *  <ul>
         *  <li>command: command name. this always starts with "#". ex) command = "#ABC"</li>
         *  <li>number:  number after command. ex) number = 5</li>
         *  <li>content: content inside {...}. ex) content = "def"</li>
         *  <li>postfix: number after command. ex) postfix = "ghi"</li>
         *  </ul>
         */
        public function get systemCommands() : Array { return _systemCommands; }
        
        
        /** Get song length by tick count (1920 for wholetone). */
        public function get tickCount() : int { return sequenceGroup.tickCount; }
        
        
        /** does this song have all repeat comand ? */
        public function get hasRepeatAll() : Boolean { return sequenceGroup.hasRepeatAll; }
        
        
        
        
    // constructor
    //--------------------------------------------------
        function MMLData()
        {
            sequenceGroup = new MMLSequenceGroup(this);
            globalSequence = new MMLSequence();
            
            _initialBPM = null;
            defaultFPS = 60;
            title = "";
            author = "";
            
            waveTables  = new Vector.<SiOPMWaveTable>(SiOPMTable.WAVE_TABLE_MAX);
            pcmData     = new Vector.<SiOPMWavePCMTable>(SiOPMTable.PCM_DATA_MAX);
            sampleTable = new SiOPMWaveSamplerTable();
            _systemCommands = [];
        }
        
        
        
        
    // operation
    //--------------------------------------------------
        /** Clear all parameters and free all sequence groups. */
        public function clear() : void
        {
            var i:int, imax:int;
            
            sequenceGroup.free();
            globalSequence.free();
            
            _initialBPM = null;
            defaultFPS = 60;
            title = "";
            author = "";
            
            for (i=0; i<SiOPMTable.WAVE_TABLE_MAX; i++) {
                if (waveTables[i]) { 
                    waveTables[i].free();
                    waveTables[i] = null;
                }
            }
            for (i=0; i<SiOPMTable.PCM_DATA_MAX; i++) {
                if (pcmData[i]) {
                    pcmData[i]._siopm_module_internal::_free();
                    pcmData[i] = null;
                }
            }
            sampleTable._siopm_module_internal::_free();
            _systemCommands.length = 0;
            
            globalSequence.initialize();
        }
        
        
        /** Append new sequence.
         *  @param sequence event list for new sequence. when null, create empty sequence.
         *  @return created sequence
         */
        public function appendNewSequence(sequence:Vector.<MMLEvent> = null) : MMLSequence
        {
            var seq:MMLSequence = sequenceGroup.appendNewSequence();
            if (sequence) seq.fromVector(sequence);
            return seq;
        }
        
        
        /** Get sequence. 
         *  @param index The index of seuence
         */
        public function getSequence(index:int) : MMLSequence
        {
            return sequenceGroup.getSequence(index);
        }
        
        
        /** Set wave table data refered by %4.
         *  @param index wave table number.
         *  @param data Vector.&lt;Number&gt; wave shape data ranged from -1 to 1.
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
    }
}


