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
    // variables
    //----------------------------------------
        /** interruption step */
        protected var _interruptStep:int;
        
        /** bass drum pattern sequencer */
        public var bass:PatternSequencer;
        /** snare drum pattern sequencer */
        public var snare:PatternSequencer;
        /** hi-hat cymbal pattern sequencer */
        public var hihat:PatternSequencer;
        
        protected var _closeHHPattern:Vector.<int>;
        protected var _openHHPattern:Vector.<int>;
        protected var _hhVoiceIndex:Vector.<int>;
        protected var _hhVoices:Vector.<SiONVoice>;
        protected var _currentHHIndex:int;
        
        
        
        
    // properties
    //----------------------------------------
        /** bass drum velocity pattern */
        public function set bassPattern(pat:Array) : void
        {
            var i:int, len:int = pat.length;
            for (i=0; i<16; i++) {
                bass.pattern[i].velocity = pat[i % len];
            }
        }
        
        
        /** snare drum velocity pattern */
        public function set snarePattern(pat:Array) : void
        {
            var i:int, len:int = pat.length;
            for (i=0; i<16; i++) {
                snare.pattern[i].velocity = pat[i % len];
            }
        }
        
        
        /** close hi-hat cymbal velocity pattern */
        public function set closeHHPattern(pat:Array) : void
        {
            var i:int, len:int = pat.length;
            for (i=0; i<16; i++) _closeHHPattern[i] = pat[i % len];
            _updateHHPatterns();
        }
        
        
        /** open hi-hat cymbal velocity pattern */
        public function set openHHPattern(pat:Array) : void
        {
            var i:int, len:int = pat.length;
            for (i=0; i<16; i++) _openHHPattern[i] = pat[i % len];
            _updateHHPatterns();
        }
        
        
        /** close hi-hat cymbal voice */
        public function set closeHHVoice(v:SiONVoice) : void
        {
            _hhVoices[0] = v;
            hihat.voice = v;
        }
        

        /** open hi-hat cymbal voice */
        public function set openHHVoice(v:SiONVoice) : void
        {
            _hhVoices[1] = v;
        }
        
        
        
        
    // constructor
    //----------------------------------------
        /** constructor */
        function RhythmBox()
        {
            super("RhythmBox");
            _interruptStep = 120;
            _closeHHPattern = new Vector.<int>(16, true);
            _openHHPattern  = new Vector.<int>(16, true);
            _hhVoiceIndex   = new Vector.<int>(16, true);
            _hhVoices       = new Vector.<SiONVoice>(2, true);
            addChild(bass  = new PatternSequencer(16, 36, 255, 1));
            addChild(snare = new PatternSequencer(16, 68, 128, 1));
            addChild(hihat = new PatternSequencer(16, 68, 64,  1));
            bass.pattern = new Vector.<Note>();
            snare.pattern = new Vector.<Note>();
            hihat.pattern = new Vector.<Note>();
            hihat.onNoteOn = _onNoteOnHH;
            for (var i:int=0; i<16; i++) {
                bass.pattern[i]  = new Note();
                snare.pattern[i] = new Note();
                hihat.pattern[i] = new Note();
                _hhVoiceIndex[i] = 0;
            }
        }
        
        
        
        
    // settings
    //----------------------------------------
        /** Get track volume */
        public function getTrackVolume(trackIndex:int) : Number {
            return _soundList[trackIndex].volume;
        }
        
        
        /** Set track volume */
        public function setTrackVolume(trackIndex:int, v:Number) : void {
            _soundList[trackIndex].volume = v;
        }
        
        
        /** Get track voice */
        public function getTrackVoice(trackIndex:int) : SiONVoice {
            return _soundList[trackIndex].voice;
        }
        
        
        /** Set track voice */
        public function setTrackVoice(trackIndex:int, v:SiONVoice) : void {
            _soundList[trackIndex].voice = v;
        }
        
        
        
        
    // operations
    //----------------------------------------
        /** @inhriteDoc */
        override public function play() : void {
            _currentHHIndex = 0;
            super.play();
        }
        
        
        
        
    // internal
    //----------------------------------------
        /** call after updating hi-hat patterns */
        protected function _updateHHPatterns() : void {
            var i:int, vel:int;
            for (i=0; i<16; i++) {
                if (_openHHPattern[i] > 0) {
                    vel = _openHHPattern[i];
                    _hhVoiceIndex[i] = 2;
                } else {
                    vel = _closeHHPattern[i];
                    _hhVoiceIndex[i] = (vel==0) ? 0 : 1;
                }
                hihat.pattern[i].velocity = vel;
            }
        }
        
        
        /** handler for hi-hat note on */
        private function _onNoteOnHH() : void {
            var voiceIndex:int = _hhVoiceIndex[hihat.frameCount];
            if (voiceIndex != 0 && voiceIndex != _currentHHIndex) {
                hihat.voice = _hhVoices[voiceIndex-1];
                _currentHHIndex = voiceIndex;
            }
        }
    }
}

