//----------------------------------------------------------------------------------------------------
// Pattern sequencer class
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound {
    import org.si.sion.*;
    import org.si.sion.sequencer.base.*;
    import org.si.sion.sequencer.SiMMLTrack;
    import org.si.sound.base.*;
    
    
    /** Pattern sequencer */
    public class PatternSequencer extends SoundObject
    {
    // variables
    //----------------------------------------
        /** callback on first beat of every seguments */
        public var onEnterSegument:Function = null;
        /** note pattern */
        public var pattern:Vector.<Note>;
        
        
        /** portament */
        protected var _portament:int;
        /** Sequence data. */
        protected var _data:SiONData;
        /** Sequence for interruption. */
        protected var _sequence:MMLSequence;
        /** MMLEvent.INTERNAL_CALL. */
        protected var _interruptEvent:MMLEvent;
        /** MMLEvent.REST. */
        protected var _restEvent:MMLEvent;
        /** division */
        protected var _division:int;
        /** division of nest segument */
        protected var _nextSegumentDivision:int;
        /** Frame counter */
        protected var _frameCount:int;
        /** playing pointer in pattern */
        protected var _pointer:int;
        /** Default velocity */
        protected var _velocity:int;
        /** Current note */
        protected var _currentNote:Note;
        
        
        
        
    // properties
    //----------------------------------------
        /** portament */
        public function get portament() : int { return _portament; }
        public function set portament(p:int) : void {
            _portament = p;
            if (_portament < 0) _portament = 0;
            if (_track) _track.setPortament(_portament);
        }
        
        
        /** beat division */
        public function get division() : int { return _division; }
        public function set division(div:int) : void { _nextSegumentDivision = div; }
        
        
        /** note. */
        override public function set note(n:int) : void {
            _note = n;
        }
        override public function get note() : int {
            if (_currentNote==null || _currentNote.note==-1) return _note;
            return _currentNote.note;
        }
        
        
        /** velocity. */
        public function set velocity(v:int) : void {
            _velocity = v;
        }
        public function get velocity() : int {
            if (_currentNote==null || _currentNote.velocity==0) return _velocity;
            return _currentNote.velocity;
        }
        
        
        /** length in 16th beat counts. */
        override public function set length(l:Number) : void {
            _length = l;
        }
        override public function get length() : Number {
            if (_currentNote==null || _currentNote.tickLength==0) return _length;
            return _currentNote.tickLength / 120;
        }
        
        
        /** Frame counter */
        public function get frameCount() : int { return _frameCount; }
        
        
        
        
    // constructor
    //----------------------------------------
        /** constructor 
         *  @param frameStep sequence step in beat number, 16 sets stepped in every 16th beats.
         */
        function PatternSequencer(division:int=16)
        {
            super("Pattern sequencer");
            var len:int = 1920/division;
            pattern = null;
            _pointer = 0;
            _data = new SiONData();
            _sequence = _data.appendNewSequence().initialize();
            _sequence.appendNewEvent(MMLEvent.REPEAT_ALL, 0);
            _interruptEvent = _sequence.appendNewCallback(_onBeat, 0);
            _restEvent      = _sequence.appendNewEvent(MMLEvent.REST, 0, len);
            _division = division;
            _nextSegumentDivision = division;
            _frameCount = 0;
            _velocity = 128;
            _currentNote = null;
        }
        
        
        
        
    // operations
    //----------------------------------------
        /** Play sound. */
        override public function play() : void
        {
            _frameCount = 0;
            var list:Vector.<SiMMLTrack> = _sequenceOn(_data, false);
            if (list.length >= 1) {
                _track = list[0];
                _track.setPortament(_portament);
                _pointer = 0;
                _currentNote = (pattern && pattern.length>0) ? pattern[0] : null;
            }
        }
        
        
        /** Stop sound. */
        override public function stop() : void
        {
            if (_track) {
                _track.setDisposable();
                _track = null;
            }
            _sequenceOff(false);
        }
        
        
        
        
    // internal
    //----------------------------------------
        // callback on every beat
        private function _onBeat(data:int) : MMLEvent
        {
            if (_frameCount == 0) _onEnterSegument();
            if (pattern && pattern.length>0) {
                if (_pointer >= pattern.length) _pointer = 0;
                _currentNote = pattern[_pointer];
                if (_currentNote && _currentNote.note != -2) {
                    _track.setNote(note, driver.sequencer.calcSampleLength(length), (_portament>0));
                    _track.velocity = velocity;
                }
                _pointer++;
            }
            if (++_frameCount == _division) _frameCount = 0;
            return null;
        }
        
        
        // callback on first beat of every seguments
        private function _onEnterSegument() : void
        {
            if (onEnterSegument != null) onEnterSegument();
            if (_nextSegumentDivision != _division) {
                _division = _nextSegumentDivision;
                _restEvent.length = 1920/_division;
            }
        }
    }
}

