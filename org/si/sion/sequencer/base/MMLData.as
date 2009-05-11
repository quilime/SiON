//----------------------------------------------------------------------------------------------------
// MML data class
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.sequencer.base {
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
        public var waveTables:Vector.<MMLDataWaveTable>;
        /** pcm data (serialized) */
        public var pcmData:Vector.<MMLDataWaveTable>;
        /** wave data (raw wave) */
        public var waveData:Vector.<MMLDataWaveTable>;
        
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
            
            waveTables = new Vector.<MMLDataWaveTable>();
            pcmData    = new Vector.<MMLDataWaveTable>();
            waveData   = new Vector.<MMLDataWaveTable>();
            systemCommands = [];
        }
        
        
        
        
    // operation
    //--------------------------------------------------
        /** Clear all parameters and free all sequence groups. */
        public function clear() : void
        {
            sequenceGroup.free();
            globalSequence.free();
            
            defaultBPM = 120;
            defaultFPS = 60;
            title = "";
            author = "";
            
            var table:MMLDataWaveTable;
            for each (table in waveTables) { MMLDataWaveTable.free(table); }
            for each (table in pcmData)    { MMLDataWaveTable.free(table); }
            for each (table in waveData)   { MMLDataWaveTable.free(table); }
            waveTables.length = 0;
            pcmData.length = 0;
            waveData.length = 0;
            systemCommands.length = 0;
        }
        
        
        /** Register all tables before processing audio. */
        public function regiterAllTables() : void
        {
            var table:MMLDataWaveTable;
            for each (table in waveTables) { table.register(); }
            for each (table in pcmData)    { table.register(); }
            for each (table in waveData)   { table.register(); }
        }
        
        
        /** Set wave table data */
        public function setWaveTable(index:int, table:Vector.<Number>, bits:int) : void
        {
            waveTables.push(MMLDataWaveTable.allocWabeTable(index, table, bits));
        }
        
        
        /** Set PCM data */
        public function setPCMData(index:int, serialized:Vector.<int>, samplingOctave:int=5) : void
        {
            pcmData.push(MMLDataWaveTable.allocPCMData(index, serialized, samplingOctave));
        }
        
        
        /** Set wave data */
        public function setWaveData(index:int, rawData:Vector.<int>, isOneShot:Boolean=true, isStereo:Boolean=false) : void
        {
            waveData.push(MMLDataWaveTable.allocWaveData(index, rawData, isOneShot, isStereo));
        }
    }
}




import flash.utils.ByteArray;
import org.si.sion.module.SiOPMTable;

// wave table class
class MMLDataWaveTable
{
    public var index:int;
    public var type:int;
    public var waveFixedBits:int;
    public var waveTable:Vector.<int>;
    static private var _freeTableList:Vector.<MMLDataWaveTable> = new Vector.<MMLDataWaveTable>();
    static private var _freePCMList:Vector.<MMLDataWaveTable> = new Vector.<MMLDataWaveTable>();
   
    
    function MMLDataWaveTable()
    {
        index = -1;
        waveFixedBits = 0;
        type = 0;
        waveTable = new Vector.<int>();
    }
    
    
    public function register() : void
    {
        switch (type) {
        case 0: SiOPMTable.registerWaveTable(index, waveTable, waveFixedBits);  break;
        case 1: SiOPMTable.registerPCMData  (index, waveTable, waveFixedBits);  break;
        case 2: SiOPMTable.registerSample   (index, waveTable, waveFixedBits);  break;
        }
    }
    
    
    static public function free(e:MMLDataWaveTable) : void
    {
        e.index = -1;
        if (e.type == 0) _freeTableList.push(e);
        else _freePCMList.push(e); 
    }

    
    static public function allocWabeTable(index:int, table:Vector.<Number>, bits:int) : MMLDataWaveTable
    { 
        var e:MMLDataWaveTable = _freeTableList.pop() || new MMLDataWaveTable();
        e.type  = 0;
        e.index = index;
        e.waveFixedBits = SiOPMTable.PHASE_BITS - bits;
        
        // copy wave table
        var i:int, imax:int = 1<<bits;
        e.waveTable = e.waveTable || new Vector.<int>();
        e.waveTable.length = imax;
        for (i=0; i<imax; i++) {
            e.waveTable[i] = SiOPMTable.calcLogTableIndex(table[i]);
        }
        return e;
    }

    
    static public function allocPCMData(index:int, serialized:Vector.<int>, samplingOctave:int) : MMLDataWaveTable
    { 
        var e:MMLDataWaveTable = _freePCMList.pop() || new MMLDataWaveTable();
        e.type  = 1;
        e.index = index;
        e.waveFixedBits = samplingOctave;
        e.waveTable = serialized;
        return e;
    }

    
    static public function allocWaveData(index:int, rawData:Vector.<int>, isOneShot:Boolean, isStereo:Boolean) : MMLDataWaveTable
    { 
        var e:MMLDataWaveTable = _freePCMList.pop() || new MMLDataWaveTable();
        e.type  = 2;
        e.index = index;
        e.waveFixedBits = ((isOneShot) ? 2 : 0) + ((isStereo) ? 1 : 0);
        e.waveTable = rawData;
        return e;
    }
}

