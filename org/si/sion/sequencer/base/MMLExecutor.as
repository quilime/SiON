//----------------------------------------------------------------------------------------------------
// MML Sequence executor class
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.sequencer.base {
    import flash.utils.ByteArray;
    import org.si.utils.SLLint;
    
    
    /** MMLExecutor has MMLSequence and executing pointer. One track has one executor, and sequencer also has one for global sequence. */
    public class MMLExecutor
    {
    // valiables
    //--------------------------------------------------
        /** Current MMLEvent to process */
        public var pointer:MMLEvent;
        
        // MMLSequence to execute.
        private var _sequence:MMLSequence;
        // Repeating count by segno
        private var _endRepeatCounter:int;
        // Repeating point
        private  var _repeatPoint:MMLEvent;
        // event to process
        private  var _processEvent:MMLEvent;
        // rest event
        private  var _restEvent:MMLEvent;
        // note event
        private  var _noteEvent:MMLEvent;
        
        /** @private [internal use] the stac of counters to operate repeatings. refer from MMLSequencer. */
        internal var _repeatCounter:SLLint;
        /** @private [internal use] the leftover of processing sample count. refer from MMLSequencer. */
        internal var _residueSampleCount:int;
        /** @private [internal use] the decimal fraction part of processing sample count. */
        internal var _decimalFractionSampleCount:int;
        
        
        
        
    // properties
    //--------------------------------------------------
        /** Repeating count by segno */
        public function get endRepeatCount() : int { return _endRepeatCounter; }
        
        
        
        
    // constructor
    //--------------------------------------------------
        /** Constructor. */
        function MMLExecutor()
        {
            _sequence = null;
            pointer = null;
            _endRepeatCounter = 0;
            _repeatPoint = null;
            _processEvent = MMLParser._allocEvent(MMLEvent.PROCESS, 0);
            _restEvent = MMLParser._allocEvent(MMLEvent.REST, 0);
            _noteEvent = MMLParser._allocEvent(MMLEvent.NOTE, 0);
            _repeatCounter = null;
            _residueSampleCount = 0;
            _decimalFractionSampleCount = 0;
        }
        
        
        
        
    // operations
    //--------------------------------------------------
        /** Initialize.
         *  @param seq Sequence to execute. If its null, set the execution pointer at the head.
         */
        public function initialize(seq:MMLSequence) : void
        {
            clear();
            if (seq) {
                _sequence = seq;
                pointer  = seq.headEvent.next;
            }
        }
        
        
        /** Clear contents. */
        public function clear() : void
        {
            _sequence = null;
            pointer = null;
            _endRepeatCounter = 0;
            _repeatPoint = null;
            SLLint.freeList(_repeatCounter);
            _repeatCounter = null;
            _residueSampleCount = 0;
            _decimalFractionSampleCount = 0;
        }
        
        
        /** Reset pointer to sequence head */
        public function resetPointer() : void
        {
            if (_sequence) pointer = _sequence.headEvent.next;
        }
        
        
        /** stop execute sequence */
        public function stop() : void
        {
            if (pointer) {
                if (pointer === _processEvent) _processEvent.jump = MMLEvent.nopEvent;
                else pointer = null;
            }
        }
        
        
        /** Publish processing event. You should return this function's return in the event handler of NOTE and REST.
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
        
        
        /** Publish delayed event. This returns PROCESS MMLEvent when delay>0.
         *  @param e MMLEvent after delay.
         *  @param delay Delay time (in sample count).
         */
        public function publishDelayedEvent(e:MMLEvent, delay:int=0) : MMLEvent
        {
            _restEvent.next = e;
            _restEvent.length = delay;
            return publishProessingEvent(_restEvent);
        }
        
        
        /** Publish note event with delay. This returns PROCESS MMLEvent when delay>0.
         *  @param note Note number.
         *  @param length Length in sample count. The argument of 0 sets no key off.
         *  @param delay Delay time (in sample count).
         */
        public function publishNoteEvent(note:int, length:int, delay:int=0) : MMLEvent
        {
            _noteEvent.data = note;
            _noteEvent.length = length;
            return publishDelayedEvent(_noteEvent, delay);
        }
        
        
        
        
    // callback
    //--------------------------------------------------
        /** @private [internal use] callback onTempoChanged. */
        public function _onTempoChanged(changingRatio:Number) : void
        {
            _residueSampleCount         *= changingRatio;
            _decimalFractionSampleCount *= changingRatio;
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
            _endRepeatCounter++;
            return _repeatPoint;
         }
    }
}


