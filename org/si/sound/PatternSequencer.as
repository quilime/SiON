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
    import org.si.sound.patterns.Note;
    import org.si.sound.synthesizers._synthesizer_internal;
    
    
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
        /** voice list refered by Note.voiceIndex. @see org.si.sound.Note.voiceIndex */
        public var voiceList:Array;
        
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
        
        /** default pattern, this pattern is used when notes or velocities propertiy is called */
        protected var _defaultPattern:Vector.<Note>;
        
        
        
        
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
        
        
        /** curent note */
        override public function get note() : int {
            if (_currentNote==null || _currentNote.note<0) return _note;
            return _currentNote.note;
        }
        override public function set note(n:int) : void {
            _note = n;
        }
        
        
        /** curent note's velocity. */
        public function get velocity() : int {
            if (_currentNote == null) return 0;
            if (_currentNote.velocity<0) return _velocity;
            return _currentNote.velocity;
        }
        public function set velocity(v:int) : void {
            _velocity = v;
        }
        
        
        /** Array of sequence's notes. */
        public function set notes(list:Array) : void {
            var i:int, pi:int, li:int;
            if (pattern && pattern !== _defaultPattern) {
                for (i=0; i<16; i++) {
                    pi = i % pattern.length;
                    _defaultPattern[i].copyFrom(pattern[pi]);
                }
            }
            for (i=0; i<16; i++) {
                li = i % list.length;
                _defaultPattern[i].note = list[li];
            }
            pattern = _defaultPattern;
        }
        
        
        /** Array of sequence's velocities */
        public function set velocities(list:Array) : void {
            var i:int, pi:int, li:int;
            if (pattern && pattern !== _defaultPattern) {
                for (i=0; i<16; i++) {
                    pi = i % pattern.length;
                    _defaultPattern[i].copyFrom(pattern[pi]);
                }
            }
            for (i=0; i<16; i++) {
                li = i % list.length;
                _defaultPattern[i].velocity = list[li];
            }
            pattern = _defaultPattern;
        }
        
        
        /** Array of sequence's voice indicies */
        public function set voiceIndicies(list:Array) : void {
            var i:int, pi:int, li:int;
            if (pattern && pattern !== _defaultPattern) {
                for (i=0; i<16; i++) {
                    pi = i % pattern.length;
                    _defaultPattern[i].copyFrom(pattern[pi]);
                }
            }
            for (i=0; i<16; i++) {
                li = i % list.length;
                _defaultPattern[i].voiceIndex = list[li];
            }
            pattern = _defaultPattern;
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
            voiceList = null;
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

            _defaultPattern = new Vector.<Note>(16);
            for (var i:int=0; i<16; i++) _defaultPattern[i] = new Note();
            
            this.division = division;
            _onEnterSegument();
        }
        
        
        
        
    // operations
    //----------------------------------------
        /** Play sound. */
        override public function play() : void
        {
            stop();
            _frameCount = 0;
            if (pattern && pattern.length>0) {
                var list:Vector.<SiMMLTrack> = _sequenceOn(_data, false, false);
                if (list.length >= 1) {
                    _track = list[0];
                    _track.setPortament(_portament);
                    _pointer = 0;
                    _currentNote = pattern[0];
                    _synthesizer._registerTrack(_track);
                }
            }
        }
        
        
        /** Stop sound. */
        override public function stop() : void
        {
            if (_track) {
                _synthesizer._unregisterTracks(_track);
                _track.setDisposable();
                _track = null;
                _sequenceOff(false);
            }
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
                var vel:int = velocity;
                if (vel > 0) {
                    var sampleLength:int = driver.sequencer.calcSampleLength(length);
                    if (onNoteOn != null) onNoteOn();
                    // voice change
                    if (voiceList && _currentNote.voiceIndex >= 0) {
                        voice = voiceList[_currentNote.voiceIndex];
                    }
                    if (_synthesizer._synthesizer_internal::_requireVoiceUpdate) {
                        _synthesizer._synthesizer_internal::_voice.setTrackVoice(_track);
                        _synthesizer._synthesizer_internal::_requireVoiceUpdate = false;
                    } 
                    _track.velocity = vel;
                    _track.setNote(note, sampleLength, (_portament>0));
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

