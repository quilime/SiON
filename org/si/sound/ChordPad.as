//----------------------------------------------------------------------------------------------------
// Polyphonic chord pad synthesizer
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound {
    import org.si.sion.utils.Chord;
    import org.si.sound.patterns.Note;
    import org.si.sound.namespaces._sound_object_internal;
    
    
    /** Polyphonic chord pad synthesizer */
    public class ChordPad extends SoundObjectContainer
    {
    // namespace
    //----------------------------------------
        use namespace _sound_object_internal;
        
        
        
        
    // variables
    //----------------------------------------
        /** Monophonic synthesize operators */
        public var operators:Vector.<PatternSequencer>;
        
        /** chord instance */
        protected var _chord:Chord;
        /** Default chord instance, this is used when the name is specifyed */
        protected var _defaultChord:Chord = new Chord();
        
        /** Note pattern */
        protected var _pattern:Vector.<Note>;
        
        /** Current length sequence pattern. */
        protected var _currentPattern:Array;
        /** Next length sequence pattern to change while playing. */
        protected var _nextPattern:Array;
        
        
        
        
    // properties
    //----------------------------------------
        /** Number of monophonic operators */
        public function get operatorCount() : int { return operators.length; }
        
        
        /** @private */
        override public function get note() : int { return _chord.rootNote; }
        override public function set note(n:int) : void {
            if (_chord !== _defaultChord) _defaultChord.copyFrom(_chord);
            _defaultChord.rootNote = n;
            _chord = _defaultChord;
            _updateChordNotes();
        }
        
        
        /** chord instance */
        public function get chord() : Chord { return _chord; }
        public function set chord(c:Chord) : void {
            if (c == null) _chord = _defaultChord;
            _chord = c;
            _updateChordNotes();
        }
        
        
        /** specify chord by name */
        public function get chordName() : String { return _chord.name; }
        public function set chordName(name:String) : void {
            _defaultChord.name = name;
            _chord = _defaultChord;
            _updateChordNotes();
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
         *  @param operatorCount Number of monophonic operators.
         *  @param pattern Number Array of the sequence notes' length. If the value is 0, insert rest instead.
         */
        function ChordPad(chord:*=null, operatorCount:int = 4, pattern:Array=null)
        {
            super("ChordPad");
            operators = new Vector.<PatternSequencer>(operatorCount);
            for (var i:int=0; i<operatorCount; i++) {
                addChild(operators[i] = new PatternSequencer());
                operators[i].sequencer.onEnterSegment = _onEnterSegment;
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
        
        
        
        
    // operation
    //----------------------------------------
        /** update chord notes */
        protected function _updateChordNotes() : void 
        {
            var i:int, imax:int = operators.length;
            for (i=0; i<imax; i++) {
                operators[i].sequencer.defaultNote = _chord.getNote(i);
            }
        }
        
        
        /** update sequence pattern */
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
                imax = operators.length;
                for (i=0; i<imax; i++) {
                    operators[i].sequencer.pattern = _pattern;
                }
            } else {
                for (i=0; i<imax; i++) {
                    operators[i].sequencer.pattern = null;
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

