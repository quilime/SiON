//----------------------------------------------------------------------------------------------------
// MML Sequence group class
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------




package org.si.sound.mml {
    import flash.utils.ByteArray;
    
    
    
    
    /** Group of MMLSequences. MMLData > MMLSequenceGroup > MMLSequence > MMLEvent (">" meanse "has a"). */
    public class MMLSequenceGroup
    {
    // valiables
    //--------------------------------------------------
       // terminator
        private var _term:MMLSequence;
        
        
        
        
    // properties
    //--------------------------------------------------
        public function get sequenceCount() : int
        {
            return _sequences.length;
        }
        
        
        public function get headSequence() : MMLSequence
        {
            return _term.nextSequence;
        }
        
        
        
        
    // constructor
    //--------------------------------------------------
        function MMLSequenceGroup()
        {
            _sequences = [];
            _term = new MMLSequence(true);
        }
        
        
        
        
    // operation
    //--------------------------------------------------
        /** Create new sequence group. Why its not create() ???
         *  @param headEvent MMLEvnet returned from MMLParser.parse().
         */
        public function alloc(headEvent:MMLEvent) : void
        {
            // divied into sequences
            var seq:MMLSequence;
            while (headEvent!=null && headEvent.jump!=null) {
                if (headEvent.id != MMLEvent.SEQUENCE_HEAD) {
                    throw new Error("MMLSequence: Unknown error on dividing sequences. " + headEvent);
                }
                seq = addTail(newSequence());       // push new sequence
                headEvent = seq._cutout(headEvent); // cutout sequence
                seq._updateMMLString();             // update mml string
            }
        }
        
        
        /** Free all sequences */
        public function free() : void
        {
            for each (var seq:MMLSequence in _sequences) {
                seq.free();
                _freeList.push(seq);
            }
            _sequences.length = 0;
            _term.free();
        }
        
        
        
        
    // factory
    //--------------------------------------------------
        // allocated sequences
        private var _sequences:Array;
        // free list
        static private var _freeList:Array = [];
        
        
        /** Allocate new sequence and push sequence chain. */
        public function newSequence() : MMLSequence
        {
            var seq:MMLSequence = _freeList.pop() || new MMLSequence();
            _sequences.push(seq);
            return seq;
        }
        
        
        /** push sequence */
        public function addTail(seq:MMLSequence) : MMLSequence
        {
            seq._insertBefore(_term);
            return seq;
        }
    }
}