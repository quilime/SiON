//----------------------------------------------------------------------------------------------------
// Basic class of a drivers between MMLEvent and sound module.
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------




package org.si.sound.mml {
    /**
     *  MMLSequencer is the basic class of a bridges between MMLEvents, sound modules and sound systems. 
     *  You should follow this in your inherited classes. <br/>
     *  1) Register MML event listeners by setMMLEventListener() or newMMLEventListener().<br/>
     *  2) Override on...() functions.<br/>
     *  3) Override prepareCompile() and compile() if necessary.<br/>
     *  4) Override prepareProcess() and process() to process audio data.<br/>
     *  And usage is as below. 
     *  1) Call initialize() to initialize.<br/>
     *  2) Call prepareCompile() and compile() to compile the MML string to MMLData.<br/>
     *  3) Call prepareProcess() and process() to process audio in inherited class.<br/>
     */
    public class MMLSequencer
    {
    // constant
    //--------------------------------------------------
        // bits for fixed decimal
        private const FIXED_BITS:int = 8;
        // filter for decimal fraction area
        private const FIXED_FILTER:int = (1<<FIXED_BITS)-1;
        
        
        
        
    // valiables
    //--------------------------------------------------
        /** MML parser setting.  */
        public var setting:MMLParserSetting;
        /** Audio setting, channel count. The value is restricted as 1 or 2.  */
        public var channel:int;
        /** Audio setting, sampling ratio. The value is restricted as 22050 or 44100.  */
        public var sampleRate:int;
        /** Audio setting, bit ratio. The value is restricted as 8 or 16.  */
        public var bitRate:int;
        
        /** Global sequence executor */
        protected var globalExecutor:MMLExecutor;
        /** Current processing sequence executor. You can refer this in onProcess. */
        protected var currentExecutor:MMLExecutor; 
        /** Current MMLData to compile or process */
        protected var mmlData:MMLData;
        
        private var _newUserDefinedEventID:int = MMLEvent.USER_DEFINE;  // id value of new user-defined event.
        private var _userDefinedEventID:Object = {};                    // id map of user-defined event letter set by newMMLEventListener().
        private var _eventHandlers:Vector.<Function>   = new Vector.<Function>(MMLEvent.COMMAND_MAX, true); // list of event handler functions set by setMMLEventListener().
        private var _eventGlobalFlags:Vector.<Boolean> = new Vector.<Boolean> (MMLEvent.COMMAND_MAX, true); // global event flag
        private var _nopEvent:MMLEvent;             // MMLEvent.NOP
        
        private var _processSampleCount:int;        // leftover of buffer sample count in processing
        private var _globalBufferSampleCount:int;   // leftover of buffer sample count in global sequence
        private var _globalExecuteSampleCount:int;  // executing buffer length in global sequence
        
        private var _bpm:Number;                    // beat per minute
        private var _samplePerTick:int;             // samples per tick << FIXED_BITS
        private var _bufferSize:int;                // buffer sample count
        
        
        
        
    // properties
    //--------------------------------------------------
        /** beat per minute. */
        protected function set bpm(b:Number) : void
        {
            if (b<1) b=1;
            else if (b>511) b=511;
            _samplePerTick = int((sampleRate * 240 / (setting.resolution * b)) * (1<<FIXED_BITS));
            onTempoChanged(_bpm/b);
            _bpm = b;
        }
        protected function get bpm() : Number { return _bpm; }
                
        
        
        
    // constructor
    //--------------------------------------------------
        /** Default constructor initializes event handlers. */
        function MMLSequencer()
        {
            this.setting = new MMLParserSetting();
            
            for (var i:int=0; i<MMLEvent.COMMAND_MAX; i++) { _eventHandlers[i] = _nop; }
            setMMLEventListener(MMLEvent.NOP,          _default_onNoOperation,  false);
            setMMLEventListener(MMLEvent.PROCESS,      _default_onProcess,      false);
            setMMLEventListener(MMLEvent.REPEAT_ALL,   _default_onRepeatAll,    false);
            setMMLEventListener(MMLEvent.REPEAT_BEGIN, _default_onRepeatBegin,  false);
            setMMLEventListener(MMLEvent.REPEAT_BREAK, _default_onRepeatBreak,  false);
            setMMLEventListener(MMLEvent.REPEAT_END,   _default_onRepeatEnd,    false);
            setMMLEventListener(MMLEvent.SEQUENCE_TAIL,_default_onSequenceTail, false);
            setMMLEventListener(MMLEvent.WAIT,         _default_onWait,         true);
            setMMLEventListener(MMLEvent.TEMPO,        _default_onTempo,        true);
            setMMLEventListener(MMLEvent.TABLE_EVENT,  _nop,                    true);
            _newUserDefinedEventID = MMLEvent.USER_DEFINE;
            _nopEvent = (new MMLEvent()).initialize(MMLEvent.NOP, 0, 0);
            
            globalExecutor = new MMLExecutor();
        }
        
        
        
        
    // internal operation
    //--------------------------------------------------
        /** Similar with an addEventListener for MMLEvents, but only one listener is for one event.
         *  @param id The ID of the event.
         *  @param func The functor of the event called back when its processing.
         */
        protected function setMMLEventListener(id:int, func:Function, isGlobal:Boolean = false) : void
        {
            _eventHandlers[id] = func;
            _eventGlobalFlags[id] = isGlobal;
        }
        
        
        /** Register new MMLEvent letter. 
         *  @param letter The letter of the event on mml.
         *  @param func The functor of the event called back when its processing.
         *  @return The ID of the event. This value is greater than or equal to MMLEvent.USER_DEFINE.
         */
        protected function newMMLEventListener(letter:String, func:Function, isGlobal:Boolean = false) : int
        {
            var id:int = _newUserDefinedEventID++;
            _userDefinedEventID[letter] = id;
            _eventHandlers[id] = func;
            _eventGlobalFlags[id] = isGlobal;
            return id;
        }
        
        
        
        
    // intiialize
    //--------------------------------------------------
        /** Initialize. This function calls onInitialize().
         *  @param channel Channel count. 1 or 2 is available.
         *  @param sampleRate Sampling ratio of wave. 22050 or 44100 is available.
         *  @param bitRate Bit ratio of wave. 8 or 16 is available.
         */
        public function initialize(channel:int, sampleRate:int, bitRate:int) : void
        {
            if (channel   !=1     && channel   !=2)     throw new Error ("MMLSequencer error: Only 1 or 2 Channel count is available.");
            if (sampleRate!=22050 && sampleRate!=44100) throw new Error ("MMLSequencer error: Only 22050 or 44100 sampling rate is available.");
            if (bitRate   !=8     && bitRate   !=16)    throw new Error ("MMLSequencer error: Only 8 or 16 bit ratio is available.");
            this.channel = channel;
            this.sampleRate = sampleRate;
            this.bitRate = bitRate;
            onInitialize();
        }
        
        
        
        
    // compile
    //--------------------------------------------------
        /** Prepare to compile mml string. Calls onBeforeCompile() inside.
         *  @param data Data instance.
         *  @param mml MML String.
         *  @return Returns false when it's not necessary to compile.
         */
        public function prepareCompile(data:MMLData, mml:String) : Boolean
        {
            // set internal parameters
            mmlData = data;
            if (mmlData == null) return false;
            
            // clear mml data
            mmlData.clear();
            
            // callback before compiling
            var mmlString:String = onBeforeCompile(mml);
            if (mmlString== null) {
                mmlData = null;
                return false;
            }
            
            // setting
            MMLParser._setUserDefinedEventID(_userDefinedEventID);
            MMLParser._setGlobalEventFlags(_eventGlobalFlags);
            MMLParser.prepareParse(setting, mmlString);
            return true;
        }
        
        
        /** Parse mml string. Calls onAfterCompile() inside.
         *  @param interval Interval to interrupt parsing [ms]. Set 0 to parse at once.
         *  @return Return compile progression. Returns 1 when its finished, or when preparation has not completed.
         */
        public function compile(interval:int = 1000) : Number
        {
            if (mmlData == null) return 1;
            
            // parse mmlString
            var e:MMLEvent = MMLParser.parse(interval);
            // null means parse imcompleted.
            if (e == null) return MMLParser.parseProgress;

            // create main sequence group
            mmlData.sequenceGroup.alloc(e);
            // abstruct global sequences
            _abstructGlobalSequence();
            // callback after parsing
            onAfterCompile(mmlData.sequenceGroup);
            
            return 1;
        }
        
        
        
        
    // process
    //--------------------------------------------------
        /** Prepare to process audio. Override and call this in the overrided function.
         *  @param bufferSize Sample count to buffer samples at once.
         *  @param resetParams Reset all channel parameters.
         */
        public function prepareProcess(data:MMLData, bufferSize:int) : void
        {
            mmlData = data;
            _bufferSize = bufferSize;
            if (mmlData == null) {
                bpm = setting.defaultBPM;
                globalExecutor.initialize(null);
            } else {
                bpm = mmlData.defaultBPM;
                globalExecutor.initialize(mmlData.globalSequence);
                mmlData.regiterAllTables();
            }
        }
        
        
        /** Process all tracks. override this function. 
         *  @return Returns true when all processes are finished.
         */
        public function process() : Boolean
        {
            // DO NOTHING !!
            // You dont have to call this in your overrided function.
            return true;
        }
        
        
        /** Execute global sequence. */
        protected function startGlobalSequence() : void
        {
            _globalBufferSampleCount = _bufferSize;
            _globalExecuteSampleCount = 0;
        }
        protected function executeGlobalSequence() : int
        {
            currentExecutor = globalExecutor;
            
            var event:MMLEvent = currentExecutor.pointer;
            _globalExecuteSampleCount = 0;
            do {
                if (event == null) {
                    _globalExecuteSampleCount = _globalBufferSampleCount;
                    _globalBufferSampleCount = 0;
                } else {
                    // update _globalExecuteSampleCount in some _eventHandler()s
                    event = _eventHandlers[event.id](event);
                    currentExecutor.pointer = event;
                }
            } while (_globalExecuteSampleCount == 0);
            return _globalExecuteSampleCount;
        }
        protected function isEndGlobalSequence() : Boolean
        {
            return (_globalBufferSampleCount == 0);
        }
        

        /** Processing audio of one sequence executor. Calls onProcess() inside.
         *  @param  exe MMLExecutor to process.
         *  @param  bufferSampleCount Buffering length of processing samples at once.
         *  @return Returns true when the process is finished.
         */
        protected function processMMLExecutor(exe:MMLExecutor, bufferSampleCount:int) : Boolean
        {
            currentExecutor = exe;
            
            // buffering
            var event:MMLEvent = currentExecutor.pointer;
            _processSampleCount = bufferSampleCount;
            while (_processSampleCount > 0) {
                if (event == null) {
                    _eventHandlers[MMLEvent.NOP](_nopEvent);
                    return true;
                } else {
                    // update _processSampleCount in some _eventHandler()s
                    event = _eventHandlers[event.id](event);
                    currentExecutor.pointer = event;
                }
            }
            return false;
        }
        
        
        
        
    // process
    //--------------------------------------------------
        /** Calculate sample count from length of MMLEvent. */
        protected function calcSampleCount(len:int) : int
        {
            return (len * _samplePerTick) >> FIXED_BITS;
        }
        
        
        /** Call onTableParse. This function */
        protected function callOnTableParse(prev:MMLEvent) : void
        {
            var tableEvent:MMLEvent = prev.next;
            onTableParse(prev, MMLParser._getSystemEventString(tableEvent));
            prev.next = tableEvent.next;
            MMLParser._freeEvent(tableEvent);
        }
        
        
        
        
    // virtual functions
    //--------------------------------------------------
        /** Callback on initializeng. This function is called from initialize(). Override this to modify setting. */
        protected function onInitialize() : void
        {
        }
        
        
        /** Callback before parse. This function is called from parse() before parseing.
         *  @param mml The mml string to parse.
         *  @return The mml string you want to parse. Parses with default mml string when you return null.
         */
        protected function onBeforeCompile(mml:String) : String
        {
            return null;
        }
        
        
        /** Callback after parse. This function is called from parse() after parseing.
         */
        protected function onAfterCompile(seqGroup:MMLSequenceGroup) : void
        {
        }
        
        
        /** Callback when table event was found.
         */
        protected function onTableParse(prev:MMLEvent, table:String) : void
        {
        }
        
        
        /** Callback on processing. This function is called from process(). 
         *  @param length Sample length to process calculated from settings.
         *  @param e MMLEvent that calls onProcess().
         */
        protected function onProcess(length:int, e:MMLEvent) : void
        {
        }
        
        
        /** Callback when the tempo is changed.
         *  @param tempoRatio Ratio of changed tempo and previous tempo.
         */
        protected function onTempoChanged(tempoRatio:Number) : void
        {
        }
        
        
        
        
    // private functions
    //--------------------------------------------------
        // abstruct global sequence.
        static private var _tempExecutor:MMLExecutor = new MMLExecutor();
        private function _abstructGlobalSequence() : void
        {
            var seqGroup:MMLSequenceGroup = mmlData.sequenceGroup;
            
            var list:Array = [];
            var seq:MMLSequence, prev:MMLEvent, e:MMLEvent, pos:int, count:int, hasNoEvent:Boolean, i:int, defaultBPM:int;
            
            for (seq = seqGroup.headSequence; seq != null; seq = seq.nextSequence) {
                count = seq.headEvent.data;
                if (count == 0) continue;
                
                // initialize
                _tempExecutor.initialize(seq);
                prev = seq.headEvent;
                e = prev.next;
                pos = 0;
                hasNoEvent = true;
                
                // calculate positoin and pickup global events
                while (e != null && (count > 0 || hasNoEvent)) {
                    if (_eventGlobalFlags[e.id]) {
                        if (e.id == MMLEvent.TABLE_EVENT) {
                            // table event
                            callOnTableParse(prev);
                        } else {
                            // global event
                            if (seq.headEvent.jump === e) seq.headEvent.jump = prev;
                            prev.next = e.next;
                            e.next = null;
                            e.length = pos;
                            list.push(e);
                        }
                        e = prev.next;
                        count--;
                    } else
                    if (e.length) {
                        // note or rest
                        pos += e.length;
                        if (e.id != MMLEvent.REST) hasNoEvent = false;
                        prev = e;
                        e = e.next;
                    } else {
                        // others
                        switch (e.id) {
                        case MMLEvent.REPEAT_BEGIN:  e = _tempExecutor._onRepeatBegin(e);  break;
                        case MMLEvent.REPEAT_BREAK:  e = _tempExecutor._onRepeatBreak(e);  break;
                        case MMLEvent.REPEAT_END:    e = _tempExecutor._onRepeatEnd(e);    break;
                        case MMLEvent.REPEAT_ALL:    e = _tempExecutor._onRepeatAll(e);    break;
                        case MMLEvent.SEQUENCE_TAIL: e = null;                             break;
                        default:
                            prev = e;
                            e = e.next;
                            hasNoEvent = true;
                            break;
                        }
                    }
                }
                
                // if no event (except rest) in the sequence, skip this sequence
                if (hasNoEvent) {
//trace("skip sequence");
                    seq = seq.removeFromChain();
                }
            }
            
            
            // sort and create global sequence
            seq = mmlData.globalSequence;
            
            seq.alloc();
            list = list.sortOn(length, Array.NUMERIC);
            pos = 0;
            defaultBPM = setting.defaultBPM;
            for each (e in list) {
                if (e.length == 0 && e.id == MMLEvent.TEMPO) {
                    // first tempo command is defaultBPM.
                    defaultBPM = e.data;
                } else {
                    count = e.length - pos;
                    pos = e.length;
                    e.length = 0;
                    if (count > 0) seq.pushEvent(MMLEvent.WAIT, 0, count);
                    seq.connectEvent(e);
                }
            }
//trace(seq);
            
            // set default bpm in mmlData
            mmlData.defaultBPM = defaultBPM;
        }
        
        
        
    // default callback functions
    //--------------------------------------------------
        /** Operates nothing. */
        protected function _nop(e:MMLEvent) : MMLEvent
        {
            return e.next;
        }
        
        
        /** default operation for MMLEvent.NOP. */
        protected function _default_onNoOperation(e:MMLEvent) : MMLEvent
        {
            onProcess(_processSampleCount, e);
            return e;
        }
        
        
        /** default operation for MMLEvent.WAIT. */
        protected function _default_onWait(e:MMLEvent) : MMLEvent
        {
            var exec:MMLExecutor = currentExecutor;
            
            // set processing length
            if (exec._residueSampleCount == 0) {
                var sampleCountFixed:int = e.length * _samplePerTick + exec._decimalFractionSampleCount;
                exec._residueSampleCount = sampleCountFixed >> FIXED_BITS;
                exec._decimalFractionSampleCount = sampleCountFixed & FIXED_FILTER;
            }
            
            // waiting
            if (exec._residueSampleCount <= _globalBufferSampleCount) {
                _globalExecuteSampleCount = exec._residueSampleCount;
                _globalBufferSampleCount  -= _globalExecuteSampleCount;
                exec._residueSampleCount  = 0;
                // goto next command
                return e.next;
            } else {
                _globalExecuteSampleCount =  _globalBufferSampleCount;
                exec._residueSampleCount  -= _globalExecuteSampleCount;
                _globalBufferSampleCount  = 0;
                // stay on this command
                return e;
            }
        }
        
        
        /** default operation for MMLEvent.PROCESS. */
        protected function _default_onProcess(e:MMLEvent) : MMLEvent
        {
            var exec:MMLExecutor = currentExecutor;
            
            // set processing length
            if (exec._residueSampleCount == 0) {
                var sampleCountFixed:int = e.length * _samplePerTick + exec._decimalFractionSampleCount;
                exec._residueSampleCount = sampleCountFixed >> FIXED_BITS;
                exec._decimalFractionSampleCount = sampleCountFixed & FIXED_FILTER;
            }
            
            // processing
            if (exec._residueSampleCount <= _processSampleCount) {
                onProcess(exec._residueSampleCount, e.jump);
                _processSampleCount -= exec._residueSampleCount;
                exec._residueSampleCount = 0;
                // goto next command
                return e.jump.next;
            } else {
                onProcess(_processSampleCount, e.jump);
                exec._residueSampleCount -= _processSampleCount;
                _processSampleCount = 0;
                // stay on this command
                return e;
            }
        }
        
        
        /** dummy operation for MMLEvent.PROCESS. */
        protected function _dummy_onProcess(e:MMLEvent) : MMLEvent
        {
            var exec:MMLExecutor = currentExecutor;
            
            // set processing length
            if (exec._residueSampleCount == 0) {
                var sampleCountFixed:int = e.length * _samplePerTick + exec._decimalFractionSampleCount;
                exec._residueSampleCount = sampleCountFixed >> FIXED_BITS;
                exec._decimalFractionSampleCount = sampleCountFixed & FIXED_FILTER;
            }
            
            // processing
            if (exec._residueSampleCount <= _processSampleCount) {
                _processSampleCount -= exec._residueSampleCount;
                exec._residueSampleCount = 0;
                // goto next command
                return e.jump.next;
            } else {
                exec._residueSampleCount -= _processSampleCount;
                _processSampleCount = 0;
                // stay on this command
                return e;
            }
        }
        
        
        /** default operation for MMLEvent.REPEAT_ALL. */
        protected function _default_onRepeatAll(e:MMLEvent) : MMLEvent
        {
            return currentExecutor._onRepeatAll(e);
        }
        
        
        /** default operation for MMLEvent.REPEAT_BEGIN. */
        protected function _default_onRepeatBegin(e:MMLEvent) : MMLEvent
        {
            return currentExecutor._onRepeatBegin(e);
        }
        
        
        /** default operation for MMLEvent.REPEAT_BREAK. */
        protected function _default_onRepeatBreak(e:MMLEvent) : MMLEvent
        {
            return currentExecutor._onRepeatBreak(e);
        }
        
        
        /** default operation for MMLEvent.REPEAT_END. */
        protected function _default_onRepeatEnd(e:MMLEvent) : MMLEvent
        {
            return currentExecutor._onRepeatEnd(e);
        }
        
        
        /** default operation for MMLEvent.SEQUENCE_TAIL. */
        protected function _default_onSequenceTail(e:MMLEvent) : MMLEvent
        {
            return currentExecutor._onSequenceTail(e);
        }
        
        
        /** default operation for MMLEvent.TEMPO. */
        protected function _default_onTempo(e:MMLEvent) : MMLEvent
        {
            bpm = e.data;
            return e.next;
        }
    }
}

