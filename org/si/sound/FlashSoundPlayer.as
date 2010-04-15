//----------------------------------------------------------------------------------------------------
// Flash Media Sound player class
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound {
    import flash.events.Event;
    import flash.events.ProgressEvent;
    import flash.events.IOErrorEvent;
    import flash.net.URLRequest;
    import flash.media.Sound;
    import flash.media.SoundLoaderContext;
    import org.si.sion.*;
    //import org.si.sion.sequencer.base.*;
    import org.si.sion.sequencer.SiMMLTrack;
    import org.si.sound.synthesizers.*;
    import org.si.sound.namespaces._sound_object_internal;
    import org.si.sound.synthesizers._synthesizer_internal;
    
    
    /** @eventType flash.events.Event */
    [Event(name="complete", type="flash.events.Event")]
    /** @eventType flash.events.Event */
    [Event(name="open",     type="flash.events.Event")]
    /** @eventType flash.events.Event */
    [Event(name="id3",      type="flash.events.Event")]
    /** @eventType flash.events.IOErrorEvent */
    [Event(name="ioError",  type="flash.events.IOErrorEvent")]
    /** @eventType flash.events.ProgressEvent */
    [Event(name="progress", type="flash.events.ProgressEvent")]
     
    
    /** FlashSoundPlayer provides advanced operations of Sound class (in flash media package). */
    public class FlashSoundPlayer extends PatternSequencer
    {
    // namespace
    //----------------------------------------
        use namespace _sound_object_internal;
        
        
        
        
    // variables
    //----------------------------------------
        /** sound instance to play */
        protected var _soundData:Sound = null;
        
        /** is sound data available to play ? */
        protected var _isSoundDataAvailable:Boolean;
        
        /** is pitch controlable ? */
        protected var _isPitchContorable:Boolean;
        
        /** synthsizer to play sound */
        protected var _flashSoundOperator:IFlashSoundOperator = null;
        
        /** playing mode, 0=stopped, 1=wait for loading, 2=play as single note, 3=play by pattern sequencer */
        protected var _playingMode:int;
        
        
        
        
    // properties
    //----------------------------------------
        /** the Sequencer instance belonging to this PatternSequencer, where the sequence pattern appears. */
        public function get soundData() : Sound { return _soundData; }
        public function set soundData(s:Sound) : void {
            _soundData = s;
            if (_soundData == null) return;
            if (_soundData.bytesLoaded == _soundData.bytesTotal) _setSoundData();
            else _addAllEventListeners();
        }
        
        /** is playing ? */
        override public function get isPlaying() : Boolean { return (_playingMode != 0); }
        
        /** is pitch controlable ? */
        public function get isPitchContorable() : Boolean { return _isPitchContorable; }
        
        /** is sound data available to play ? */
        public function get isSoundDataAvailable() : Boolean { return _isSoundDataAvailable; }
        
        
        /** Voice data to play, You cannot change the voice of this sound object. */
        override public function get voice() : SiONVoice { return _synthesizer._synthesizer_internal::_voice; }
        override public function set voice(v:SiONVoice) : void { 
            throw new Error("SoundPlayer; You cannot change voice of this sound object.");
        }
        
        
        /** Synthesizer to generate sound, You cannot change the synthesizer of this sound object */
        override public function get synthesizer() : VoiceReference { return _synthesizer; }
        override public function set synthesizer(s:VoiceReference) : void {
            throw new Error("SoundPlayer; You cannot change synthesizer of this sound object.");
        }
        
        
        
        
        
    // constructor
    //----------------------------------------
        /** constructor 
         *  @param soundData flash.media.Sound instance to control.
         *  @param isPitchControlable pitch controlable flag. Set true to control pitch, false to assign Sound for each note. 
         */
        function FlashSoundPlayer(soundData:Sound = null, isPitchContorable:Boolean = false)
        {
            super(68, 128, 0);
            name = "SoundPlayer";
            _isPitchContorable = isPitchContorable;
            _isSoundDataAvailable = false;
            _playingMode = 0;
            _flashSoundOperator = (_isPitchContorable) ? (new PCMSynth()) : (new SamplerSynth());
            _synthesizer = _flashSoundOperator;
            this.soundData = soundData;
        }
        
        
        
        
    // operations
    //----------------------------------------
        /** start sequence */
        override public function play() : void
        {
            _playingMode = 1;
            if (_isSoundDataAvailable) _playSound();
        }
        
        
        /** stop sequence */
        override public function stop() : void
        {
            switch (_playingMode) {
            case 2:
                if (_track) {
                    _synthesizer._unregisterTracks(_track);
                    _track.setDisposable();
                    _track = null;
                    _noteOff(-1, false);
                }
                _stopEffect();
                break;
            case 3:
                super.stop();
                break;
            }
            _playingMode = 0;
        }
        
        
        /** load sound from url */
        public function load(url:URLRequest, context:SoundLoaderContext=null) : void
        {
            _soundData = new Sound(url, context);
            _addAllEventListeners();
        }
        
        
        
        
    // internal
    //----------------------------------------
        private function _setSoundData() : void 
        {
            _isSoundDataAvailable = true;
            _flashSoundOperator.setSound(_soundData);
            if (_playingMode == 1) _playSound();
        }
        
        
        private function _playSound() : void
        {
            if (_sequencer.pattern != null) {
                // play by PatternSequencer
                _playingMode = 3;
                super.play();
            } else {
                // play as single note
                _playingMode = 2;
                stop();
                _track = _noteOn(_note, false);
                if (_track) _synthesizer._registerTrack(_track);
            }
        }
        
        
        private function _addAllEventListeners() : void
        {
            _soundData.addEventListener(Event.COMPLETE, _onComplete);
            _soundData.addEventListener(Event.ID3, _onID3);
            _soundData.addEventListener(IOErrorEvent.IO_ERROR, _onIOError);
            _soundData.addEventListener(Event.OPEN, _onOpen);
            _soundData.addEventListener(ProgressEvent.PROGRESS, _onProgress);
        }
        
        
        private function _removeAllEventListeners() : void
        {
            _soundData.removeEventListener(Event.COMPLETE, _onComplete);
            _soundData.removeEventListener(Event.ID3, _onID3);
            _soundData.removeEventListener(IOErrorEvent.IO_ERROR, _onIOError);
            _soundData.removeEventListener(Event.OPEN, _onOpen);
            _soundData.removeEventListener(ProgressEvent.PROGRESS, _onProgress);
        }
        
        
        private function _onComplete(event:Event) : void
        {
            _removeAllEventListeners();
            _setSoundData();
            dispatchEvent(new Event(Event.COMPLETE));
        }
        
        
        private function _onID3(event:Event) : void
        {
            dispatchEvent(new Event(Event.ID3));
        }
        
        
        private function _onIOError(event:IOErrorEvent) : void
        {
            _removeAllEventListeners();
            dispatchEvent(new IOErrorEvent(IOErrorEvent.IO_ERROR, false, false, event.text));
        }
        
        
        private function _onOpen(event:Event) : void
        {
            dispatchEvent(new Event(Event.OPEN));
        }
        
        
        private function _onProgress(event:ProgressEvent) : void
        {
            dispatchEvent(new ProgressEvent(ProgressEvent.PROGRESS, false, false, event.bytesLoaded, event.bytesTotal));
        }
    }
}

