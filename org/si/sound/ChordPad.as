//----------------------------------------------------------------------------------------------------
// Polyphonic chord pad synthesizer
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound {
    import org.si.sion.SiONData;
    import org.si.sion.sequencer.SiMMLTrack;
    import org.si.sion.utils.Chord;
    import org.si.sound.patterns.Note;
    import org.si.sound.patterns.Sequencer;
    import org.si.sound.namespaces._sound_object_internal;
    
    
    /** Chord pad provides polyphonic synthesizer controled by chord and rhythm pattern. */
    public class ChordPad extends MultiTrackSoundObject
    {
    // namespace
    //----------------------------------------
        use namespace _sound_object_internal;
        
        
        
        
    // constants
    //----------------------------------------
        /** closed voicing mode [o5c,o5e,o5g,o5b,o6e,o6g] for CM7 @see voiceMode */
        static public const CLOSED:int = 0x543210;
        
        /** opened voicing mode [o5c,o5g,o5b,o6e,o6g,o6b] for CM7 @see voiceMode */
        static public const OPENED:int = 0x654320;
        
        /** middle-position voicing mode [o5e,o5g,o5b,o6e,o6g,o6b] for CM7 @see voiceMode */
        static public const MIDDLE:int = 0x654321;
        
        /** high-position voicing mode [o5g,o5b,o6e,o6g,o6b,o7e] for CM7 @see voiceMode */
        static public const HIGH:int = 0x765432;
        
        /** opened high-position voicing mode [o5g,o6e,o6g,o6b,o7e,o7g] for CM7 @see voiceMode */
        static public const OPENED_HIGH:int = 0x876542;
        
        
        
        
    // variables
    //----------------------------------------
        /** @private [protected] Monophonic sequencers */
        protected var _operators:Vector.<Sequencer>;
        
        /** @private [protected] Sequence data */
        protected var _data:SiONData;
        
        /** @private [protected] chord instance */
        protected var _chord:Chord;
        /** @private [protected] Default chord instance, this is used when the name is specifyed */
        protected var _defaultChord:Chord = new Chord();
        /** @private [protected] chord notes index */
        protected var _noteIndexes:int;
        
        /** @private [protected] Note pattern */
        protected var _pattern:Vector.<Note>;
        /** @private [protected] Current length sequence pattern. */
        protected var _currentPattern:Array;
        /** @private [protected] Next length sequence pattern to change while playing. */
        protected var _nextPattern:Array;
        
        
        
        
    // properties
    //----------------------------------------
        /** list of monophonic operators */
        public function get operators() : Vector.<Sequencer> { return operators; }
        
        /** Number of monophonic operators */
        public function get operatorCount() : int { return operators.length; }
        
        
        /** root note of current chord @default 60 */
        override public function get note() : int { return _chord.rootNote; }
        override public function set note(n:int) : void {
            if (_chord !== _defaultChord) _defaultChord.copyFrom(_chord);
            _defaultChord.rootNote = n;
            _chord = _defaultChord;
            _updateChordNotes();
        }
        
        
        /** chord instance @default Chord("C") */
        public function get chord() : Chord { return _chord; }
        public function set chord(c:Chord) : void {
            if (c == null) _chord = _defaultChord;
            _chord = c;
            _updateChordNotes();
        }
        
        
        /** specify chord by name @default "C" */
        public function get chordName() : String { return _chord.name; }
        public function set chordName(name:String) : void {
            _defaultChord.name = name;
            _chord = _defaultChord;
            _updateChordNotes();
        }
        
        
        /** voicing mode @default CLOSED */
        public function get voiceMode() : int { return _noteIndexes; }
        public function set voiceMode(m:int) : void {
            _noteIndexes = m;
        }
        
        
        /** Number Array of the sequence notes' length. If the value is 0, insert rest instead. */
        public function set pattern(pat:Array) : void {
            if (!isPlaying) _updateSequencePattern(pat);
            else _nextPattern = pat;
        }
        
        
        
        
    // constructor
    //----------------------------------------
        /** constructor 
         *  @param chord org.si.sion.utils.Chord, chord name String or null is suitable.
         *  @param operatorCount Number of monophonic operators (1-6).
         *  @param voiceMode Voicing mode.
         *  @param pattern Number Array of the sequence notes' length. If the value is 0, insert rest instead.
         */
        function ChordPad(chord:*=null, operatorCount:int=4, voiceMode:int=CLOSED, pattern:Array=null)
        {
            super("ChordPad");
            
            if (operatorCount<1 || operatorCount>6) throw new Error("ChordPad; Number of operators should be in the range of 1 - 6.");
            
            _data = new SiONData();
            _operators = new Vector.<Sequencer>(operatorCount);
            _noteIndexes = voiceMode;
            
            for (var i:int=0; i<operatorCount; i++) {
                _operators[i] = new Sequencer(this, _data, 60, 128, 1);
                _operators[i].onEnterSegment = _onEnterSegment;
            }
            
            if (chord is Chord) {
                _chord = chord as Chord;
            } else {
                _chord = _defaultChord;
                if (chord is String) {
                    _chord.name = chord as String;
                }
            }
            
            _nextPattern = null;
            _pattern = new Vector.<Note>();
            
            _updateChordNotes();
            _updateSequencePattern(pattern);
        }
        
        
        
        
    // configure
    //----------------------------------------
        
        
        
        
    // operations
    //----------------------------------------
        /** play drum sequence */
        override public function play() : void
        {
            var i:int, imax:int = _operators.length;
            stop();
            _tracks = _sequenceOn(_data, false, false);
            if (_tracks && _tracks.length == imax) {
                _synthesizer._registerTracks(_tracks);
                for (i=0; i<imax; i++) _operators[i].play(_tracks[i]);
            }
        }
        
        
        /** stop sequence */
        override public function stop() : void
        {
            if (_tracks) {
                for (var i:int=0; i<_operators.length; i++) _operators[i].stop();
                _synthesizer._unregisterTracks(_tracks[0], _tracks.length);
                for each (var t:SiMMLTrack in _tracks) t.setDisposable();
                _tracks = null;
                _sequenceOff(false);
            }
            _stopEffect();
        }
        
        
        
        
    // internals
    //----------------------------------------
        /** @private [protected] update chord notes */
        protected function _updateChordNotes() : void 
        {
            var i:int, imax:int = _operators.length, noteIndex:int;
            for (i=0; i<imax; i++) {
                _operators[i].defaultNote = _chord.getNote((_noteIndexes>>(i<<2)) & 15);
            }
        }
        
        
        /** @private [protected] update sequence pattern */
        protected function _updateSequencePattern(lengthPattern:Array) : void
        {
            var i:int, imax:int;
            
            _currentPattern = lengthPattern;
            if (_currentPattern) {
                imax = _currentPattern.length;
                _pattern.length = imax;
                for (i=0; i<imax; i++) {
                    if (_pattern[i] == null) _pattern[i] = new Note();
                    if (lengthPattern[i] == 0) _pattern[i].setRest();
                    else _pattern[i].setNote(-1, -1, _currentPattern[i]);
                }
                imax = _operators.length;
                for (i=0; i<imax; i++) {
                    _operators[i].pattern = _pattern;
                }
            } else {
                for (i=0; i<imax; i++) {
                    _operators[i].pattern = null;
                }
            }
        }
        
        
        // on enter segment 
        private function _onEnterSegment() : void {
            if (_nextPattern != null) {
                _updateSequencePattern(_nextPattern);
                _nextPattern = null;
            }
        }
    }
}

