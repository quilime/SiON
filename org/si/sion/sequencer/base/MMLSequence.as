//----------------------------------------------------------------------------------------------------
// MML Sequence class
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.sequencer.base {
    import flash.utils.ByteArray;
    
    
    /** Sequence of 1 sound channel. MMLData > MMLSequenceGroup > MMLSequence > MMLEvent (">" meanse "has a"). */
    public class MMLSequence
    {
    // valiables
    //--------------------------------------------------
        /** First MMLEvent. The ID is always MMLEvent.SEQUENCE_HEAD. */
        public var headEvent:MMLEvent;
        /** Last MMLEvent. The ID is always MMLEvent.SEQUENCE_TAIL and lastEvent.next is always null. */
        public var tailEvent:MMLEvent;
        /** MML String */
        public var mmlString:String;
        
        // Previous sequence in the chain.
        private var _prevSequence:MMLSequence;
        // Next sequence in the chain.
        private var _nextSequence:MMLSequence;
        // Is terminal sequence.
        private var _isTerminal:Boolean;
        
        /** @private [internal use] owner data */
        public var _owner:MMLData;
        
        
        
    // properties
    //--------------------------------------------------
        /** next sequence. */
        public function get nextSequence() : MMLSequence
        {
            return (!_nextSequence._isTerminal) ? _nextSequence : null;
        }
        
        
        
        
    // constructor
    //--------------------------------------------------
        /** Constructor. */
        function MMLSequence(term:Boolean = false)
        {
            _owner = null;
            headEvent = null;
            tailEvent = null;
            mmlString = "";
            _prevSequence = (term) ? this : null;
            _nextSequence = (term) ? this : null;
            _isTerminal = term;
        }
        
        
        /** toString returns the event ids. */
        public function toString() : String
        {
            if (_isTerminal) return "terminator";
            var e:MMLEvent = headEvent.next;
            var str:String = "";
            for (var i:int=0; i<32; i++) {
                str += String(e.id) + " ";
                e = e.next;
                if (e == null) break;
            }
            return str;
        }
        
        
        /** Returns events as an Vector.<MMLEvent>. 
         *  @param lengthLimit maximum length of returning Vector. When this argument set to 0, the Vector includes all events.
         *  @param offset starting index of returning Vector.
         *  @param eventID event id to get. When this argument set to -1, the Vector includes all kind of events.
         */
        public function toVector(lengthLimit:int=0, offset:int=0, eventID:int=-1) : Vector.<MMLEvent>
        {
            if (headEvent == null) return null;
            var e:MMLEvent, i:int=0, result:Vector.<MMLEvent> = new Vector.<MMLEvent>();
            for (e=headEvent.next; e!=null && e.id!=MMLEvent.SEQUENCE_TAIL; e=e.next) {
                if (eventID == -1 || eventID == e.id) {
                    if (i >= offset) result.push(e);
                    if (lengthLimit > 0 && i >= lengthLimit) break;
                    i++;
                }
            }
            return result;
        }
        
        
        /** Create sequence from Vector.<MMLEvent>. 
         *  @param events event list of the sequence.
         */
        public function fromVector(events:Vector.<MMLEvent>) : MMLSequence
        {
            alloc();
            for each (var e:MMLEvent in events) connectEvent(e);
            return this;
        }
        
        
        
        
        
    // operations
    //--------------------------------------------------
        /** Alloc. */
        public function alloc() : MMLSequence
        {
            if (!isEmpty()) {
                headEvent.jump.next = tailEvent;
                MMLParser._freeAllEvents(this);
            }
            headEvent = MMLParser._allocEvent(MMLEvent.SEQUENCE_HEAD, 0);
            tailEvent = MMLParser._allocEvent(MMLEvent.SEQUENCE_TAIL, 0);
            headEvent.next = tailEvent;
            headEvent.jump = headEvent;
            return this;
        }
        
        
        /** Free. */
        public function free() : void
        {
            if (headEvent) {
                // disconnect
                headEvent.jump.next = tailEvent;
                MMLParser._freeAllEvents(this);
                _prevSequence = null;
                _nextSequence = null;
            } else 
            if (_isTerminal) {
                _prevSequence = this;
                _nextSequence = this;
            }
            mmlString = "";
        }
        
        
        /** is empty ? */
        public function isEmpty() : Boolean
        {
            return (headEvent == null);
        }
        
        
        /** Pack to ByteArray. */
        public function pack(seq:ByteArray) : void
        {
            // not available
        }
        
        
        /** Unpack from ByteArray. */
        public function unpack(seq:ByteArray) : void
        {
            // not available
        }
        
        
        /** Append new MMLEvent at tail */
        public function appendNewEvent(id:int, data:int, length:int=0) : MMLEvent
        {
            var e:MMLEvent = MMLParser._allocEvent(id, data, length);
            connectEvent(e);
            return e;
        }
        
        
        /** Prepend new MMLEvent at head */
        public function prependNewEvent(id:int, data:int, length:int=0) : MMLEvent
        {
            var e:MMLEvent = MMLParser._allocEvent(id, data, length);
            e.next = headEvent;
            headEvent.next = e;
            if (headEvent.jump == headEvent) headEvent.jump = e;
            return e;
        }
        
        
        /** connect MMLEvent */
        public function connectEvent(e:MMLEvent) : MMLSequence
        {
            // connect event at tail
            headEvent.jump.next = e;
            e.next = tailEvent;
            headEvent.jump = e;
            return this;
        }
        
        
        /** connect 2 sequences */
        public function connectBefore(e:MMLEvent) : MMLSequence
        {
            // headEvent.jump is last event
            headEvent.jump.next = e;
            return this;
        }
        
        
        /** is system command */
        public function isSystemCommand() : Boolean
        {
            return (headEvent.next.id == MMLEvent.SYSTEM_EVENT);
        }
        
        
        /** get system command */
        public function getSystemCommand() : String
        {
            return MMLParser._getSystemEventString(headEvent.next);
        }
        
        
        /** @private [internal use] cutout MMLSequence */
        public function _cutout(head:MMLEvent) : MMLEvent
        {
            var last:MMLEvent = head.jump; // last event of this sequence
            var next:MMLEvent = last.next; // head of next sequence

            // cut out
            headEvent = head;
            tailEvent = MMLParser._allocEvent(MMLEvent.SEQUENCE_TAIL, 0);
            last.next = tailEvent;  // append tailEvent at last
            
            return next;
        }
        
        
        /** @private [internal use] update mml string */
        internal function _updateMMLString() : void
        {
            if (headEvent.next.id == MMLEvent.DEBUG_INFO) {
                mmlString = MMLParser._getSequenceMML(headEvent.next);
                headEvent.length = 0;
            }
        }
        
        
        /** @private [internal use] insert before */
        internal function _insertBefore(next:MMLSequence) : void
        {
            _prevSequence = next._prevSequence;
            _nextSequence = next;
            _prevSequence._nextSequence = this;
            _nextSequence._prevSequence = this;
        }
        
        
        /** @private [internal use] insert after */
        internal function _insertAfter(prev:MMLSequence) : void
        {
            _prevSequence = prev;
            _nextSequence = prev._nextSequence;
            _prevSequence._nextSequence = this;
            _nextSequence._prevSequence = this;
        }
        
        
        /** remove from chain. @return previous sequence. */
        public function removeFromChain() : MMLSequence
        {
            var ret:MMLSequence = _prevSequence;
            _prevSequence._nextSequence = _nextSequence;
            _nextSequence._prevSequence = _prevSequence;
            _prevSequence = null;
            _nextSequence = null;
            return (ret === this) ? null : ret;
        }
    }
}


