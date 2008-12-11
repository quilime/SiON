//----------------------------------------------------------------------------------------------------
// SiOPM driver
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------




package org.si.sound {
    import flash.errors.*;
    import flash.events.*;
    import flash.media.Sound;
    import flash.media.SoundChannel;
    import flash.media.SoundTransform;
    import flash.display.Sprite;
    import flash.utils.getTimer;
    import flash.utils.ByteArray;

    import org.si.utils.SLLint;
    import org.si.utils.SLLNumber;
    import org.si.sound.driver.SiMMLSequencer;
    import org.si.sound.driver.SiMMLSequencerTrack;
    import org.si.sound.module.SiOPMChannelParam;
    
    
    
    
    /** SiOPM driver class.<br/>
     *  -- BASIC USAGE --<br/>
     *  1) Create new SiOPMDriver.<br/>
     *  2) addChild the instance of SiOPMDriver onto the stage or stage's descendant.<br/>
     *  3) addEventListner(SiOPMEvent.COMPILE_COMPLETE) to catch the finished timing of compile, and call compile("mmlString").<br/>
     *  4) After the compiling (lets say, in the callback of the SiOPMEvent.COMPILE_COMPLETE event), call play() to start playing sound.<br/>
     *  5) Call stop() to stop the sound.<br/>
     */
    public class SiOPMDriver extends Sprite
    {
    // constants
    //----------------------------------------
        static public const VERSION:String = "0.4.1";
        
        
        protected const NO_LISTEN:int = 0;
        protected const LISTEN_COMPILE:int = 1;
        protected const LISTEN_PROCESS:int = 2;
        
        protected const TIME_AVARAGING_SIZE:int = 8;
        
        
        
        
    // valiables
    //----------------------------------------
        /** SiMMLSequencer instance. */
        public var sequencer:SiMMLSequencer;
        
        protected var _data:SiOPMData;            // data to compile or process
        protected var _mmlString:String;          // mml string of previous compiling
        protected var _sound:Sound;               // sound stream instance
        protected var _soundChannel:SoundChannel;     // sound channel instance
        protected var _soundTransform:SoundTransform; // sound transform
        
        protected var _freqRatio:int;             // module output frequency ratio (44100 or 22050)
        protected var _bufferSize:int;            // module and streaming buffer size (8192, 4096 or 2048)
        protected var _throwErrorEvent:Boolean;   // true; throw ErrorEvent, false; throw Error
        
        protected var _compileInterval:int        // interrupting interval in compile
        protected var _compileProgress:Number;    // progression of compile on this que
        protected var _isPaused:Boolean;          // flag to pause
        protected var _position:Number;           // start position [ms]
        
        protected var _timeCompile:int;           // total compile time.
        protected var _timeProcess:int;           // averge time process in 1sec.
        protected var _timeProcessTotal:int;      // total processing time in last 8 bufferings.
        protected var _timeProcessData:SLLint;    // processing time data of last 8 bufferings.
        protected var _timeProcessAveRatio:Number;// number to averaging _timeProcessTotal
        protected var _timePrevStream:int;        // previous streaming time.
        protected var _latency:Number;            // streaming latency [ms]
        
        protected var _listenEvent:int;           // current lintening event
        
        static protected var _compileQue:Vector.<SiOPMCompileQue> = null;   // compiling que
        
        
        
        
    // properties
    //----------------------------------------
        // data
        /** MML string. This property is only available during compile. */
        public function get mmlString() : String { return _mmlString; }
        
        /** Data to compile and process. */
        public function get data() : SiOPMData { return _data; }
        
        /** Sound instance. */
        public function get sound() : Sound { return _sound; }
        
        /** Sound channel. This property is only available during playing sound. */
        public function get soundChannel() : SoundChannel { return _soundChannel; }
        
        
        // paramteters
        /** Track count. This value is only available after play(). */
        public function get trackCount() : int { return sequencer.trackCount; }
        
        /** Sound volume. */
        public function get volume() : Number       { return _soundTransform.volume; }
        public function set volume(v:Number) : void {
            _soundTransform.volume = v; 
            if (_soundChannel) _soundChannel.soundTransform = _soundTransform;
        }
        
        /** Sound panning. */
        public function get pan() : Number       { return _soundTransform.pan; }
        public function set pan(p:Number) : void {
            _soundTransform.pan = p; 
            if (_soundChannel) _soundChannel.soundTransform = _soundTransform;
        }
        
        
        // measured time
        /** total compiling time. [ms] */
        public function get compileTime() : int { return _timeCompile; }
        
        /** average processing time per 1sec. [ms] */
        public function get processTime() : int { return _timeProcess; }
        
        /** compiling progression in one que. 0=start -> 1=finish. */
        public function get compileProgress() : Number { return _compileProgress; }
        
        /** compiling que length. */
        public function get compileQueLength() : int { return _compileQue.length; }
        
        /** streaming latency */
        public function get latency() : Number { return _latency; }
        
        
        // flag
        /** Is compiling ? */
        public function get isCompiling() : Boolean { return (_compileProgress>0 && _compileProgress<1); }
        
        /** Is playing sound ? */
        public function get isPlaying() : Boolean { return (_soundChannel != null); }
        
        
        // operation
        /** Buffering position[ms] on mml data. */
        public function get position() : Number {
            return sequencer.processedSampleCount * 1000 / _freqRatio;
        }
        public function set position(pos:Number) : void {
            _position = pos;
            if (sequencer.isReadyToProcess) {
                sequencer.resetAllTracks();
                sequencer.dummyProcess(_position * _freqRatio * 0.001);
            }
        }
        
        
        
        
    // constructor
    //----------------------------------------
        /** Create driver to manage the SiOPM module, compiler and sequencer.
         *  @param channel Channel count. 1 or 2 is available.
         *  @param sampleRate Sampling ratio of wave. 22050 or 44100 is available.
         *  @param bitRate Bit ratio of wave. 8 or 16 is available.
         *  @param bufferSize Buffer size of sound stream. 8192, 4096 or 2048 is available, but no check.
         *  @param throwErrorEvent true; throw ErrorEvent when it errors. false; throw Error when it errors.
         */
        function SiOPMDriver(channelCount:int=2, sampleRate:int=44100, bitRate:int=16, bufferSize:int=8192, throwErrorEvent:Boolean=true)
        {
            if (!_compileQue) _compileQue = new Vector.<SiOPMCompileQue>();
            
            sequencer = new SiMMLSequencer();
            _sound = new Sound();
            _soundTransform = new SoundTransform();

            // initialize
            _throwErrorEvent = throwErrorEvent;
            
            sequencer.initialize(channelCount, sampleRate, bitRate);
            _bufferSize = bufferSize;
            _freqRatio  = sampleRate;
            _listenEvent = NO_LISTEN;
            
            _soundTransform.volume = 1;
            _soundTransform.pan = 0;
            _position = 0;
            
            _compileInterval = 0;
            _compileProgress = 0;
            
            _timeCompile = 0;
            _timeProcessTotal = 0;
            _timeProcessData = SLLint.allocRing(TIME_AVARAGING_SIZE);
            _timeProcessAveRatio = _freqRatio / (_bufferSize * TIME_AVARAGING_SIZE);
            _timePrevStream = 0;
            _latency = 0;
            
            _mmlString    = null;
            _data         = null;
            _soundChannel = null;
            
            // register sound streaming function 
            _sound.addEventListener("sampleData", _streaming);
        }
        
        
        
        
    // operations for data
    //----------------------------------------
        /** Compile the MML string. 
         *  After calling this function, the SiOPMEvent.COMPILE_PROGRESS, SiOPMEvent.COMPILE_COMPLETE and ErrorEvent.ERROR events will be dispatched.<br/>
         *  The SiOPMEvent.COMPILE_PROGRESS is dispatched when it's compiling in the interval of the argument "interval".<br/>
         *  The SiOPMEvent.COMPILE_COMPLETE is dispatched when the compile is finished successfully.<br/>
         *  The ErrorEvent.ERROR is dispatched when some error appears during the compile.<br/>
         *  @param mml MML string to compile.
         *  @param interavl Interval to interrupt compiling [ms]. The value of 0 sets no interruption and returns SiOPMData immediately.
         *  @param data SiOPMData to compile. The SiOPMDriver creates new SiOPMData When this argument is null.
         *  @return This function returns compiled data only when the argument "interval" set to 0, and returns null in other case.
         */
        public function compile(mml:String, interval:int=0, data:SiOPMData=null) : SiOPMData
        {
            // stop sound
            stop();
            
            try {
                if (interval > 0) {
                     // push compile que
                    _pushCompileQue(mml, interval, data);
                    _compile_addAllEventListners();
                } else {
                    // compile immediately
                    var t:int = getTimer();
                    _prepareCompile(mml, 0, data);
                    _compileProgress = sequencer.compile(0);
                    _timeCompile += getTimer() - t;
                    return _data;
                }
            } catch(e:Error) {
                // error
                if (_throwErrorEvent) dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, e.message));
                else throw e;
            }
            
            return null;
        }
        
        
        
        
    // operations for sound
    //----------------------------------------
        /** Play sound.
         *  @param data Data to play. You can pass null when resume after pause.
         */
        public function play(data:SiOPMData=null) : void
        {
            if (_isPaused) {
                _isPaused = false;
            } else 
            if (data) {
                _data = data;
                if (_data) {
                    // stop sound
                    stop();
                    
                    // preparation
                    sequencer.prepareProcess(_data, _bufferSize);
                    if (_position > 0) { sequencer.dummyProcess(_position * _freqRatio * 0.001); }
                    
                    // dispatch streaming start event
                    dispatchEvent(new SiOPMEvent(SiOPMEvent.STREAM_START, this));
                    
                    // start stream
                    _process_addAllEventListners();
                    _soundChannel = _sound.play();
                    _soundChannel.soundTransform = _soundTransform;
                    
                    // initialize
                    _timeProcessTotal = 0;
                    for (var i:int=0; i<TIME_AVARAGING_SIZE; i++) {
                        _timeProcessData.i = 0;
                        _timeProcessData = _timeProcessData.next;
                    }
                    _isPaused = false;
                }
            }
        }
        
        
        /** Stop sound. */
        public function stop() : void
        {
            _removeAllEventListners();
            if (_soundChannel) {
                _soundChannel.stop();
                _soundChannel = null;
                _latency = 0;
                // dispatch streaming stop event
                dispatchEvent(new SiOPMEvent(SiOPMEvent.STREAM_STOP, this));
            }
        }
        
        
        /** Pause sound. You can resume it by play() without any arguments. */
        public function pause() : void
        {
            _isPaused = true;
        }
        
        
        /** Get track instance. This function only is available after play().
         *  Most common timing to call is in the event handler of SiOPMEvent.STREAM_START.
         *  @param trackIndex Track index. This must be less than SiMMLDriver.trackCount.
         *  @return Track instance. When the trackIndex is out of range, returns null.
         */
        public function getTrack(trackIndex:int) : SiMMLSequencerTrack
        {
            return sequencer.getTrack(trackIndex);
        }
        
        
        
        
    // MIDI interface
    //----------------------------------------
        /** Start null stream */
        public function startStream() : void
        {
            // stop sound
            stop();
            
            // preparation
            sequencer.prepareProcess(null, _bufferSize);
            
            // dispatch streaming start event
            dispatchEvent(new SiOPMEvent(SiOPMEvent.STREAM_START, this));
            
            // start stream
            _process_addAllEventListners();
            _soundChannel = _sound.play();
            _soundChannel.soundTransform = _soundTransform;
            
            // initialize
            _timeProcessTotal = 0;
            for (var i:int=0; i<TIME_AVARAGING_SIZE; i++) {
                _timeProcessData.i = 0;
                _timeProcessData = _timeProcessData.next;
            }
            _isPaused = false;
        }
        
        
        /** Note on. This function only is available after play().
         *  @param channel Channel to switch key on.
         *  @param note Note number to switch key on.
         *  @return The track switched key key on. Returns null when tracks are overflowed.
         */
        public function noteOn(note:int, param:SiOPMChannelParam=null) : SiMMLSequencerTrack
        {
            var trk:SiMMLSequencerTrack = sequencer.getFreeControlableTrack() || sequencer.newControlableTrack();
            if (trk) {
                if (param) trk.channel.setSiOPMChannelParam(param, false);
                trk.keyOnDelay = (_timePrevStream - getTimer()) * 44.1;
                trk.keyOn(note);
            }
            return trk;
        }
        
        
        /** Note off. This function only is available after play(). 
         *  @param channel Channel to switch key off.
         *  @param note Note number to switch key off.
         *  @return The track switched key off. Returns null when no tracks run specifyed note.
         */
        public function noteOff(note:int) : SiMMLSequencerTrack
        {
            var trk:SiMMLSequencerTrack = sequencer.findControlableTrack(note);
            if (trk) trk.keyOff();
            return trk;
        }
        
        
        
        
    // operate event listner
    //----------------------------------------
        // add all event listners
        private function _compile_addAllEventListners() : void
        {
            addEventListener(Event.ENTER_FRAME, _compile_onEnterFrame);
            _listenEvent = LISTEN_COMPILE;
        }
        
        
        // add all event listners
        private function _process_addAllEventListners() : void
        {
            addEventListener(Event.ENTER_FRAME, _process_onEnterFrame);
            _listenEvent = LISTEN_PROCESS;
        }
        
        
        // remove all event listners
        private function _removeAllEventListners() : void
        {
            switch (_listenEvent) {
            case LISTEN_COMPILE:
                removeEventListener(Event.ENTER_FRAME, _compile_onEnterFrame);
                break;
            case LISTEN_PROCESS:
                removeEventListener(Event.ENTER_FRAME, _process_onEnterFrame);
                break;
            }
            _listenEvent = NO_LISTEN;
        }
        
        
        
        
    // compile
    //----------------------------------------
        // Stac que
        private function _pushCompileQue(mml:String, interval:int, data:SiOPMData) : void
        {
            try {
                if (isCompiling) {
                    _compileQue.push(new SiOPMCompileQue(mml, interval, data));
                } else {
                    _prepareCompile(mml, interval, data);
                }
            } catch(e:Error) {
                // error
                if (_throwErrorEvent) dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, e.message));
                else throw e;
            }
        }
        
        
        // Compile staced que
        private function _execCompileQue() : Boolean
        {
            if (_compileQue.length == 0) return false;
            var que:SiOPMCompileQue = _compileQue.shift();
            _prepareCompile(que.mml, que.interval, que.data);
            return true;
        }
        
        
        // prepare to compile
        private function _prepareCompile(mml:String, interval:int, data:SiOPMData) : void
        {
            _data = data || new SiOPMData();
            _mmlString = mml;
            _compileInterval = interval;
            sequencer.prepareCompile(_data, _mmlString);
            _compileProgress = 0.01;
        }
        
        
        // on enterFrame
        private function _compile_onEnterFrame(e:Event) : void
        {
            try {
                // compile
                var t:int = getTimer();
                _compileProgress = sequencer.compile(_compileInterval);
                _timeCompile += getTimer() - t;
                
                if (_compileProgress == 1) {
                    // complete
                    dispatchEvent(new SiOPMEvent(SiOPMEvent.COMPILE_COMPLETE, this));
                    // execute next que
                    if (!_execCompileQue()) {
                        // finished
                        _removeAllEventListners();
                        _data = null;
                        _mmlString = null;
                    }
                } else {
                    // progress
                    dispatchEvent(new SiOPMEvent(SiOPMEvent.COMPILE_PROGRESS, this));
                }
            } catch (e:Error) {
                // error
                _removeAllEventListners();
                if (_throwErrorEvent) dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, e.message));
                else throw e;
            }
        }
        
        
        
        
    // process
    //----------------------------------------
        // on enterFrame
        private function _process_onEnterFrame(e:Event) : void
        {
        }
        
        
        // on sampleData
        private function _streaming(e:SampleDataEvent) : void
        {
            var buf:ByteArray = e.data,
                dat:SLLNumber = sequencer.module.outputBuffer, 
                imax:int      = sequencer.module.bufferLength, 
                i:int;

            // calculate latency (0.022675736961451247 = 1/44.1)
            if (_soundChannel) {
                _latency = e.position * 0.022675736961451247 - _soundChannel.position;
            }
            
            try {
                if (_isPaused) {
                    // paused -> 0 filling
                    for (i=0; i<imax; i++) {
                        buf.writeFloat(0);
                        buf.writeFloat(0);
                    }
                } else {
                    // processing
                    var t:int = getTimer();
                    sequencer.process();
                    
                    // calculate the average of processing time
                    _timePrevStream = t;
                    _timeProcessTotal -= _timeProcessData.i;
                    _timeProcessData.i = getTimer() - t;
                    _timeProcessTotal += _timeProcessData.i;
                    _timeProcessData   = _timeProcessData.next;
                    _timeProcess = _timeProcessTotal * _timeProcessAveRatio;
                    
                    // write samples
                    for (i=0; i<imax; i++) {
                        buf.writeFloat(dat.n);
                        buf.writeFloat(dat.next.n);
                        dat.n = 0;
                        dat.next.n = 0;
                        dat = dat.next.next;
                    }
                    
                    // dispatch streaming event
                    dispatchEvent(new SiOPMEvent(SiOPMEvent.STREAM, this, buf));
                }
            } catch (e:Error) {
                // error
                _removeAllEventListners();
                if (_throwErrorEvent) dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, e.message));
                else throw e;
            }
        }
    }
}




import org.si.sound.SiOPMData;

class SiOPMCompileQue
{
    public var mml:String;
    public var interval:int;
    public var data:SiOPMData;
    
    function SiOPMCompileQue(mml_:String, interval_:int, data_:SiOPMData) 
    {
        mml = mml_;
        interval = interval_;
        data = data_ || new SiOPMData();
    }
}


