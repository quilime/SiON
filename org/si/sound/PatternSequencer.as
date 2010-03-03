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
    import org.si.sound.synthesizer._synthesizer_internal;
    
    
    /** Pattern sequencer */
    public class PatternSequencer extends SoundObject
    {
    // variables
    //----------------------------------------
        /** callback on first beat of every seguments */
        public var onEnterSegument:Function = null;
        /** callback on every notes */
        public var onNoteOn:Function = null;
        /** note pattern */
        public var pattern:Vector.<Note>;
        
        /** portament */
        protected var _portament:int;
        /** Sequence data. */
        protected var _data:SiONData;
        /** Sequence for interruption. */
        protected var _sequence:MMLSequence;
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
        override public function get note() : int {
            if (_currentNote==null || _currentNote.note==-1) return _note;
            return _currentNote.note;
        }
        override public function set note(n:int) : void {
            _note = n;
        }
        
        
        /** velocity. */
        public function get velocity() : int {
            if (_currentNote==null || _currentNote.velocity==-1) return _velocity;
            return _currentNote.velocity;
        }
        public function set velocity(v:int) : void {
            _velocity = v;
        }
        
        
        /** length in 16th beat counts. */
        override public function get length() : Number {
            if (_currentNote==null || isNaN(_currentNote.length)) return _length;
            return _currentNote.length;
        }
        override public function set length(l:Number) : void {
            _length = l;
        }
        
        
        /** Frame counter */
        public function get frameCount() : int { return _frameCount; }
        
        
        
        
    // constructor
    //----------------------------------------
        /** constructor 
         *  @param frameStep sequence step in beat number, 16 sets stepped in every 16th beats.
         */
        function PatternSequencer(division:int=16, defaultNote:int=60, defaultVelocity:int=128, defaultLength:Number=0)
        {
            super("Pattern sequencer");
            pattern = null;
            onEnterSegument = null;
            _data = new SiONData();
            
            _data.clear();
            _sequence = _data.appendNewSequence();
            _sequence.initialize();
            _sequence.appendNewEvent(MMLEvent.REPEAT_ALL, 0);
            _sequence.appendNewCallback(_onBeat, 0);
            _restEvent = _sequence.appendNewEvent(MMLEvent.REST, 0, 0);
            
            _pointer = 0;
            _frameCount = 0;
            _note     = defaultNote;
            _velocity = defaultVelocity;
            _length   = defaultLength;
            _currentNote = null;
            quantize = 16;
            
            this.division = division;
            _onEnterSegument();
        }
        
        
        
        
    // operations
    //----------------------------------------
        /** Play sound. */
        override public function play() : void
        {
            _frameCount = 0;
            var list:Vector.<SiMMLTrack> = _sequenceOn(_data, false, false);
            if (list.length >= 1) {
                _track = list[0];
                _track.setPortament(_portament);
                _pointer = 0;
                _currentNote = pattern[0];
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
        private function _onBeat(trackNumber:int) : MMLEvent
        {
            if (_frameCount == 0) _onEnterSegument();
            if (pattern && pattern.length>0) {
                if (_pointer >= pattern.length) _pointer = 0;
                _currentNote = pattern[_pointer];
                if (_currentNote && _currentNote.velocity > 0) {
                    var sampleLength:int = driver.sequencer.calcSampleLength(length);
                    _track.setNote(note, sampleLength, (_portament>0));
                    _track.velocity = velocity;
                    if (onNoteOn != null) onNoteOn();
                    if (_synthesizer._synthesizer_internal::_requireVoiceUpdate) {
                        _synthesizer.setTrackVoice(_track);
                    }
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

