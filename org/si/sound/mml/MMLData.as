//----------------------------------------------------------------------------------------------------
// MML data class
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------




package org.si.sound.mml {
    import flash.utils.ByteArray;
    
    
    
    
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
        public var waveTables:Array;
        
        
        
        
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
            
            waveTables = [];
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
            
            for each (var table:MMLDataWaveTable in waveTables) { MMLDataWaveTable.free(table); }
            waveTables.length = 0;
        }
        
        
        /** Register all tables before processing audio. */
        public function regiterAllTables() : void
        {
            for each (var table:MMLDataWaveTable in waveTables) { table.register(); }
        }
        
        
        /** Set wave table data */
        public function setWaveTable(index:int, table:Vector.<Number>, bits:int) : void
        {
            waveTables.push(MMLDataWaveTable.alloc(index, table, bits));
        }
    }
}




import org.si.sound.module.SiOPMTable;


class MMLDataWaveTable
{
    public var index:int;
    public var waveFixedBits:int;
    public var waveTable:Vector.<int>;
    static private var _freeList:Array = [];
   
    
    function MMLDataWaveTable()
    {
        index = -1;
        waveFixedBits = 0;
        waveTable = null;
    }
    
    
    public function register() : void
    {
        SiOPMTable.registerWaveTable(index, waveTable, waveFixedBits);
    }
    
    
    static public function free(e:MMLDataWaveTable) : void
    {
        e.index = -1;
        _freeList.push(e); 
    }

    
    static public function alloc(index:int, table:Vector.<Number>, bits:int) : MMLDataWaveTable
    { 
        var i:int, imax:int;
        
        // new element
        var e:MMLDataWaveTable = _freeList.pop() || new MMLDataWaveTable();

        // initialize
        e.index = index;
        if (e.waveFixedBits != SiOPMTable.PHASE_BITS - bits) {
            e.waveTable = new Vector.<int>(1<<bits);
            e.waveFixedBits = SiOPMTable.PHASE_BITS - bits;
        }
        
        // copy wave table
        imax = e.waveTable.length;
        for (i=0; i<imax; i++) {
            e.waveTable[i] = SiOPMTable.calcLogTableIndex(table[i]);
        }
        
        return e;
    }
}

