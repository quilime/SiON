//----------------------------------------------------------------------------------------------------
// Sound object
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound {
    import flash.events.EventDispatcher;
    import org.si.sion.*;
    import org.si.sion.utils.Translator;
    import org.si.sion.utils.Fader;
    import org.si.sion.namespaces._sion_internal;
    import org.si.sion.events.SiONEvent;
    import org.si.sion.events.SiONTrackEvent;
    import org.si.sion.effector.SiEffectBase;
    import org.si.sion.module.SiOPMModule;
    import org.si.sion.sequencer.SiMMLTrack;
    import org.si.sound.namespaces._sound_object_internal;
    import org.si.sound.core.EffectChain;
    import org.si.sound.synthesizers.VoiceReference;
    import org.si.sound.synthesizers.BasicSynth;
    import org.si.sound.synthesizers._synthesizer_internal;
    
    
    /** The SoundObject class is the base class for all objects that can play sounds by operating SiONDriver. 
     */
    public class SoundObject extends EventDispatcher
    {
    // namespace
    //----------------------------------------
        use namespace _synthesizer_internal;
        use namespace _sound_object_internal;
        
        
        
        
    // valiables
    //----------------------------------------
        /** Name. */
        public var name:String;
        
        /** @private [protected] Base note of this sound */
        protected var _note:int;
        /** @private [protected] Synthesizer instance */
        protected var _synthesizer:VoiceReference;
        /** @private [protected] Synthesizer instance to use SiONVoice  */
        protected var _voiceReference:VoiceReference;
        /** @private [protected] Effect chain instance */
        protected var _effectChain:EffectChain;
        /** @private [protected] track for noteOn() */
        protected var _track:SiMMLTrack;
        /** @private [protected] tracks for sequenceOn() */
        protected var _tracks:Vector.<SiMMLTrack>;
        /** @private [protected] Auto-fader to fade in/out. */
        protected var _fader:Fader;
        /** @private [protected] Fader volume. */
        protected var _faderVolume:Number;
        
        /** @private [protected] Sound length uint in 16th beat, 0 sets inifinity length. @default 0. */
        protected var _length:Number;
        /** @private [protected] Sound delay uint in 16th beat. @default 0. */
        protected var _delay:Number;
        /** @private [protected] Synchronizing uint in 16th beat. (0:No synchronization, 1:sync.with 16th, 4:sync.with 4th). @default 0. */
        protected var _quantize:Number;
        
        /** @private [protected] Note shift in half-tone unit. */
        protected var _noteShift:int;
        /** @private [protected] Pitch shift in half-tone unit. */
        protected var _pitchShift:Number;
        /** @private [protected] gate ratio (value of 'q' command * 0.125) */
        protected var _gateTime:Number;
        /** @private [protected] Event mask (value of '@mask' command) */
        protected var _eventMask:Number;
        /** @private [protected] Event trigger ID */
        protected var _eventTriggerID:int;
        /** @private [protected] note on trigger type */
        protected var _noteOnTrigger:int;
        /** @private [protected] note off trigger type */
        protected var _noteOffTrigger:int;
        
        /** @private [protected] volumes for all streams */
        protected var _volumes:Vector.<int>;
        /** @private [protected] total panning of all ancestors */
        protected var _pan:Number;
        /** @private [protected] total mute flag of all ancestors */
        protected var _mute:Boolean;
        /** @private [protected] Pitch bend in half-tone unit. */
        protected var _pitchBend:Number;
        
        /** @private [protected] parent container */
        protected var _parent:SoundObjectContainer;
        /** @private [protected] the depth of parent-child chain */
        protected var _childDepth:int;
        /** @private [protected] volume of this sound object */
        protected var _thisVolume:Number;
        /** @private [protected] panning of this sound object */
        protected var _thisPan:Number;
        /** @private [protected] mute flag of this sound object */
        protected var _thisMute:Boolean;
        
        /** @private [protected] track id. This value is asigned when its created. */
        protected var _trackID:int;
        
        
        
        
    // properties
    //----------------------------------------
        /** SiONDriver instrance to operate. this returns null when driver is not created. */
        public function get driver() : SiONDriver { return SiONDriver.mutex; }
        
        /** parent container. */
        public function get parent() : SoundObjectContainer { return _parent; }
        
        /** is playing ? */
        public function get isPlaying() : Boolean { return (_track != null); }

        
        /** Base note of this sound */
        public function get note() : int { return _note; }
        public function set note(n:int) : void { _note = n; }
        
        /** Voice data to play */
        public function get voice() : SiONVoice { 
            return _synthesizer._synthesizer_internal::_voice;
        }
        public function set voice(v:SiONVoice) : void { 
            _voiceReference.voice = v;
            if (!isPlaying) _synthesizer = _voiceReference;
        }

        /** Synthesizer to generate sound */
        public function get synthesizer() : VoiceReference { 
            return _synthesizer;
        }
        public function set synthesizer(s:VoiceReference) : void {
            if (isPlaying) throw new Error("SoundObject: Synthesizer should not be changed during playing.");
            _synthesizer = s || _voiceReference;
        }
        
        /** Sound length in 16th beat, 0 sets inifinity length. @default 0. */
        public function get length() : Number { return _length; }
        public function set length(l:Number) : void { _length = l; }
        
        /** Synchronizing quantizing, uint in 16th beat. (0:No synchronization, 1:sync.with 16th, 4:sync.with 4th). @default 0. */
        public function get quantize() : Number { return _quantize; }
        public function set quantize(q:Number) : void { _quantize = q; }
        
        /** Sound delay, uint in 16th beat. @default 0. */
        public function get delay() : Number { return _delay; }
        public function set delay(d:Number) : void { _delay = d; }
        
        
        
        /** Master coarse tuning, 1 for half-tone. */
        public function get coarseTune() : int { return _noteShift; }
        public function set coarseTune(n:int) : void {
            _noteShift = n;
            if (_track) _track.noteShift = _noteShift;
        }
        /** Master fine tuning, 1 for half-tone, you can specify fineTune<-1 or fineTune>1. */
        public function get fineTune() : Number { return _pitchShift * 0.015625; }
        public function set fineTune(p:Number) : void {
            _pitchShift = p;
            if (_track) _track.pitchShift = _pitchShift * 64;
        }
        /** Track gate time (0:Minimum - 1:Maximum). (value of 'q' command * 0.125) */
        public function get gateTime() : Number { return _gateTime; }
        public function set gateTime(g:Number) : void {
            _gateTime = (g<0) ? 0 : (g>1) ? 1 : g;
            if (_track) _track.quantRatio = _gateTime;
        }
        /** Track event mask. (value of '@mask' command) */
        public function get eventMask() : int { return _eventMask; }
        public function set eventMask(m:int) : void {
            _eventMask = m;
            if (_track) _track.eventMask = _eventMask;
        }
        /** Track id */
        public function get trackID() : int { return _trackID; }
        /** Track event trigger ID */
        public function get eventTriggerID() : int { return _eventTriggerID; }
        /** Track note on trigger type */
        public function get noteOnTriggerType() : int { return _noteOnTrigger; }
        /** Track note off trigger type */
        public function get noteOffTriggerType() : int { return _noteOffTrigger; }
        
        
        /** Channel mute, this property can control track after play(). */
        public function get mute() : Boolean { return _thisMute; }
        public function set mute(m:Boolean) : void { 
            _thisMute = m;
            _updateMute();
            if (_track) _track.channel.mute = _mute;
        }
        /** Channel volume (0:Minimum - 1:Maximum), this property can control track after play(). */
        public function get volume() : Number { return _thisVolume; }
        public function set volume(v:Number) : void {
            _thisVolume = v;
            _updateVolume();
            _limitVolume();
            _updateStreamSend(0, _volumes[0] * 0.0078125);
        }
        /** Channel panning (-1:Left - 0:Center - +1:Right), this property can control track after play(). */
        public function get pan() : Number { return _thisPan; }
        public function set pan(p:Number) : void {
            _thisPan = p;
            _updatePan();
            _limitPan();
            if (_track) _track.channel.pan = _pan;
        }
        
        
        /** Channel effect send level for slot 1 (0:Minimum - 1:Maximum), this property can control track after play(). */
        public function get effectSend1() : Number { return _volumes[1] * 0.0078125; }
        public function set effectSend1(v:Number) : void {
            v = (v<0) ? 0 : (v>1) ? 1 : v;
            _volumes[1] = v * 128;
            _updateStreamSend(1, v);
        }
        /** Channel effect send level for slot 2 (0:Minimum - 1:Maximum), this property can control track after play(). */
        public function get effectSend2() : Number { return _volumes[2] * 0.0078125; }
        public function set effectSend2(v:Number) : void {
            v = (v<0) ? 0 : (v>1) ? 1 : v;
            _volumes[2] = v * 128;
            _updateStreamSend(2, v);
        }
        /** Channel effect send level for slot 3 (0:Minimum - 1:Maximum), this property can control track after play(). */
        public function get effectSend3() : Number { return _volumes[3] * 0.0078125; }
        public function set effectSend3(v:Number) : void {
            v = (v<0) ? 0 : (v>1) ? 1 : v;
            _volumes[3] = v * 128;
            _updateStreamSend(3, v);
        }
        /** Channel effect send level for slot 4 (0:Minimum - 1:Maximum), this property can control track after play(). */
        public function get effectSend4() : Number { return _volumes[4] * 0.0078125; }
        public function set effectSend4(v:Number) : void {
            v = (v<0) ? 0 : (v>1) ? 1 : v;
            _volumes[4] = v * 128;
            _updateStreamSend(4, v);
        }
        /** Channel pitch bend, 1 for halftone, this property can control track after play(). */
        public function get pitchBend() : Number { return _pitchBend; }
        public function set pitchBend(p:Number) : void {
            _pitchBend = p;
            if (_track) _track.pitchBend = p * 64;
        }
        
        
        /** Array of SiEffectBase to modify this sound object's output. */
        public function get effectors() : Array {
            return (_effectChain) ? _effectChain.effectList : null;
        }
        public function set effectors(effectList:Array) :void {
            if (_effectChain) {
                _effectChain.effectList = effectList;
            } else {
                if (effectList && effectList.length>0) {
                    _effectChain = EffectChain.alloc(effectList);
                }
            }
        }
        
        
        // counter to asign unique track id
        static private var _uniqueTrackID:int = 0;
        
        
        
        
    // constructor
    //----------------------------------------
        /** constructor. */
        function SoundObject(name:String = null, synth:BasicSynth = null)
        {
            this.name = name || "";
            _parent = null;
            _childDepth = 0;
            _voiceReference = new VoiceReference();
            _synthesizer = synth || _voiceReference;
            _effectChain = null;
            _track = null;
            _tracks = null;
            _fader = new Fader(null, 1);
            _volumes = new Vector.<int>(SiOPMModule.STREAM_SEND_SIZE);
            _faderVolume = 1;
            
            _note = 60;
            _length = 0;
            _delay = 0;
            _quantize = 1;
            
            _volumes[0] = 64;
            for (var i:int=1; i<SiOPMModule.STREAM_SEND_SIZE; i++) _volumes[i] = 0;
            _pan = 0;
            _mute = false;
            _pitchBend = 0;
            
            _gateTime = 0.75;
            _noteShift = 0;
            _pitchShift = 0;
            _eventMask = 0;
            _eventTriggerID = 0;
            _noteOnTrigger = 0;
            _noteOffTrigger = 0;
            
            _thisVolume = 0.5;
            _thisPan = 0;
            _thisMute = false;
            
            _trackID = (_uniqueTrackID & 0x7fff) | 0x8000;
            _uniqueTrackID++;
        }
        
        
        
        
    // settings
    //----------------------------------------
        /** Reset */
        public function reset() : void 
        {
            stop();
            
            _note = 60;
            _length = 0;
            _delay = 0;
            _quantize = 1;
            
            _fader.setFade(null, 1);
            _effectChain = null;
            _volumes[0] = 64;
            for (var i:int=1; i<SiOPMModule.STREAM_SEND_SIZE; i++) _volumes[i] = 0;
            _faderVolume = 1;
            _pan = 0;
            _mute = false;
            _pitchBend = 0;
            
            _gateTime = 0.75;
            _noteShift = 0;
            _pitchShift = 0;
            _eventMask = 0;
            _eventTriggerID = 0;
            _noteOnTrigger = 0;
            _noteOffTrigger = 0;
            
            _thisVolume = 0.5;
            _thisPan = 0;
            _thisMute = false;
        }
        
        
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
        
        
        /** Set volume by index.
         *  @param slot streaming slot number.
         *  @param volume volume (0:Minimum - 1:Maximum).
         */
        public function setVolume(slot:int, volume:Number) : void 
        {
            _volumes[slot] = (volume<0) ? 0 : (volume>1) ? 128 : (volume * 128);
        }
        
        
        /** Set fading in. 
         *  @param time fading time[sec].
         */
        public function fadeIn(time:Number) : void
        {
            var drv:SiONDriver = driver;
            if (drv) {
                if (!_fader.isActive) {
                    drv.addEventListener(SiONEvent.STREAM, _onStream);
                    drv._sion_internal::forceDispatchStreamEvent();
                }
                _fader.setFade(_fadeVolume, 0, 1, time * drv.sampleRate / drv.bufferLength);
            }
        }
        
        
        /** Set fading out.
         *  @param time fading time[sec].
         */
        public function fadeOut(time:Number) : void
        {
            var drv:SiONDriver = driver;
            if (drv) {
                if (!_fader.isActive) {
                    drv.addEventListener(SiONEvent.STREAM, _onStream);
                    drv._sion_internal::forceDispatchStreamEvent();
                }
                _fader.setFade(_fadeVolume, 1, 0, time * drv.sampleRate / drv.bufferLength);
            }
        }
        
        
        
        
    // operations
    //----------------------------------------
        /** Play sound. */
        public function play() : void
        {
            stop();
            _track = _noteOn(_note, false);
            if (_track) _synthesizer._registerTrack(_track);
        }
        
        
        /** Stop sound. */
        public function stop() : void
        {
            if (_track) {
                _synthesizer._unregisterTracks(_track);
                _track.setDisposable();
                _track = null;
                _noteOff(-1, false);
            }
            _stopEffect();
        }
        
        
        
        
    // operations
    //----------------------------------------
        /** @private [protected] driver.noteOn.
         *  @param note playing note
         *  @param isDisposable disposable flag.
         *  @return playing track
         */
        protected function _noteOn(note:int, isDisposable:Boolean) : SiMMLTrack
        {
            if (!driver) return null;
            var voice:SiONVoice = _synthesizer._synthesizer_internal::_voice, 
                bottomEC:EffectChain = _bottomEffectChain(),
                track:SiMMLTrack = driver.noteOn(note, voice, _length, _delay, _quantize, _trackID, isDisposable);
            if (_effectChain) {
                _effectChain._activateLocalEffect(_childDepth);
                _effectChain.setAllStreamSendLevels(_volumes);
            }
            if (bottomEC) {
                track.channel.masterVolume = 128;
                track.channel.setStreamBuffer(0, bottomEC.streamingBuffer);
            } else {
                track.channel.setAllStreamSendLevels(_volumes);
            }
            track.channel.pan  = _pan;
            track.channel.mute = _mute;
            track.pitchBend  = _pitchBend * 64;
            track.noteShift  = _noteShift;
            track.pitchShift = _pitchShift * 64;
            track.setEventTrigger(_eventTriggerID, _noteOnTrigger, _noteOffTrigger);
            if (voice && isNaN(voice.gateTime)) track.quantRatio = _gateTime;
            return track;
        }
        
        
        /** @private [protected] driver.noteOff()
         *  @param stopImmediately stop sound wit resetting channels process
         *  @return stopped track list
         */
        protected function _noteOff(note:int, stopImmediately:Boolean = true) : Vector.<SiMMLTrack>
        {
            if (!driver) return null;
            if (_effectChain) _effectChain._inactivateLocalEffect();
            return driver.noteOff(note, _trackID, _delay, _quantize, stopImmediately);
        }
        
        
        /** @private [protected] driver.sequenceOn()
         *  @param data sequence data
         *  @param isDisposable disposable flag
         *  @param applyLength
         *  @return vector of playing tracks
         */
        protected function _sequenceOn(data:SiONData, isDisposable:Boolean, applyLength:Boolean=true) : Vector.<SiMMLTrack>
        {
            if (!driver) return null;
            var len:Number = (applyLength) ? _length : 0;
            var voice:SiONVoice = _synthesizer._synthesizer_internal::_voice, 
                bottomEC:EffectChain = _bottomEffectChain(),
                list:Vector.<SiMMLTrack> = driver.sequenceOn(data, voice, len, _delay, _quantize, _trackID, isDisposable),
                track:SiMMLTrack, ps:int = _pitchShift * 64, pb:int = _pitchBend * 64;
            if (_effectChain) {
                _effectChain._activateLocalEffect(_childDepth);
                _effectChain.setAllStreamSendLevels(_volumes);
            }
            for each (track in list) {
                if (bottomEC) {
                    track.channel.masterVolume = 128;
                    track.channel.setStreamBuffer(0, bottomEC.streamingBuffer);
                } else {
                    track.channel.setAllStreamSendLevels(_volumes);
                }
                track.channel.pan  = _pan;
                track.channel.mute = _mute;
                track.pitchBend  = pb;
                track.noteShift  = _noteShift;
                track.pitchShift = ps;
                track.setEventTrigger(_eventTriggerID, _noteOnTrigger, _noteOffTrigger);
                if (voice && isNaN(voice.gateTime)) track.quantRatio = _gateTime;
            }
            return list;
        }
        
        
        /** @private [protected] driver.sequenceOff()
         *  @param stopImmediately stop sound wit resetting channels process
         *  @return stopped track list
         */
        protected function _sequenceOff(stopImmediately:Boolean = true) : Vector.<SiMMLTrack>
        {
            if (!driver) return null;
            if (_effectChain) _effectChain._inactivateLocalEffect();
            return driver.sequenceOff(_trackID, 0, _quantize, stopImmediately);
        }
        
        
        /** @private [protected] free effect chain if the effect list is empty */
        protected function _stopEffect() : void
        {
            if (_effectChain && _effectChain.effectList.length == 0) {
                _effectChain.free();
                _effectChain = null;
            }
        }
        
        
        /** @private [protected] update stream send level */
        protected function _updateStreamSend(streamNum:int, level:Number) : void {
            if (_track) {
                if (_effectChain) _effectChain.setStreamSend(streamNum, level);
                else _track.channel.setStreamSend(streamNum, level);
            }
        }
        
        
        
    // internals
    //----------------------------------------
        // bottom effect chain
        private function _bottomEffectChain() : EffectChain
        {
            return _effectChain || ((_parent) ? _parent._bottomEffectChain() : null);
        }
        
        
        /** @private [internal use] */
        internal function _setParent(parent:SoundObjectContainer) : void
        {
            if (_parent != null) _parent.removeChild(this);
            _parent = parent;
            _updateChildDepth();
            _updateMute();
            _updateVolume();
            _limitVolume();
            _updatePan();
            _limitPan();
        }
        
        
        /** @private [internal use] */
        internal function _updateChildDepth() : void
        {
            _childDepth = (parent) ? (parent._childDepth + 1) : 0;
        }
        
        
        /** @private [internal use] */
        internal function _updateMute() : void
        {
            if (_parent) _mute = _parent._mute || _thisMute;
            else _mute = _thisMute;
        }
        
        
        /** @private [internal use] */
        internal function _updateVolume() : void
        {
            if (_parent) _volumes[0] = _parent._volumes[0] * _thisVolume * _faderVolume;
            else _volumes[0] = _thisVolume * _faderVolume * 128;
        }
        
        
        /** @private [internal use] */
        internal function _limitVolume() : void
        {
            if (_volumes[0] < 0) _volumes[0] = 0;
            else if (_volumes[0] > 128) _volumes[0] = 128;
        }
        
        
        /** @private [internal use] */
        internal function _updatePan() : void
        {
            if (_parent) _pan = (_parent._pan + _thisPan) * 0.5;
            else _pan = _thisPan;
        }
        
        
        /** @private [internal use] */
        internal function _limitPan() : void
        {
            if (_pan < -1) _pan = -1;
            else if (_pan > 1) _pan = 1;
        }

        
        /** @private [protected] Handler for SiONEvent.STREAM */
        protected function _onStream(e:SiONEvent) : void
        {
            if (!_fader.execute()) {
                driver.removeEventListener(SiONEvent.STREAM, _onStream);
                driver._sion_internal::forceDispatchStreamEvent(false);
            }
        }
        
        
        /** @private [protected] call from fader */
        protected function _fadeVolume(v:Number) : void
        {
            _faderVolume = v;
            _updateVolume();
        }
        
        
        
        
        
    // errors
    //----------------------------------------
        /** @private [protected] not available */
        protected function _errorNotAvailable(str:String) : Error
        {
            return new Error("SoundObject; " + str + " method is not available in this object.");
        }
        
        
        /** @private [protected] Cannot change */
        protected function _errorCannotChange(str:String) : Error
        {
            return new Error("SoundObject; You can not change " + str + " property in this object.");
        }
    }
}

