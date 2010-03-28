//----------------------------------------------------------------------------------------------------
// Class for play rhythm tracks
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound {
    import org.si.sound.base.*;
    import org.si.sound.synthesizers.RhythmBoxPresetVoice;
    import org.si.sound.patterns.RhythmBoxPresetPattern;
    
    
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
        static private var bassPatternList:Array;
        static private var snarePatternList:Array;
        static private var hihatPatternList:Array;
        static private var percusPatternList:Array;
        static private var bassVoiceList:Array;
        static private var snareVoiceList:Array;
        static private var hihatVoiceList:Array;
        static private var percusVoiceList:Array;
        
        
        
    // properties
    //----------------------------------------
        /** Preset voices */
        public function get presetVoice() : RhythmBoxPresetVoice { return _presetVoice; }
        
        /** Preset patterns */
        public function get presetPattern() : RhythmBoxPresetPattern { return _presetPattern; }
        
        /** maximum value of basePatternIndex */  public function get bassPatternIndexMax()  : int { return bassPatternList.length; }
        /** maximum value of snarePatternIndex */ public function get snarePatternIndexMax() : int { return snarePatternList.length; }
        /** maximum value of hihatPatternIndex */ public function get hihatPatternIndexMax() : int { return hihatPatternList.length; }
        /** maximum value of baseVoiceIndex */    public function get bassVoiceIndexMax()  : int { return bassVoiceList.length>>1; }
        /** maximum value of snareVoiceIndex */   public function get snareVoiceIndexMax() : int { return snareVoiceList.length>>1; }
        /** maximum value of hihatVoiceIndex */   public function get hihatVoiceIndexMax() : int { return hihatVoiceList.length>>1; }
        
        
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
        
        
        /** bass drum pattern number. */
        public function set bassVoiceIndex(index:int) : void {
            index <<= 1;
            if (index < 0 || index >= bassVoiceList.length) return;
            bass.voiceList = [bassVoiceList[index], bassVoiceList[index+1]];
        }
        
        
        /** snare drum pattern number. */
        public function set snareVoiceIndex(index:int) : void {
            index <<= 1;
            if (index < 0 || index >= snareVoiceList.length) return;
            snare.voiceList = [snareVoiceList[index], snareVoiceList[index+1]];
        }
        
        
        /** hi-hat cymbal pattern number. */
        public function set hihatVoiceIndex(index:int) : void {
            index <<= 1;
            if (index < 0 || index >= hihatVoiceList.length) return;
            hihat.voiceList = [hihatVoiceList[index], hihatVoiceList[index+1]];
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
                bassPatternList   = _presetPattern["bass"];
                snarePatternList  = _presetPattern["snare"];
                hihatPatternList  = _presetPattern["hihat"];
                percusPatternList = _presetPattern["percus"];
                bassVoiceList   = _presetVoice["bass"];
                snareVoiceList  = _presetVoice["snare"];
                hihatVoiceList  = _presetVoice["hihat"];
                percusVoiceList = _presetVoice["percus"];
            }
            
            super("RhythmBox");
            
            addChild(bass   = new PatternSequencer(16, 36, 255, 1));
            addChild(snare  = new PatternSequencer(16, 68, 128, 1));
            addChild(hihat  = new PatternSequencer(16, 68, 64,  1));
            bassVoiceIndex = 0;
            snareVoiceIndex = 0;
            hihatVoiceIndex = 0;
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

