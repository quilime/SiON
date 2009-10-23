//----------------------------------------------------------------------------------------------------
// Class for sound object with single track
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound.base {
    import org.si.sion.*;
    import org.si.sion.sequencer.SiMMLTrack;
    
    
    /** Sound object with single track */
    public class SingleTrackObject extends SoundObject
    {
    // variables
    //----------------------------------------
        /** voice data. */
        public var voice:SiONVoice;
        /** sequence data. */
        protected var _data:SiONData;

        /** note quantize */
        protected var _noteQuantize:int;
        /** Event trigger ID */
        protected var _eventTriggerID:int;
        /** note on trigger type */
        protected var _noteOnTrigger:int;
        /** note off trigger type */
        protected var _noteOffTrigger:int;
        
        // track to control
        private var _track:SiMMLTrack;
        
        
        
        
    // properties
    //----------------------------------------
        /** note quantize (value of 'q' command) */
        public function get noteQuantize() : int { return _noteQuantize; }
        public function set noteQuantize(q:int) : void {
            _noteQuantize = q;
            if (_noteQuantize < 0) _noteQuantize = 0;
            else if (_noteQuantize > 8) _noteQuantize = 8;
            var t:SiMMLTrack = track;
            if (t) t.quantRatio = _noteQuantize * 0.125;
        }
        
        /** sequence data */
        public function get data() : SiONData { return _data; }
        
        /** track. Available only after play(). Returns null when the track is stopped. */
        public function get track() : SiMMLTrack { 
            if (_track && !_track.isActive) _track = null;
            return _track;
        }
        
        /** @private */
        override public function set mute(m:Boolean) : void { 
            super.mute = m;
            var t:SiMMLTrack = track;
            if (t) t.channel.masterVolume = (_totalMute) ? 0 : _totalVolume*128;
        }
        
        /** @private */
        override public function set volume(v:Number) : void {
            super.volume = v;
            var t:SiMMLTrack = track;
            if (t) t.channel.masterVolume = (_totalMute) ? 0 : _totalVolume*128;
        }
        
        /** @private */
        override public function set pan(p:Number) : void {
            super.pan = p;
            var t:SiMMLTrack = track;
            if (t) t.channel.pan = _totalPan;
        }
        
        /** @private */
        override public function get isPlaying() : Boolean {
            return (_track && _track.isActive);
        }
        
        
        
        
    // constructor
    //----------------------------------------
        /** constructor */
        function SingleTrackObject(name:String="") {
            super(name);
            voice = null;
            _data = null;
            _track = null;
            _eventTriggerID = 0;
            _noteOnTrigger = 0;
            _noteOffTrigger = 0;
            _noteQuantize = 6;
        }
        
        
        
        
    // operations
    //----------------------------------------
        /** Set event trigger.
         *  @param id Event trigger ID of this track. This value can be refered from SiONTrackEvent.eventTriggerID.
         *  @param noteOnType Dispatching event type at note on. 0=no events, 1=NOTE_ON_FRAME, 2=NOTE_ON_STREAM, 3=both.
         *  @param noteOffType Dispatching event type at note off. 0=no events, 1=NOTE_OFF_FRAME, 2=NOTE_OFF_STREAM, 3=both.
         *  @see org.si.sion.events.SiONTrackEvent
         */
        public function setEventTrigger(id:int, noteOnType:int=1, noteOffType:int=0) : void
        {
            _eventTriggerID = id;
            _noteOnTrigger = noteOnType;
            _noteOffTrigger = noteOffType;
        }
        
        
        /** call driver.noteOn() */
        protected function noteOn() : void
        {
            var oldTrack:SiMMLTrack = track;
            _track = driver.noteOn(_note, voice, _length, _delay, _quantize, _trackID, _eventTriggerID, _noteOnTrigger, _noteOffTrigger);
            if (_track) {
                if (oldTrack) oldTrack.keyOff(_track.trackStartDelay);
                _track.channel.pan = _totalPan;
                _track.channel.masterVolume = (_totalMute) ? 0 : _totalVolume*128;
                _track.quantRatio = _noteQuantize * 0.125;
            }
        }
        
        
        /** call driver.noteOff() */
        protected function noteOff() : void
        {
            driver.noteOff(_note, _trackID, 0, 1);
        }
        
        
        /** call driver.sequenceOn(_data) */
        protected function sequenceOn() : void
        {
            var oldTrack:SiMMLTrack = track;
            var tracks:Vector.<SiMMLTrack> = driver.sequenceOn(_data, voice, _length, _delay, _quantize, _trackID);
            if (tracks.length > 0) {
                _track = tracks[0];
                if (oldTrack) oldTrack.sequenceOff(_track.trackStartDelay-1);
                _track.channel.pan = _totalPan;
                _track.channel.masterVolume = (_totalMute) ? 0 : _totalVolume*128;
                _track.quantRatio = _noteQuantize * 0.125;
                _track.setEventTrigger(_eventTriggerID, _noteOnTrigger, _noteOffTrigger);
            } else {
                _track = null;
                if (oldTrack) oldTrack.sequenceOff(0);
            }
        }
        
        
        /** call driver.sequenceOff() */
        protected function sequenceOff() : void
        {
            driver.sequenceOff(_trackID, 0, 1);
        }
        
        
        /** Play sound. */
        override public function play() : void { noteOn(); }
        
        
        /** Stop sound. */
        override public function stop() : void { noteOff(); }
    }
}

