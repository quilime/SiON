//----------------------------------------------------------------------------------------------------
// MML data class
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------




package org.si.sound.mml {
    import flash.utils.ByteArray;
    
    
    
    
    /** MML data class. MMLData > MMLSequenceGroup > MMLSequence > MMLEvent (">" meanse "has array of"). */
    public class MMLData
    {
    // valiables
    //--------------------------------------------------
        /** main MMLSequenceGroup */
        public var mainSequenceGroup:MMLSequenceGroup;
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
        
        
        
        
    // properties
    //--------------------------------------------------
        
        
        
        
    // constructor
    //--------------------------------------------------
        function MMLData()
        {
            mainSequenceGroup = new MMLSequenceGroup();
            globalSequence    = new MMLSequence();
            _sequenceGroups   = [];
            
            defaultBPM = 120;
            defaultFPS = 60;
            title = "";
            author = "";
        }
        
        
        
        
    // operation
    //--------------------------------------------------
        /** Clear all parameters and free all sequence groups. */
        public function clear() : void
        {
            mainSequenceGroup.free();
            globalSequence.free();
            
            for each (var seqGroup:MMLSequenceGroup in _sequenceGroups) {
                seqGroup.free();
                _freeList.push(seqGroup);
            }
            _sequenceGroups.length = 0;
            
            defaultBPM = 120;
            defaultFPS = 60;
            title = "";
        }

        
        
        
    // factory
    //--------------------------------------------------
        // MMLSequenceGroup buffer
        private var _sequenceGroups:Array;
        // free list
        static private var _freeList:Array = [];
        
        
        /** Allocate new sequence and push sequence chain. */
        public function newSequenceGroup() : MMLSequenceGroup
        {
            var seqGroup:MMLSequenceGroup = _freeList.pop() || new MMLSequenceGroup();
            _sequenceGroups.push(seqGroup);
            return seqGroup;
        }
    }
}

