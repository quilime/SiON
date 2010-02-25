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
    public class RhythmBox extends MMLSoundObject
    {
    // variables
    //----------------------------------------
        /** voices for all tracks */
        protected var _voices:Vector.<SiONVoice>;
        
        /** notes for all tracks */
        protected var _notes:Vector.<int>;
        
        /** volumes for all tracks */
        protected var _trackVolumes:Vector.<int>;
        
        /** phrases */
        protected var _phrases:Vector.<Vector.<Number>>;
        
        /** interruption step */
        protected var _interruptStep:int;
        
        
        
    // properties
    //----------------------------------------
        /** track count. this must be grater than 4. */
        public function set trackCount(count:int) : void {
            if (count < 4) count = 4;
            _voices.length  = count;
            _trackVolumes.length = count;
            _phrases.length = count;
        }
        public function get trackCount() : int { return _voices.length; }
        
        
        
        
    // constructor
    //----------------------------------------
        /** constructor */
        function RhythmBox(trackCount:int = 4)
        {
            _voices       = new Vector.<SiONVoice>(trackCount);
            _trackVolumes = new Vector.<int>(trackCount);
            _phrases      = new Vector.<Vector.<int>>(trackCount);
            super(null);
            name = "RhythmBox";
            _phrases[0] = Vector.<int>([]);
            _phrases[1] = Vector.<int>([]);
            _phrases[2] = Vector.<int>([]);
            _phrases[3] = Vector.<int>([]);
            _interruptStep = 120;
        }
        
        
        
        
    // settings
    //----------------------------------------
        /** Get volume */
        public function getVolume(trackIndex:int) : Number {
            return _trackVolumes[trackIndex]*0.0078125;
        }
        
        
        /** Set volume */
        public function setVolume(trackIndex:int, v:Number) : void {
            if (v < 0) v = 0;
            else if (v > 1) v = 1;
            _trackVolumes[trackIndex] = v*128;
            if (_tracks) _tracks[trackIndex].expression = _trackVolumes[trackIndex];
        }
        
        
        /** Get voice */
        public function getVoice(trackIndex:int) : SiONVoice {
            return _voices[trackIndex];
        }
        
        
        /** Set voice */
        public function setVoice(trackIndex:int, v:SiONVoice) : void {
            _voices[trackIndex] = v;
            if (_tracks) v.setTrackVoice(_tracks[trackIndex]);
        }
        
        
        
        
    // operations
    //----------------------------------------
        
        
        
        
    // internal
    //----------------------------------------
        private function _constructData() : void 
        {
            var seq:SiMMLSequence, i:int = 0, imax:int = _phrases.length;
            _data.clear();
            for (i=0; i<imax; i++) {
                seq = _data.appendSequence().initialize();
                seq.appendNewEvent(MMLEvent.REPEAT_ALL);
                seq.appendNewCallback(_onTrackInterruption, i);
                seq.appendNewEvent(MMLEvent.REST, 0, _interruptStep);
            }
        }
        
        private function _onTrackInterruption(data:int) : MMLEvent
        {
            var track:SiMMLTrack = _tracks[data];
            track.keyOn(0, );
            return null;
        }
    }
}

