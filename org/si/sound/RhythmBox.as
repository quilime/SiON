//----------------------------------------------------------------------------------------------------
// Class for play rhythm tracks
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound {
    import org.si.sion.*;
    import org.si.sound.base.*;
    import org.si.sion.sequencer.SiMMLTrack;
    import org.si.sion.sequencer.SiMMLSequencer;
    import org.si.sion.sequencer.base.MMLSequence;
    
    
    /** Sound object playng rhythm tracks */
    public class RhythmBox extends SoundObjectContainer
    {
    // static variables
    //----------------------------------------
        static private var _presetVoice:RhythmBoxPresetVoice = null;
        static private var _presetPattern:RhythmBoxPresetPattern = null;
        
        
        
        
    // variables
    //----------------------------------------
        /** bass drum pattern sequencer */
        public var bass:PatternSequencer;
        /** snare drum pattern sequencer */
        public var snare:PatternSequencer;
        /** hi-hat cymbal pattern sequencer */
        public var hihat:PatternSequencer;
        
        // preset pattern list
        private var bassPatternList:Array;
        private var snarePatternList:Array;
        private var hihatPatternList:Array;
        private var percusPatternList:Array;
        
        
        
    // properties
    //----------------------------------------
        /** Preset voices */
        public function get presetVoice() : RhythmBoxPresetVoice {
            return _presetVoice;
        }
        
        
        /** Preset patterns */
        public function get presetPattern() : RhythmBoxPresetPattern {
            return _presetPattern;
        }
        
        
        /** bass drum pattern number, -1 sets no patterns. */
        public function set bassPatternIndex(index:int) : void {
            if (index < -1 || index >= bassPatternList.length) return;
            bass.pattern = (index != -1) ? bassPatternList[index] : null;
        }
        
        
        /** snare drum pattern number, -1 sets no patterns. */
        public function set snarePatternIndex(index:int) : void {
            if (index < -1 || index >= snarePatternList.length) return;
            snare.pattern = (index != -1) ? snarePatternList[index] : null;
        }
        
        
        /** hi-hat cymbal pattern number, -1 sets no patterns. */
        public function set hihatPatternIndex(index:int) : void {
            if (index < -1 || index >= hihatPatternList.length) return;
            hihat.pattern = (index != -1) ? hihatPatternList[index] : null;
        }
        
        
        /** bass drum voice list */
        public function set bassVoiceList(list:Array) : void {
            bass.voiceList = list;
        }
        
        
        /** snare drum voice list */
        public function set snareVoiceList(list:Array) : void {
            snare.voiceList = list;
        }
        
        
        /** hi-hat cymbal voice list */
        public function set hihatVoiceList(list:Array) : void {
            hihat.voiceList = list;
        }
        
        
        
        
    // constructor
    //----------------------------------------
        /** constructor 
         *  @param bassPatternIndex bass drum pattern index
         *  @param snarePatternIndex snare drum pattern index
         *  @param hihatPatternIndex hihat symbal pattern index
         */
        function RhythmBox(bassPatternIndex:int=0, snarePatternIndex:int=8, hihatPatternIndex:int=0)
        {
            if (_presetVoice == null) {
                _presetVoice = new RhythmBoxPresetVoice();
                _presetPattern = new RhythmBoxPresetPattern();
            }
            
            super("RhythmBox");
            
            bassPatternList   = _presetPattern["bass"];
            snarePatternList  = _presetPattern["snare"];
            hihatPatternList  = _presetPattern["hihat"];
            percusPatternList = _presetPattern["percus"];
            addChild(bass   = new PatternSequencer(16, 36, 255, 1));
            addChild(snare  = new PatternSequencer(16, 68, 128, 1));
            addChild(hihat  = new PatternSequencer(16, 68, 64,  1));
            bass.voiceList  = [_presetVoice["bass1"],  _presetVoice["bass1"]];
            snare.voiceList = [_presetVoice["snare1"], _presetVoice["snare2"]];
            hihat.voiceList = [_presetVoice["closedhh1"], _presetVoice["openedhh1"]];
            bass.velocity = 192;
            snare.velocity = 128;
            hihat.velocity = 64;
            
            setPatternIndex(bassPatternIndex, snarePatternIndex, hihatPatternIndex);
        }
        
        
        
        
    // configure
    //----------------------------------------
        /** Set all pattern indeces 
         *  @param bassPatternIndex bass drum pattern index
         *  @param snarePatternIndex snare drum pattern index
         *  @param hihatPatternIndex hihat symbal pattern index
         */
        public function setPatternIndex(bassPatternIndex:int, snarePatternIndex:int, hihatPatternIndex:int) : RhythmBox
        {
            this.bassPatternIndex  = bassPatternIndex;
            this.snarePatternIndex = snarePatternIndex;
            this.hihatPatternIndex = hihatPatternIndex;
            return this;
        }
    }
}

