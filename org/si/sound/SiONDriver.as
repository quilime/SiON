//----------------------------------------------------------------------------------------------------
// SiON driver
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------




package org.si.sound {
    import flash.errors.*;
    import flash.events.*;
    import flash.media.Sound;
    import flash.media.SoundChannel;
    import flash.media.SoundTransform;
    import flash.display.*;
    import flash.utils.getTimer;
    import flash.utils.ByteArray;

    import org.si.utils.SLLint;
    import org.si.utils.SLLNumber;
    import org.si.sound.mml.SiMMLSequencer;
    import org.si.sound.mml.SiMMLTrack;
    import org.si.sound.mml.SiMMLEnvelopTable;
    import org.si.sound.mml.SiMMLTable;
    import org.si.sound.module.SiOPMTable;
    import org.si.sound.module.SiOPMModule;
    import org.si.sound.module.SiOPMChannelParam;
    import org.si.sound.effect.SiEffectModule;
    import org.si.sound.events.*;
    
    
    
    
    /** SiON driver class.<br/>
     * @see SiONData
     * @see SiONToneSetting
     * @see org.si.sound.events.SiONEvent
     * @see org.si.sound.events.SiONTrackEvent
     * @see org.si.sound.module.SiOPMModule
     * @see org.si.sound.mml.SiMMLSequencer
     * @see org.si.sound.effect.SiEffectModule
@example 1) The simplest sample. Create new instance and call play with MML string.<br/>
<listing version="3.0">
// create driver instance.
public var driver = new SiONDriver();
...
// call play() with mml string whenever you want to play sound.
driver.play("t100 l8 [ ccggaag4 ffeeddc4 | [ggffeed4]2 ]2");
</listing>
     */
    public class SiONDriver extends Sprite
    {
    // constants
    //----------------------------------------
        /** version number */
        static public const VERSION:String = "0.5.1";
        
        
        // event listener type
        private const NO_LISTEN:int = 0;
        private const LISTEN_QUEUE:int = 1;
        private const LISTEN_PROCESS:int = 2;
        
        // time avaraging sample count
        private const TIME_AVARAGING_COUNT:int = 8;
        
        
        
        
    // valiables
    //----------------------------------------
        /** SiOPM sound module. */
        public var module:SiOPMModule;
        
        /** effector module. */
        public var effector:SiEffectModule;
        
        /** mml sequencer module. */
        public var sequencer:SiMMLSequencer;
        
        
        // private:
        private var _data:SiONData;             // data to compile or process
        private var _mmlString:String;          // mml string of previous compiling
        private var _sound:Sound;               // sound stream instance
        private var _soundChannel:SoundChannel;     // sound channel instance
        private var _soundTransform:SoundTransform; // sound transform
        
        private var _channelCount:int;          // module output channels (1 or 2)
        private var _sampleRate:int;            // module output frequency ratio (44100 or 22050)
        private var _bitRate:int;               // module output bitrate (0 or 8 or 16)
        private var _bufferLength:int;          // module and streaming buffer size (8192, 4096 or 2048)
        private var _debugMode:Boolean;         // true; throw Error, false; throw ErrorEvent
        private var _dispatchStreamEvent:Boolean; // dispatch steam event
        private var _cannotChangeBPM:Boolean;     // internal flag not to change bpm

        private var _queueInterval:int;         // interupting interval to execute queued jobs
        private var _queueLength:int;           // queue length to execute
        private var _jobProgress:Number;        // progression of current job
        private var _currentJob:int;            // current job 0=no job, 1=compile, 2=render
        
        
        private var _isPaused:Boolean;          // flag to pause
        private var _position:Number;           // start position [ms]
        
        private var _triggerEventQueue:Vector.<SiONTrackEvent>;
        
        private var _renderBuffer:Vector.<Number>;  // rendering buffer
        private var _renderBufferIndex:int;         // rendering buffer writing index
        private var _renderBufferSizeMax:int;       // maximum value of rendering buffer size
        
        private var _timeCompile:int;           // previous compiling time.
        private var _timeRender:int;            // previous rendering time.
        private var _timeProcess:int;           // averge processing time in 1sec.
        private var _timeProcessTotal:int;      // total processing time in last 8 bufferings.
        private var _timeProcessData:SLLint;    // processing time data of last 8 bufferings.
        private var _timeProcessAveRatio:Number;// number to averaging _timeProcessTotal
        private var _timePrevStream:int;        // previous streaming time.
        private var _latency:Number;            // streaming latency [ms]
        private var _prevFrameTime:int;         // previous frame time
        private var _frameRate:int;             // frame rate
        
        private var _eventListenerPrior:int;    // event listeners priority
        private var _listenEvent:int;           // current lintening event
        
        static private var _jobQueue:Vector.<SiONDriverJob> = null;   // compiling/rendering jobs queue
        
        
        
        
    // properties
    //----------------------------------------
        // data
        /** MML string (this property is only available during compile). */
        public function get mmlString() : String { return _mmlString; }
        
        /** Data to compile, render and process. */
        public function get data() : SiONData { return _data; }
        
        /** Sound instance. */
        public function get sound() : Sound { return _sound; }
        
        /** Sound channel. This property is only available during playing sound. */
        public function get soundChannel() : SoundChannel { return _soundChannel; }
        
        
        // paramteters
        /** Track count, this value is only available after play(). */
        public function get trackCount() : int { return sequencer.tracks.length; }
        
        /** Streaming buffer length. */
        public function get bufferLength() : int { return _bufferLength; }
        
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
        /** previous compiling time [ms]. */
        public function get compileTime() : int { return _timeCompile; }
        
        /** previous rendering time [ms]. */
        public function get renderTime() : int { return _timeRender; }
        
        /** average processing time in 1sec [ms]. */
        public function get processTime() : int { return _timeProcess; }
        
        /** progression of current compiling/rendering (0=start -> 1=finish). */
        public function get jobProgress() : Number { return _jobProgress; }
        
        /** progression of all queued jobs (0=start -> 1=finish). */
        public function get jobQueueProgress() : Number {
            if (_queueLength == 0) return 1;
            return (_queueLength - _jobQueue.length - 1 + _jobProgress) / _queueLength;
        }
        
        /** compiling/rendering jobs queue length. */
        public function get jobQueueLength() : int { return _jobQueue.length; }
        
        /** streaming latency [ms]. */
        public function get latency() : Number { return _latency; }
        
        
        // flags
        /** Is job executing ? */
        public function get isJobExecuting() : Boolean { return (_jobProgress>0 && _jobProgress<1); }
        
        /** Is playing sound ? */
        public function get isPlaying() : Boolean { return (_soundChannel != null); }
        
        
        // operation
        /** Buffering position[ms] on mml data. */
        public function get position() : Number {
            return sequencer.processedSampleCount * 1000 / _sampleRate;
        }
        public function set position(pos:Number) : void {
            _position = pos;
            if (sequencer.isReadyToProcess) {
                sequencer.resetAllTracks();
                sequencer.dummyProcess(_position * _sampleRate * 0.001);
            }
        }
        
        /** Beat par minute. */
        public function get bpm() : Number {
            return (sequencer.isReadyToProcess) ? sequencer.bpm : sequencer.setting.defaultBPM;
        }
        public function set bpm(t:Number) : void {
            if (sequencer.isReadyToProcess) {
                if (_cannotChangeBPM) throw errorCannotChangeBPM();
                sequencer.bpm = t;
            } else {
                sequencer.setting.defaultBPM = t;
            }
        }
        
        /** Debug mode, true; throw Error / false; throw ErrorEvent when error appears. */
        public function get debugMode() : Boolean { return _debugMode; }
        public function set debugMode(mode:Boolean) : void { _debugMode = mode; }
        
        
        
        
    // constructor
    //----------------------------------------
        /** Create driver to manage the sound module, sequencer and effectors.
         *  @param bufferLength Buffer size of sound stream. 8192, 4096 or 2048 is available, but no check.
         *  @param channel Channel count. 1 or 2 is available.
         *  @param sampleRate Sampling ratio of wave. 22050 or 44100 is available.
         *  @param bitRate Bit ratio of wave. 0, 8 or 16 is available. 0 means float value [-1 to 1].
         *  @param frameRate frame rate of stage.
         */
        function SiONDriver(bufferLength:int=2048, channelCount:int=2, sampleRate:int=44100, bitRate:int=0)
        {
            if (!_jobQueue) _jobQueue = new Vector.<SiONDriverJob>();
            
            module = new SiOPMModule();
            effector = new SiEffectModule(module);
            sequencer = new SiMMLSequencer(module, _callbackEventTriggerOn, _callbackEventTriggerOff);
            _sound = new Sound();
            _soundTransform = new SoundTransform();

            // initialize
            _channelCount = channelCount;
            _sampleRate = 44100; // sampleRate; 44100 is only available now.
            _bitRate = bitRate;
            _bufferLength = bufferLength;
            _listenEvent = NO_LISTEN;
            _dispatchStreamEvent = false;
            _cannotChangeBPM = false;
            _debugMode = false;
            
            _soundTransform.volume = 1;
            _soundTransform.pan = 0;
            _position = 0;
            
            _eventListenerPrior = 1;
            _triggerEventQueue = new Vector.<SiONTrackEvent>();
            
            _queueInterval = 500;
            _jobProgress = 0;
            _currentJob = 0;
            _queueLength = 0;
            
            _timeCompile = 0;
            _timeProcessTotal = 0;
            _timeProcessData = SLLint.allocRing(TIME_AVARAGING_COUNT);
            _timeProcessAveRatio = _sampleRate / (_bufferLength * TIME_AVARAGING_COUNT);
            _timePrevStream = 0;
            _latency = 0;
            _prevFrameTime = 0;
            _frameRate = 1;
            
            _mmlString    = null;
            _data         = null;
            _soundChannel = null;
            
            // register sound streaming function 
            _sound.addEventListener("sampleData", _streaming);
        }
        
        
        
        
    // interfaces for data preparation
    //----------------------------------------
        /** Compile MML string immeriately. 
         *  @param mml MML string to compile.
         *  @param data SiONData to compile. The SiONDriver creates new SiONData instance when this argument is null.
         *  @return Compiled data.
         */
        public function compile(mml:String, data:SiONData=null) : SiONData
        {
            try {
                // stop sound
                stop();
                
                // compile immediately
                var t:int = getTimer();
                _prepareCompile(mml, data);
                _jobProgress = sequencer.compile(0);
                _timeCompile = getTimer() - t;
                _mmlString = null;
            } catch(e:Error) {
                // error
                if (_debugMode) throw e;
                else dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, e.message));
            }
            
            return _data;
        }
        
        
        /** Push queue job to compile MML string. Start compiling after calling startQueue.<br/>
         *  @param mml MML string to compile.
         *  @param data SiONData to compile.
         *  @return Queue length.
         *  @see #startQueue()
         */
        public function compileQueue(mml:String, data:SiONData) : int
        {
            if (mml == null || data == null) return _jobQueue.length;
            return _jobQueue.push(new SiONDriverJob(mml, null, data));
        }
        
        
        
        
    // interfaces for sound rendering
    //----------------------------------------
        /** Render sound immeriately.
         *  @param data SiONData or mml String to play.
         *  @param renderBuffer Rendering target. null to create new buffer. The length of renderBuffer limits rendering length except for 0.
         *  @param resetEffector reset all effectors before play data.
         *  @return rendered data.
         */
        public function render(data:*, renderBuffer:Vector.<Number>=null, resetEffector:Boolean=true) : Vector.<Number>
        {
            try {
                // stop sound
                stop();
                
                // rendering immediately
                var t:int = getTimer();
                if (resetEffector) effector.initialize();
                _prepareRender(data, renderBuffer);
                while(true) { if (_rendering()) break; }
                _timeRender = getTimer() - t;
            } catch (e:Error) {
                // error
                _removeAllEventListners();
                if (_debugMode) throw e;
                else dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, e.message));
            }
            
            return _renderBuffer;
        }
        
        
        /** Push queue job to render sound. Start rendering after calling startQueue.<br/>
         *  @param data SiONData or mml String to render.
         *  @param renderBuffer Rendering target. The length of renderBuffer limits rendering length except for 0.
         *  @return Queue length.
         *  @see #startQueue()
         */
        public function renderQueue(data:*, renderBuffer:Vector.<Number>) : int
        {
            if (data == null || renderBuffer == null) return _jobQueue.length;
            
            if (data is String) {
                var compiled:SiONData = new SiONData();
                _jobQueue.push(new SiONDriverJob(data as String, null, compiled));
                return _jobQueue.push(new SiONDriverJob(null, renderBuffer, compiled));
            } else 
            if (data is SiONData) {
                return _jobQueue.push(new SiONDriverJob(null, renderBuffer, data as SiONData));
            }
            
            var e:Error = errorDataIncorrect();
            if (_debugMode) throw e;
            else dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, e.message));
            return _jobQueue.length;
        }
        
        
        
        
    // interfaces for jobs queue
    //----------------------------------------
        /** Execute all elements of queue pushed by compileQueue and renderQueue.
         *  After calling this function, the SiONEvent.QUEUE_PROGRESS, SiONEvent.QUEUE_COMPLETE and ErrorEvent.ERROR events will be dispatched.<br/>
         *  The SiONEvent.QUEUE_PROGRESS is dispatched when it's executing queued job.<br/>
         *  The SiONEvent.QUEUE_COMPLETE is dispatched when finish all queued jobs.<br/>
         *  The ErrorEvent.ERROR is dispatched when some error appears during the compile.<br/>
         *  @param interval Interupting interval
         *  @return Queue length.
         *  @see #compileQueue()
         *  @see #renderQueue()
         */
        public function startQueue(interval:int=500) : int
        {
            stop();
            _queueLength = _jobQueue.length;
            if (_jobQueue.length > 0) {
                _queueInterval = interval;
                _executeNextJob();
                _queue_addAllEventListners();
            }
            return _queueLength;
        }
        
        
        
        
    // interfaces for sound streaming
    //----------------------------------------
        /** Play sound.
         *  @param data SiONData or mml String to play. You can pass null when resume after pause or streaming without any data.
         *  @param resetEffector reset all effectors before play data.
         *  @return SoundChannel instance to play data. This instance is same as soundChannel property.
         *  @see #soundChannel
         */
        public function play(data:*=null, resetEffector:Boolean=true) : SoundChannel
        {
            try {
                if (_isPaused) {
                    _isPaused = false;
                } else {
                    // stop sound
                    stop();
                    
                    // preparation
                    if (resetEffector) effector.initialize();
                    _prepareProcess(data);
                    
                    // dispatch streaming start event
                    var event:SiONEvent = new SiONEvent(SiONEvent.STREAM_START, this, null, true);
                    dispatchEvent(event);
                    if (event.isDefaultPrevented()) return null;   // canceled
                    
                    // set position
                    if (_data && _position > 0) { sequencer.dummyProcess(_position * _sampleRate * 0.001); }
                    
                    // start stream
                    _process_addAllEventListners();
                    _soundChannel = _sound.play();
                    _soundChannel.soundTransform = _soundTransform;
                    
                    // initialize
                    _timeProcessTotal = 0;
                    for (var i:int=0; i<TIME_AVARAGING_COUNT; i++) {
                        _timeProcessData.i = 0;
                        _timeProcessData = _timeProcessData.next;
                    }
                    _isPaused = false;
                }
            } catch(e:Error) {
                // error
                if (_debugMode) throw e;
                else dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, e.message));
            }
            
            return _soundChannel;
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
                dispatchEvent(new SiONEvent(SiONEvent.STREAM_STOP, this));
            }
        }
        
        
        /** Pause sound. You can resume it by play() without any arguments. */
        public function pause() : void
        {
            _isPaused = true;
        }
        
        
        
        
    // Interface for data register
    //----------------------------------------
        /** Set wave table data refered by %4.
         *  @param index wave table number.
         *  @param table wave shape vector ranges in -1 to 1.
         */
        public function setWaveTable(index:int, table:Vector.<Number>) : void
        {
            var len:int, bits:int=-1;
            for (len=table.length; len>0; len>>=1) bits++;
            if (bits<2) return;
            var serialized:Vector.<int> = SiONUtil.serializeVectorPCM(table, new Vector.<int>());
            serialized.length = 1<<bits;
            SiOPMTable.registerWaveTable(index, serialized, bits);
        }
        
        
        /** Set PCM data rederd from %7.
         *  @param index PCM data number.
         *  @param sound Sound instance to set.
         *  @param samplingOctave Sampling frequency. The value of 5 means that "o5a" is original frequency.
         */
        public function setPCMData(index:int, sound:Sound, samplingOctave:int=5) : void
        {
            var data:Vector.<int> = SiONUtil.serialize(sound);
            SiOPMTable.registerPCMData(index, data, samplingOctave);
        }
        
        
        /** Set wave data refered by %10.
         *  @param index note number. 128-255 for bank1.
         *  @param sound Sound instance to set.
         *  @param isOneShot True to set "one shot" sound. The "one shot" sound ignores note off.
         *  @param isStereo True to set as stereo data.
         */
        public function setWaveData(index:int, sound:Sound, isOneShot:Boolean=true, isStereo:Boolean=false) : void
        {
            var data:Vector.<int> = SiONUtil.getRawData(sound);
            SiOPMTable.registerSample(index, data, ((isOneShot) ? 2 : 0) + ((isStereo) ? 1 : 0));
        }
        
        
        
        
    // Interface for intaractivity
    //----------------------------------------
        /** Note on. This function only is available after play(). The NOTE_ON_STREAM event is dispatched inside.
         *  @param note note number [0-127].
         *  @param setting tone setting.
         *  @param length note length in 16th beat. 0 sets no note off, this means you should call noteOff().
         *  @param delay note on delay units in 16th beat.
         *  @param quant quantize in 16th beat. 0 sets no quantization. 4 sets quantization by 4th beat.
         *  @param trackID new tracks id.
         *  @param eventTriggerID Event trigger id.
         *  @param noteOnTrigger note on trigger type.
         *  @param noteOffTrigger note off trigger type.
         *  @return SiMMLTrack to play the note.
         */
        public function noteOn(note:int, setting:SiONToneSetting, 
                               length:Number=0, delay:Number=0, quant:int=0, trackID:int=0, 
                               eventTriggerID:int=0, noteOnTrigger:int=0, noteOffTrigger:int=0) : SiMMLTrack
        {
            trackID = (trackID & SiMMLTrack.TRACK_ID_FILTER) | SiMMLTrack.DRIVER_TRACK_ID_OFFSET;
            var mmlTrack:SiMMLTrack = sequencer.getFreeControlableTrack(trackID) || sequencer.newControlableTrack(trackID);
            var delaySamples:int = sequencer.calcSampleDelay(0, delay, quant);
            if (mmlTrack) {
                if (setting) setting.setTrackTone(mmlTrack);
                mmlTrack.setEventTrigger(eventTriggerID, noteOnTrigger, noteOffTrigger);
                mmlTrack.keyOn(note, sequencer.calcSampleLength(length), delaySamples);
            }
            return mmlTrack;
        }
        
        
        /** Note off. This function only is available after play(). The NOTE_OFF_STREAM event is dispatched inside.
         *  @param note note number [0-127].
         *  @param trackID track id to note off.
         *  @return The SiMMLTrack switched key off. Returns null when tracks are overflowed.
         */
        public function noteOff(note:int, trackID:int=0) : SiMMLTrack
        {
            trackID = (trackID & SiMMLTrack.TRACK_ID_FILTER) | SiMMLTrack.DRIVER_TRACK_ID_OFFSET;
            var mmlTrack:SiMMLTrack = sequencer.findControlableTrack(trackID, note);
            if (mmlTrack) mmlTrack.keyOff();
            return mmlTrack;
        }
        
        
        
        
    //====================================================================================================
    // Internal uses
    //====================================================================================================
    // callback for event trigger
    //----------------------------------------
        // call back when sound streaming
        private function _callbackEventTriggerOn(track:SiMMLTrack, pitch:int) : Boolean
        {
            return _publishEventTrigger(track, track.eventTriggerTypeOn, SiONTrackEvent.NOTE_ON_FRAME, SiONTrackEvent.NOTE_ON_STREAM);
        }
        
        // call back when sound streaming
        private function _callbackEventTriggerOff(track:SiMMLTrack) : Boolean
        {
            return _publishEventTrigger(track, track.eventTriggerTypeOff, SiONTrackEvent.NOTE_OFF_FRAME, SiONTrackEvent.NOTE_OFF_STREAM);
        }
        
        // publish event trigger
        private function _publishEventTrigger(track:SiMMLTrack, type:int, frameEvent:String, streamEvent:String) : Boolean
        {
            var event:SiONTrackEvent;
            if (type & 1) { // frame event. dispatch later
                event = new SiONTrackEvent(frameEvent, this, track);
                _triggerEventQueue.push(event);
            }
            if (type & 2) { // sound event. dispatch immediately
                event = new SiONTrackEvent(streamEvent, this, track);
                dispatchEvent(event);
                return !(event.isDefaultPrevented());
            }
            return true;
        }
        
        
    // operate event listener
    //----------------------------------------
        // add all event listners
        private function _queue_addAllEventListners() : void
        {
            if (_listenEvent != NO_LISTEN) throw errorDriverBusy(LISTEN_QUEUE);
            addEventListener(Event.ENTER_FRAME, _queue_onEnterFrame, false, _eventListenerPrior);
            _listenEvent = LISTEN_QUEUE;
        }
        
        
        // add all event listners
        private function _process_addAllEventListners() : void
        {
            if (_listenEvent != NO_LISTEN) throw errorDriverBusy(LISTEN_PROCESS);
            addEventListener(Event.ENTER_FRAME, _process_onEnterFrame, false, _eventListenerPrior);
            _dispatchStreamEvent = (hasEventListener(SiONEvent.STREAM));
            _prevFrameTime = getTimer();
            _listenEvent = LISTEN_PROCESS;
        }
        
        
        // remove all event listners
        private function _removeAllEventListners() : void
        {
            switch (_listenEvent) {
            case LISTEN_QUEUE:
                removeEventListener(Event.ENTER_FRAME, _queue_onEnterFrame);
                break;
            case LISTEN_PROCESS:
                removeEventListener(Event.ENTER_FRAME, _process_onEnterFrame);
                _dispatchStreamEvent = false;
                break;
            }
            _listenEvent = NO_LISTEN;
        }
        
        
        
        
    // parse
    //----------------------------------------
        // parse system command on SiONDriver
        private function _parseSystemCommand(systemCommands:Array) : Boolean
        {
            var id:int, effectSet:Boolean = false;
            for each (var cmd:* in systemCommands) {
                switch(cmd.command){
                case "#EFFECT":
                    if (!effectSet) effector.initialize();  // initialize effect
                    effectSet = true;
                    effector.parseMML(cmd.number, cmd.content);
                    break;
                }
            }
            return effectSet;
        }
        
        
        
        
    // jobs queue
    //----------------------------------------
        // cancel
        private function _cancelAllJobs() : void
        {
            _data = null;
            _mmlString = null;
            _currentJob = 0;
            _jobQueue.length = 0;
            _queueLength = 0;
            _removeAllEventListners();
            dispatchEvent(new SiONEvent(SiONEvent.QUEUE_CANCEL, this, null));
        }
        
        
        // next job
        private function _executeNextJob() : Boolean
        {
            _data = null;
            _mmlString = null;
            _currentJob = 0;
            if (_jobQueue.length == 0) {
                _queueLength = 0;
                _removeAllEventListners();
                dispatchEvent(new SiONEvent(SiONEvent.QUEUE_COMPLETE, this, null));
                return true;
            }
            
            var queue:SiONDriverJob = _jobQueue.shift();
            if (queue.mml) _prepareCompile(queue.mml, queue.data);
            else _prepareRender(queue.data, queue.buffer);
            return false;
        }
        
        
        // on enterFrame
        private function _queue_onEnterFrame(e:Event) : void
        {
            try {
                var event:SiONEvent, t:int = getTimer();
                
                switch (_currentJob) {
                case 1: // compile
                    _jobProgress = sequencer.compile(_queueInterval);
                    _timeCompile += getTimer() - t;
                    break;
                case 2: // render
                    _jobProgress += (1 - _jobProgress) * 0.5;
                    while (getTimer() - t <= _queueInterval) { 
                        if (_rendering()) {
                            _jobProgress = 1;
                            break;
                        }
                    }
                    _timeRender += getTimer() - t;
                    break;
                }
                
                // finish job
                if (_jobProgress == 1) {
                    // finish all jobs
                    if (_executeNextJob()) return;
                }
                
                // progress
                event = new SiONEvent(SiONEvent.QUEUE_PROGRESS, this, null, true);
                dispatchEvent(event);
                if (event.isDefaultPrevented()) _cancelAllJobs();   // canceled
            } catch (e:Error) {
                // error
                _removeAllEventListners();
                if (_debugMode) throw e;
                else dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, e.message));
            }
        }
        
        
        
    // compile
    //----------------------------------------
        // prepare to compile
        private function _prepareCompile(mml:String, data:SiONData) : void
        {
            _data = data || new SiONData();
            _mmlString = mml;
            sequencer.prepareCompile(_data, _mmlString);
            _jobProgress = 0.01;
            _timeCompile = 0; 
            _currentJob = 1;
        }
        
        
        
        
    // render
    //----------------------------------------
        // prepare for rendering
        private function _prepareRender(data:*, renderBuffer:Vector.<Number>) : void
        {
            _prepareProcess(data);
            _renderBuffer = renderBuffer || new Vector.<Number>();
            _renderBufferSizeMax = _renderBuffer.length;
            _renderBufferIndex = 0;
            _jobProgress = 0.01;
            _timeRender = 0;
            _currentJob = 2;
        }
        
        
        // rendering @return true when finished rendering.
        private function _rendering() : Boolean
        {
            var i:int, j:int, imax:int, 
                output:Vector.<Number> = module.output, 
                finished:Boolean = false;
            
            // processing
            sequencer.process();
            effector.process();
            
            // limit rendering length
            imax = _bufferLength<<1;
            if (_renderBufferSizeMax != 0 && _renderBufferSizeMax < _renderBufferIndex+imax) {
                imax = _renderBufferSizeMax - _renderBufferIndex;
                finished = true;
            }
            
            // extend buffer
            if (_renderBuffer.length < _renderBufferIndex+imax) {
                _renderBuffer.length = _renderBufferIndex+imax;
            }
            
            // copy output
            for (i=0, j=_renderBufferIndex; i<imax; i++, j++) {
                _renderBuffer[j] = output[i];
            }
            
            // incerement index
            _renderBufferIndex += imax;
            
            return (finished || (_renderBufferSizeMax==0 && sequencer.isFinished));
        }
        
        
        
        
    // process
    //----------------------------------------
        // prepare for processing
        private function _prepareProcess(data:*) : void
        {
            if (data is String) {
                _data = compile(data as String);
            } else {
                if (!(data == null || data is SiONData)) throw errorDataIncorrect();
                _data = data;
            }
            module.initialize(_channelCount, _bufferLength);
            module.reset();                                                 // reset channels
            sequencer.prepareProcess(_data, _sampleRate, _bufferLength);    // set track channels (this must be called after module.reset().
            if (_data) _parseSystemCommand(_data.systemCommands);           // parse #EFFECT (initialize effector inside)
            effector.prepareProcess();                                      // set stream number inside
        }
        
        
        // on enterFrame
        private function _process_onEnterFrame(e:Event) : void
        {
            // frame rate
            var t:int = getTimer();
            _frameRate = t - _prevFrameTime;
            _prevFrameTime = t;
            
            // frame trigger
            if (_triggerEventQueue.length > 0) {
                _triggerEventQueue = _triggerEventQueue.filter(function(e:SiONTrackEvent, i:int, v:Vector.<SiONTrackEvent>) : Boolean {
                    if (e._decrementTimer(_frameRate)) {
                        dispatchEvent(e);
                        return false;
                    }
                    return true;
                });
            }
        }
        
        
        // on sampleData
        private function _streaming(e:SampleDataEvent) : void
        {
            var buffer:ByteArray = e.data, output:Vector.<Number> = module.output, imax:int, i:int;

            // calculate latency (0.022675736961451247 = 1/44.1)
            if (_soundChannel) {
                _latency = e.position * 0.022675736961451247 - _soundChannel.position;
            }
            
            try {
                if (_isPaused) {
                    // paused -> 0 filling
                    buffer = e.data;
                    imax = module.bufferLength;
                    for (i=0; i<imax; i++) {
                        buffer.writeFloat(0);
                        buffer.writeFloat(0);
                    }
                } else {
                    var t:int = getTimer();
                    // processing
                    _cannotChangeBPM = true;
                    sequencer.process();
                    effector.process();
                    _cannotChangeBPM = false;
                    
                    // calculate the average of processing time
                    _timePrevStream = t;
                    _timeProcessTotal -= _timeProcessData.i;
                    _timeProcessData.i = getTimer() - t;
                    _timeProcessTotal += _timeProcessData.i;
                    _timeProcessData   = _timeProcessData.next;
                    _timeProcess = _timeProcessTotal * _timeProcessAveRatio;
                    
                    // write samples
                    imax = output.length;
                    for (i=0; i<imax; i++) buffer.writeFloat(output[i]);
                    
                    // dispatch streaming event
                    if (_dispatchStreamEvent) {
                        var event:SiONEvent = new SiONEvent(SiONEvent.STREAM, this, buffer, true);
                        dispatchEvent(event);
                        if (event.isDefaultPrevented()) stop();   // canceled
                    }
                }
            } catch (e:Error) {
                // error
                _removeAllEventListners();
                if (_debugMode) throw e;
                else dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, e.message));
            }
        }
        
        
        
        
    // error
    //----------------------------------------
        private function errorDataIncorrect() : Error {
            return new Error("SiONDriver error; data incorrect in play() or render().");
        }
        
        
        private function errorDriverBusy(execID:int) : Error {
            var states:Array = ["compiling", "streaming", "rendering"];
            return new Error("SiONDriver error: Driver busy. Call " + states[execID] + " while " + states[_listenEvent] + ".");
        }
        
        
        private function errorCannotChangeBPM() : Error {
            return new Error("SiONDriver error: Cannot change bpm while rendering (SiONTrackEvent.NOTE_*_STREAM).");
        }
    }
}




import org.si.sound.SiONData;

class SiONDriverJob
{
    public var mml:String;
    public var buffer:Vector.<Number>;
    public var data:SiONData;
    
    function SiONDriverJob(mml_:String, buffer_:Vector.<Number>, data_:SiONData) 
    {
        mml = mml_;
        buffer = buffer_;
        data = data_ || new SiONData();
    }
}


