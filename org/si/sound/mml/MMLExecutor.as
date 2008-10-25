//----------------------------------------------------------------------------------------------------
// MML Sequence executor class
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------




package org.si.sound.mml {
    import flash.utils.ByteArray;
    import org.si.utils.SLLint;
    
    
    /** MMLExecutor holds a chain of MMLEvents and processing pointer. */
    public class MMLExecutor
    {
    // valiables
    //--------------------------------------------------
        /** MMLSequence to execute. */
        public var sequence:MMLSequence;
        /** Current MMLEvent to process */
        public var pointer:MMLEvent;
        /** Repeating count */
        public var repeatCount:int;
        
        // Repeating point
        private  var _repeatPoint:MMLEvent;
        // event to process
        private  var _processEvent:MMLEvent;
        /** @private [internal use] the stac of counters to operate repeatings. refer from MMLSequencer. */
        internal var _repeatCounter:SLLint;
        /** @private [internal use] the leftover of processing sample count. refer from MMLSequencer. */
        internal var _residueSampleCount:int;
        /** @private [internal use] the decimal fraction part of processing sample count. */
        internal var _decimalFractionSampleCount:int;
        
        
        
        
    // constructor
    //--------------------------------------------------
        /** Constructor. */
        function MMLExecutor()
        {
            sequence = null;
            pointer = null;
            repeatCount = 0;
            _repeatPoint = null;
            _processEvent = MMLParser._allocEvent(MMLEvent.PROCESS, 0);
            _repeatCounter = null;
            _residueSampleCount = 0;
            _decimalFractionSampleCount = 0;
        }
        
        
        
        
    // operations
    //--------------------------------------------------
        /** Initialize.
         *  @param seq Sequence to execute.
         */
        public function initialize(seq:MMLSequence) : void
        {
            clear();
            if (seq) {
                sequence = seq;
                pointer  = seq.headEvent.next;
            }
        }
        
        
        /** Clear contents. */
        public function clear() : void
        {
            sequence = null;
            pointer = null;
            repeatCount = 0;
            _repeatPoint = null;
            SLLint.freeList(_repeatCounter);
            _repeatCounter = null;
            _residueSampleCount = 0;
            _decimalFractionSampleCount = 0;
        }
        
        
        /** Publish processing event. Returns this function's return value in the event handler of NOTE and REST.
         *  @param e Current event
         */
        public function publishProessingEvent(e:MMLEvent) : MMLEvent
        {
            if (e.length > 0) {
                //_processEvent.data   = 0;
                //_processEvent.next   = null;
                _processEvent.length = e.length;
                _processEvent.jump   = e;
                return _processEvent;
            }
            return e.next;
        }
        
        
        
        
    // callback
    //--------------------------------------------------
        /** @private [internal use] callback onTempoChanged. */
        public function _onTempoChanged(changingRatio:Number) : void
        {
            _processEvent.length *= changingRatio;
        }
        
        
        /** @private [internal use] callback onRepeatAll. */
        internal function _onRepeatAll(e:MMLEvent) : MMLEvent
        {
            _repeatPoint = e.next;
            return e.next;
        }
        
        
        /** @private [internal use] callback onRepeatBegin. */
        internal function _onRepeatBegin(e:MMLEvent) : MMLEvent
        {
            var counter:SLLint = SLLint.alloc(e.data);
            counter.next = _repeatCounter;
            _repeatCounter = counter;
            return e.next;
        }
        
        
        /** @private [internal use] callback onRepeatBreak. */
        internal function _onRepeatBreak(e:MMLEvent) : MMLEvent
        {
            if (_repeatCounter.i == 1) {
                var counter:SLLint = _repeatCounter.next;
                SLLint.free(_repeatCounter);
                _repeatCounter = counter;
                // Jump to repeatStart.repeatEnd.next
                return e.jump.jump.next;
            }
            return e.next;
        }
        
        
        /** @private [internal use] callback onRepeatEnd. */
        internal function _onRepeatEnd(e:MMLEvent) : MMLEvent
        {
           if (--_repeatCounter.i == 0) {
                var counter:SLLint = _repeatCounter.next;
                SLLint.free(_repeatCounter);
                _repeatCounter = counter;
                return e.next;
            }
            // Jump to repeatStart.next
            return e.jump.next;
         }
        
        
        /** @private [internal use] callback onSequenceTail. */
        internal function _onSequenceTail(e:MMLEvent) : MMLEvent
        {
            repeatCount++;
            return _repeatPoint;
         }
    }
}


