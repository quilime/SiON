//----------------------------------------------------------------------------------------------------
// Sequencer class
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound.patterns {
    import org.si.sion.*;
    import org.si.sion.sequencer.base.*;
    import org.si.sion.sequencer.SiMMLTrack;
    import org.si.sound.SoundObject;
    import org.si.sound.namespaces._sound_object_internal;
    import org.si.sound.synthesizers._synthesizer_internal;
    
    
    /** The Sequencer class provides simple one track pattern player. */
    public class Sequencer
    {
    // namespace
    //----------------------------------------
        use namespace _sound_object_internal;
        
        
        
        
    // variables
    //----------------------------------------
        /** pattern note vector to play */
        public var pattern:Vector.<Note>;
        /** voice list referenced by Note.voiceIndex. @see org.si.sound.Note.voiceIndex */
        public var voiceList:Array;
        

        /** @private [internal use] callback on every notes without any arguments. function() : void */
        _sound_object_internal var onEnterFrame:Function = null;
        /** @private [internal use] callback on first beat of every segments without any arguments. function() : void */
        _sound_object_internal var onEnterSegment:Function = null;
        /** @private [internal use] Sequence data. */
        _sound_object_internal var data:SiONData;
        /** @private [internal use] Frame count in one segment */
        _sound_object_internal var segmentFrameCount:int;
        /** @private [internal use] Grid step in ticks */
        _sound_object_internal var gridStep:int;
        /** @private [internal use] portament */
        _sound_object_internal var portament:int;
        
        /** @private owner of this pattern sequencer */
        protected var _owner:SoundObject;
        /** @private controlled track */
        protected var _track:SiMMLTrack;
        /** @private MMLEvent.REST. */
        protected var _restEvent:MMLEvent;
        /** @private check number of synthsizer update */
        protected var _synthesizer_updateNumber:int;
        
        /** @private Frame counter */
        protected var _frameCounter:int;
        /** @private playing pointer on the pattern */
        protected var _sequencePointer:int;
        /** @private initial value of _sequencePointer */
        protected var _initialSequencePointer:int;
        
        /** @private Default note */
        protected var _defaultNote:int;
        /** @private Default velocity */
        protected var _defaultVelocity:int;
        /** @private Default note */
        protected var _defaultLength:int;
        /** @private Current note */
        protected var _currentNote:Note;
        /** @private Grid shift vectors */
        protected var _currentGridShift:int;
        
        /** @private Grid shift pattern */
        protected var _gridShiftPattern:Vector.<int>;
        
        
        
        
    // properties
    //----------------------------------------
        /** current frame count */
        public function get frameCount() : int { return _frameCounter; }
        
        
        /** sequence pointer */
        public function get sequencePointer() : int { return _sequencePointer; }
        public function set sequencePointer(p:int) : void {
            if (_track) {
                _sequencePointer = p;
                _frameCounter = p % segmentFrameCount;
            } else {
                _initialSequencePointer = p;
            }
        }
        
        
        /** curent note */
        public function get note() : int {
            if (_currentNote == null || _currentNote.note < 0) return _defaultNote;
            return _currentNote.note;
        }
        
        
        /** curent note's velocity (minimum:0 - maximum:255, the value over 128 makes distotion). */
        public function get velocity() : int {
            if (_currentNote == null) return 0;
            if (_currentNote.velocity < 0) return _defaultVelocity;
            return _currentNote.velocity;
        }
        
        
        /** curent note's length in 16th beat counts. */
        public function get length() : Number {
            if (_currentNote == null || isNaN(_currentNote.length)) return _defaultLength;
            return _currentNote.length;
        }
        
        
        /** default note, this value is refered when the Note's note property is under 0 (ussualy -1). */
        public function get defaultNote() : int { return _defaultNote; }
        public function set defaultNote(n:int) : void { _defaultNote = (n < 0) ? 0 : (n > 127) ? 127 : n; }
        
        
        /** default velocity (minimum:0 - maximum:255, the value over 128 makes distotion), this value is refered when the Note's velocity property is under 0 (ussualy -1). */
        public function get defaultVelocity() : int { return _defaultVelocity; }
        public function set defaultVelocity(v:int) : void { _defaultVelocity = (v < 0) ? 0 : (v > 255) ? 255 : v; }
        
        
        /** default length, this value is refered when the Note's length property is Number.NaN. */
        public function get defaultLength() : Number { return _defaultLength; }
        public function set defaultLength(l:Number) : void { _defaultLength = (l < 0) ? 0 : l; }
        
        
        
        
    // constructor
    //----------------------------------------
        /** @private constructor. you should not create new PatternSequencer in your own codes. */
        function Sequencer(owner:SoundObject, defaultNote:int=60, defaultVelocity:int=128, defaultLength:Number=0, gridShiftPattern:Vector.<int>=null)
        {
            _owner = owner;
            pattern = null;
            voiceList = null;
            onEnterSegment = null;
            onEnterFrame = null;
            
            // initialize
            segmentFrameCount = 16;    // 16 count in one segment
            gridStep = 120;            // 16th beat (1920/16)
            portament = 0;
            _frameCounter = 0;
            _sequencePointer = 0;
            _initialSequencePointer = 0;
            _defaultNote     = defaultNote;
            _defaultVelocity = defaultVelocity;
            _defaultLength   = defaultLength;
            _currentNote = null;
            _currentGridShift = 0;
            _gridShiftPattern = gridShiftPattern;

            // create internal sequence
            var seq:MMLSequence;
            data = new SiONData();
            data.clear();
            seq = data.appendNewSequence();
            seq.initialize();
            seq.appendNewEvent(MMLEvent.REPEAT_ALL, 0);
            seq.appendNewCallback(_onEnterFrame, 0);
            _restEvent = seq.appendNewEvent(MMLEvent.REST, 0, gridStep);
        }
        
        
        
        
    // operations
    //----------------------------------------
        /** @private [internal use] */
        _sound_object_internal function play(track:SiMMLTrack) : SiMMLTrack
        {
            _synthesizer_updateNumber = _owner.synthesizer._synthesizer_internal::_voiceUpdateNumber;
            _track = null;
            _sequencePointer = _initialSequencePointer;
            _frameCounter = _initialSequencePointer % segmentFrameCount;
            if (pattern && pattern.length>0) {
                _track = track;
                _track.setPortament(portament);
                _currentNote = pattern[0];
                _currentGridShift = 0;
            }
            return track;
        }
        
        
        /** @private [internal use] */
        _sound_object_internal function stop() : void
        {
            _track = null;
            _sequencePointer = 0;
            _frameCounter = 0;
        }
        
        
        /** @private [internal use] set portament */
        _sound_object_internal function setPortament(p:int) : int
        {
            portament = p;
            if (portament < 0) portament = 0;
            if (_track) _track.setPortament(portament);
            return portament;
        }
        
        
        
        
    // internal
    //----------------------------------------
        /** @private internal callback on every beat */
        protected function _onEnterFrame(trackNumber:int) : MMLEvent
        {
            var vel:int, patternLength:int;
            
            // segment oprations
            if (_frameCounter == 0) _onEnterSegment();

            // callback on enter frame
            if (onEnterFrame != null) onEnterFrame();
            
            // pattern sequencer
            patternLength = (pattern) ? pattern.length : 0;
            if (patternLength > 0) {
                // get current Note from pattern
                if (_sequencePointer >= patternLength) _sequencePointer %= patternLength;
                _currentNote = pattern[_sequencePointer];
                
                // get current velocity, note on when velocity > 0
                vel = velocity;
                if (vel > 0) {
                    // change voice
                    if (voiceList && _currentNote && _currentNote.voiceIndex >= 0) {
                        _owner.voice = voiceList[_currentNote.voiceIndex];
                    }
                    // update owners track voice when synthesizer is updated
                    if (_synthesizer_updateNumber != _owner.synthesizer._synthesizer_internal::_voiceUpdateNumber) {
                        _owner.synthesizer._synthesizer_internal::_voice.setTrackVoice(_track);
                        _synthesizer_updateNumber = _owner.synthesizer._synthesizer_internal::_voiceUpdateNumber;
                    } 
                    
                    // change track velocity
                    _track.velocity = vel;
                    
                    // note on
                    _track.setNote(note, SiONDriver.mutex.sequencer.calcSampleLength(length), (portament>0));
                }
                
                // set length of rest event 
                if (_gridShiftPattern != null) {
                    var diff:int = _gridShiftPattern[_frameCounter] - _currentGridShift;
                    _restEvent.length = gridStep + diff;
                    _currentGridShift += diff;
                }
                
                // increment pointer
                _sequencePointer++;
            }

            // increment frame counter
            if (++_frameCounter == segmentFrameCount) _frameCounter = 0;
            
            return null;
        }
        
        
        /** @private internal callback on first beat of every segments */
        protected function _onEnterSegment() : void
        {
            // callback on enter segment
            if (onEnterSegment != null) onEnterSegment();
        }
    }
}

