//----------------------------------------------------------------------------------------------------
// Bass sequencer class
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound {
    import org.si.sion.*;
    import org.si.sion.utils.Chord;
    import org.si.sound.patterns.BassSequencerPresetPattern;
    import org.si.sound.namespaces._sound_object_internal;
    
    
    /** Bass sequencer provides simple monophonic bass line by pattern number. */
    public class BassSequencer extends PatternSequencer
    {
    // namespace
    //----------------------------------------
        use namespace _sound_object_internal;
        
        
        
        
    // static variables
    //----------------------------------------
        static private var _presetPattern:BassSequencerPresetPattern = null;
        static private var bassPatternList:Array;
        
        
        
        
    // variables
    //----------------------------------------
        /** chord instance */
        protected var _chord:Chord;
        /** Default chord instance, this is used when the name is specifyed */
        protected var _defaultChord:Chord = new Chord();

        /** Current bass line. */
        protected var _currentPattern:Array;
        /** Next bass line to change while playing. */
        protected var _nextPatternNumber:int;
        
                
        
        
    // properties
    //----------------------------------------
        /** Preset voice list */
        //public function get presetVoice() : BassSequencerPresetVoice { return _presetVoice; }
        
        /** Preset pattern list */
        public function get presetPattern() : BassSequencerPresetPattern { return _presetPattern; }
        
        
        /** @private */
        override public function get note() : int { return _chord.rootNote; }
        override public function set note(n:int) : void {
            if (_chord !== _defaultChord) _defaultChord.copyFrom(_chord);
            _defaultChord.rootNote = n;
            _chord = _defaultChord;
            //_updateChordNotes();
        }
        
        
        /** chord instance */
        public function get chord() : Chord { return _chord; }
        public function set chord(c:Chord) : void {
            if (c == null) _chord = _defaultChord;
            _chord = c;
            //_updateChordNotes();
        }
        
        
        /** specify chord by name */
        public function get chordName() : String { return _chord.name; }
        public function set chordName(name:String) : void {
            _defaultChord.name = name;
            _chord = _defaultChord;
            //_updateChordNotes();
        }
        
        
        /** maximum limit of bass line Pattern number */
        public function get bassPatternNumberMax() : int {
            return bassPatternList.length;
        }
        
        
        /** bass line Pattern number */
        public function set patternNumber(n:int) : void {
            if (n < 0 || n >= bassPatternList.length) return;
            _sequencer.pattern = bassPatternList[n];
        }
        
        
        
        
    // constructor
    //----------------------------------------
        /** constructor 
         *  @param scale Arpaggio scale, org.si.sion.utils.Scale instance, scale name String or null is suitable.
         *  @param noteLength length for each note
         *  @param pattern arpegio pattern 
         *  @see org.si.sion.utils.Scale
         */
        function BassSequencer(chord:*=null) 
        {
            super();
            name = "BassSequencer";
            
            if (_presetPattern == null) {
                _presetPattern = new BassSequencerPresetPattern();
                bassPatternList = _presetPattern["bass"];
            }
            
            _chord = new Chord();
            if (chord is Chord) _chord.copyFrom(chord as Chord);
            else if (chord is String) _chord.name = chord as String;
            
            _nextPatternNumber = -1;
            _sequencer.onEnterSegment = _onEnterSegment;
        }
        
        
        
        
        
    // internal
    //----------------------------------------
        // on enter segment 
        private function _onEnterSegment() : void {
            if (_nextPatternNumber != -1) {
                patternNumber = _nextPatternNumber;
                _nextPatternNumber = -1;
            }
        }
    }
}

