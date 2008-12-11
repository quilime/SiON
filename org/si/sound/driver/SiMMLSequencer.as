//----------------------------------------------------------------------------------------------------
// MML bridge for SiOPMModule.
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------




package org.si.sound.driver {
    import flash.system.System;
    
    import org.si.sound.mml.*;
    import org.si.sound.module.SiOPMModule;
    import org.si.sound.module.SiOPMChannelFM;
    import org.si.sound.module.SiOPMChannelBase;
    import org.si.sound.module.SiOPMChannelParam;
    import org.si.sound.module.SiOPMOperatorParam;
    import org.si.sound.module.SiOPMTable;
    import org.si.utils.SLLint;
    
    
    /** MML bridge for SiOPMModule.
     *  SiMMLSequencer -> SiMMLSequencerTrack -> SiOPMChannelFM -> SiOPMOperator. (-> means "operates")
     */
    public class SiMMLSequencer extends MMLSequencer
    {
    // constants
    //--------------------------------------------------
        /** maximum output level of 1 operator. */
        static public const OUTPUT_MAX:int = (1<<SiOPMTable.LOG_VOLUME_BITS);
        /** maximum prameter count */
        static public const PARAM_MAX:int = 16;
        /** macro size */
        static public const MACRO_SIZE:int = 26;
        
        
        // mask bit for @m command
        static protected const MASK_VOLUME  :int = 1;
        static protected const MASK_PAN     :int = 2;
        static protected const MASK_QUANTIZE:int = 4;
        static protected const MASK_OPERATOR:int = 8;
        static protected const MASK_ENVELOP :int = 16;
        static protected const MASK_MODULATE:int = 32;
        
        
        
        
    // valiables
    //--------------------------------------------------
        /** Module instance. */
        public var module:SiOPMModule;
        
        /** Current processing track. */
        protected var currentTrack:SiMMLSequencerTrack;
        
        /** MMLExecutorConnector */
        protected var connector:MMLExecutorConnector;
        
        /** Macro strings */
        protected var macroStrings:Vector.<String>;
        /** Expanded macro flag to avoid circular reference */
        protected var macroExpanded:uint;
        
        /** Event id of first envelop */
        protected var envelopEventID:int;
        /** Macro expantion mode */
        protected var macroExpandDynamic:Boolean;
        
        // temporary area to get plural parameters
        private var _p:Vector.<int> = new Vector.<int>(PARAM_MAX);
        // internal table index
        private var _internalTableIndex:int = 0
        
        // Title of the song.
        private var _title:String;
        // SiMMLSequencerTracks count
        private var _trackCount:int;
        // SiMMLSequencerTracks
        private var _tracks:Array;
        // Processed sample count
        private var _processedSampleCount:int;
        
        
        
        
    // properties
    //--------------------------------------------------
        /** SiMMLSequencerTracks count */
        public function get trackCount() : int { return _trackCount; }
        
        /** Is ready to process ? */
        public function get isReadyToProcess() : Boolean { return (_trackCount>0); }
        
        /** Song title */
        public function get title() : String { return _title; }
        
        /** Processed sample count */
        public function get processedSampleCount() : int { return _processedSampleCount; }
        
        
        
        
    // constructor
    //--------------------------------------------------
        /** Create new sequencer. */
        function SiMMLSequencer()
        {
            super();
            
            var i:int;
            
            // initialize
            module = new SiOPMModule();
            _tracks = [];
            _trackCount = 0;
            _processedSampleCount = 0;
            connector = new MMLExecutorConnector();
            macroStrings  = new Vector.<String> (MACRO_SIZE, true);
            
            // initialize table once
            SiOPMTable.initialize(3580000, 44100);
            SiMMLTable.initialize();
            
            // pitch
            newMMLEventListener('k',    _onDetune);
            newMMLEventListener('kt',   _onKeyTrans);
            newMMLEventListener('!@kr', _onRelativeDetune);
            
            // track setting
            newMMLEventListener('@mask', _onEventMask);
            setMMLEventListener(MMLEvent.QUANT_RATIO,  _onQuantRatio);
            setMMLEventListener(MMLEvent.QUANT_COUNT,  _onQuantCount);
            
            // volume
            newMMLEventListener('p',  _onPan);
            newMMLEventListener('@p', _onFinePan);
            newMMLEventListener('@f', _onFilter);
            newMMLEventListener('x',  _onExpression);
            setMMLEventListener(MMLEvent.VOLUME,       _onVolume);
            setMMLEventListener(MMLEvent.VOLUME_SHIFT, _onVolumeShift);
            setMMLEventListener(MMLEvent.FINE_VOLUME,  _onMasterVolume);

            // channel setting
            newMMLEventListener('@al', _onAlgorism);
            newMMLEventListener('@fb', _onFeedback);
            newMMLEventListener('@r',  _onRingModulation);
            setMMLEventListener(MMLEvent.MOD_TYPE,    _onModuleType);
            setMMLEventListener(MMLEvent.INPUT_PIPE,  _onInput);
            setMMLEventListener(MMLEvent.OUTPUT_PIPE, _onOutput);
            newMMLEventListener('%e',  _onModuleEffect);
            
            
            // operator setting
            newMMLEventListener('i',   _onSlotIndex);
            newMMLEventListener('@rr', _onOpeReleaseRate);
            newMMLEventListener('@tl', _onOpeTotalLevel);
            newMMLEventListener('@ml', _onOpeMultiple);
            newMMLEventListener('@dt', _onOpeDetune);
            newMMLEventListener('@ph', _onOpePhase);
            newMMLEventListener('@fx', _onOpeFixedNote);
            newMMLEventListener('@se', _onOpeSSGEnvelop);
            setMMLEventListener(MMLEvent.MOD_PARAM, _onOpeParameter);
            newMMLEventListener('s',   _onSustain);
            
            // modulation
            newMMLEventListener('@lfo', _onLFO);
            newMMLEventListener('mp', _onPitchModulation);
            newMMLEventListener('ma', _onAmplitudeModulation);
            
            // envelop
            newMMLEventListener('@fps', _onEnvelopFPS);
            envelopEventID = 
            newMMLEventListener('@@', _onToneEnv);
            newMMLEventListener('na', _onAmplitudeEnv);
            newMMLEventListener('np', _onPitchEnv);
            newMMLEventListener('nt', _onNoteEnv);
            newMMLEventListener('nf', _onFilterEnv);
            newMMLEventListener('_@@', _onToneReleaseEnv);
            newMMLEventListener('_na', _onAmplitudeReleaseEnv);
            newMMLEventListener('_np', _onPitchReleaseEnv);
            newMMLEventListener('_nt', _onNoteReleaseEnv);
            newMMLEventListener('_nf', _onFilterReleaseEnv);
            newMMLEventListener('!na', _onAmplitudeEnvTSSCP);
            /**/
            newMMLEventListener('po', _onPortament);
            
            // processing events
            _registerProcessEvent();
            
            //setMMLEventListener(MMLEvent.REGISTER);

            // set initial values of operators
            module.initOperatorParam.ar     = 63;
            module.initOperatorParam.dr     = 0;
            module.initOperatorParam.sr     = 0;
            module.initOperatorParam.rr     = 28;
            module.initOperatorParam.sl     = 0;
            module.initOperatorParam.tl     = 0;
            module.initOperatorParam.ksr    = 0;
            module.initOperatorParam.ksl    = 0;
            module.initOperatorParam.fmul   = 128;
            module.initOperatorParam.dt1    = 0;
            module.initOperatorParam.detune = 0;
            module.initOperatorParam.ams    = 1;
            module.initOperatorParam.phase  = 0;
            module.initOperatorParam.fixedPitch = 0;
            module.initOperatorParam.modLevel   = 5;
            module.initOperatorParam.setPGType(SiOPMTable.PG_SQUARE);
            
            // parser settings
            setting.defaultBPM        = 120;
            setting.defaultLValue     = 4;
            setting.defaultQuantRatio = 6;
            setting.maxQuantRatio     = 8;
            setting.defaultOctave     = 5;
            setting.maxVolume         = 32;
            setting.defaultVolume     = 16;
            setting.maxFineVolume     = 128;
            setting.defaultFineVolume = 64;
        }
        
        
        
        
    // operation for all tracks
    //--------------------------------------------------
        /** Get track instance. This function only is available after prepareProcess. */
        public function getTrack(trackIndex:int) : SiMMLSequencerTrack
        {
            return (trackIndex < _trackCount) ? _tracks[trackIndex] : null;
        }
        
        
        /** Reset all tracks. */
        public function resetAllTracks() : void
        {
            var i:int, trk:SiMMLSequencerTrack;
            for (i=0; i<_trackCount; i++) {
                trk = _tracks[i];
                trk.reset();
                trk.masterVolume = setting.defaultFineVolume;
                trk.velocity     = setting.defaultVolume<<3;
                trk.quantRatio   = setting.defaultQuantRatio / setting.maxQuantRatio;
                trk.quantCount   = calcSampleCount(setting.defaultQuantCount);
            }
            _processedSampleCount = 0;
        }
        
        
        
        
    // operation for controlable tracks
    //--------------------------------------------------
        /** Get free controlable track */
        public function getFreeControlableTrack() : SiMMLSequencerTrack
        {
            var i:int;
            for (i=_trackCount-1; i>=0; i--) {
                if (!_tracks[i].isActive) return _tracks[i];
            }
            return null;
        }
        
        
        /** Get free controlable track */
        public function findControlableTrack(note:int) : SiMMLSequencerTrack
        {
            var i:int;
            for (i=_trackCount-1; i>=0; i--) {
                if (_tracks[i].isControlable && _tracks[i].note == note) return _tracks[i];
            }
            return null;
        }
        
        
        /** new controlable track */
        public function newControlableTrack() : SiMMLSequencerTrack
        {
            var trk:SiMMLSequencerTrack = (_trackCount < _tracks.length) ? _tracks[_trackCount] : (new SiMMLSequencerTrack());
            trk._initialize(null, 60, _trackCount);
            trk.reset();
            trk.masterVolume = setting.defaultFineVolume;
            trk.velocity     = setting.defaultVolume<<3;
            trk.quantRatio   = setting.defaultQuantRatio / setting.maxQuantRatio;
            trk.quantCount   = calcSampleCount(setting.defaultQuantCount);
            _tracks[_trackCount] = trk;
            _trackCount++;
            return trk;
        }
        
        
        
        
    // process
    //--------------------------------------------------
        /** Prepare to process audio.
         *  @param bufferSize Buffering size of processing samples at once.
         *  @param resetParams Reset all channel parameters.
         */
        override public function prepareProcess(data:MMLData, bufferSize:int) : void
        {
            // initialize module and all channels
            module.initialize(bufferSize);
            module.reset();
            _trackCount = 0;
            _processedSampleCount = 0;
            
            // call super function
            super.prepareProcess(data, bufferSize);
            
            if (mmlData) {
                // initialize all tracks
                var trk:SiMMLSequencerTrack;
                var seq:MMLSequence = mmlData.sequenceGroup.headSequence;
                var idx:int = 0;

                // initialize sequence tracks
                while (seq) {
                    trk = (idx < _tracks.length) ? _tracks[idx] : (new SiMMLSequencerTrack());
                    _tracks[idx] = trk._initialize(seq, mmlData.defaultFPS, idx);
                    seq = seq.nextSequence;
                    idx++;
                }
                _trackCount = idx;
            }

            // reset 
            resetAllTracks();
        }
        

        /** Process all tracks. Calls onProcess() inside. This funciton must be called after prepareProcess().
         *  @return Returns true when all processes are finished.
         */
        override public function process() : Boolean
        {
            var ret:Boolean = true, i:int, bufferingTick:int;
            
            // prepare buffering
            for (i=0; i<_trackCount; i++) {
                _tracks[i].channel.prepareBuffer();
            }
            
            // buffering
            startGlobalSequence();
            do {
                bufferingTick = executeGlobalSequence();
                for (i=0; i<_trackCount; i++) {
                    currentTrack = _tracks[i];
                    ret = processMMLExecutor(currentTrack.executor, bufferingTick) && ret;
                }
            } while (!isEndGlobalSequence());
            
            _processedSampleCount += module.bufferLength;
            return ret;
        }
        

        /** Dummy process. This funciton must be called after prepareProcess().
         *  @param length dumming sample count.
         */
        public function dummyProcess(sampleCount:int) : Boolean
        {
            var i:int, bufferingTick:int, count:int,
                bufCount:int = sampleCount / module.bufferLength;
            
            if (bufCount == 0) return true;
            
            // register dummy processing events
            _registerDummyProcessEvent();
            
            var ret:Boolean = true; 

            for (count=0; count<bufCount; count++) {
                // prepare buffering
                for (i=0; i<_trackCount; i++) {
                    _tracks[i].channel.prepareBuffer();
                }
                // buffering
                startGlobalSequence();
                do {
                    bufferingTick = executeGlobalSequence();
                    for (i=0; i<_trackCount; i++) {
                        currentTrack = _tracks[i];
                        ret = processMMLExecutor(currentTrack.executor, bufferingTick) && ret;
                    }
                } while (!isEndGlobalSequence());
            }
            
            // register standard processing events
            _registerProcessEvent();

            return ret;
        }
        
        
        
        
    // implements
    //--------------------------------------------------
        /** onInitialize */
        override protected function onInitialize() : void
        {
        }
        

        /** Preprocess mml string */
        override protected function onBeforeCompile(mml:String) : String
        {
            var codeA:int = "A".charCodeAt();
            var codeH:int = "-".charCodeAt();
            var comrex:RegExp = new RegExp("/\\*.*?\\*/|//.*?[\\r\\n]+", "gms");
            var reprex:RegExp = new RegExp("!\\[(\\d*)(.*?)(!\\|(.*?))?!\\](\\d*)", "gms");
            var seqrex:RegExp = new RegExp("[ \\t\\r\\n]*(#([A-Z@\\-]+)(\\+=|=)?)?([^;{]*({.*?})?[^;]*);", "gms"); //}
            var midrex:RegExp = new RegExp("([A-Z])?(-([A-Z])?)?", "g");
            var expmml:String, res:*, midres:*, c:int, i:int, imax:int, str1:String, str2:String, concat:Boolean, startID:int, endID:int;

            // reset
            _resetParserParameters();
            
            // remove comments
            mml += "\n";
            mml = mml.replace(comrex, "");
            
            // format last
            i = mml.length;
            do {
                if (i == 0) return null;
                str1 = mml.charAt(--i);
            } while (" \t\r\n".indexOf(str1) != -1);
            mml = mml.substring(0, i+1);
            if (str1 != ";") mml += ";";

            // expand macros
            expmml = "";
            res = seqrex.exec(mml);
            while (res) {
                // normal sequence
                if (res[1] == undefined) {
                    expmml += _expandMacro(res[4]) + ";";
                } else 
                
                // system command
                if (res[3] == undefined) {
                    if (String(res[2]) == 'END') {
                        // #END command
                        break;
                    } else
                    // parse system command
                    if (!_parseSystemCommandBefore(String(res[1]), res[4])) {
                        // if the function returns false, parse system command after compiling mml.
                        expmml += String(res[0]);
                    }
                } else 
                
                // macro definition
                {
                    str2 = String(res[2]);
                    concat = (res[3] == "+=");
                    // parse macro IDs
                    midrex.lastIndex = 0;
                    midres = midrex.exec(str2);
                    while (midres[0]) {
                        startID = (midres[1]) ? (String(midres[1]).charCodeAt() - codeA) : 0;
                        endID   = (midres[2]) ? ((midres[3]) ? (String(midres[3]).charCodeAt()-codeA) : MACRO_SIZE-1) : startID;
                        for (i=startID; i<=endID; i++) {
                            if (concat) { macroStrings[i] += (macroExpandDynamic) ? String(res[4]) : _expandMacro(res[4]); }
                            else        { macroStrings[i]  = (macroExpandDynamic) ? String(res[4]) : _expandMacro(res[4]); }
                        }
                        midres = midrex.exec(str2);
                    }
                }
                
                // next
                res = seqrex.exec(mml);
            }
            
            // expand repeat
            expmml = expmml.replace(reprex, 
                function() : String {
                    imax = (arguments[1].length > 0) ? (int(arguments[1])-1) : (arguments[5].length > 0) ? (int(arguments[5])-1) : 1;
                    if (imax > 256) imax = 256;
                    str2 = arguments[2];
                    if (arguments[3]) str2 += arguments[4];
                    for (i=0, str1=""; i<imax; i++) { str1 += str2; }
                    str1 += arguments[2];
                    return str1;
                }
            );
            
            //trace(mml); trace(expmml);
            return expmml;
        }
        
        
        /** Postprocess of compile. */
        override protected function onAfterCompile(seqGroup:MMLSequenceGroup) : void
        {
            // parse system command after parsing
            var seq:MMLSequence = seqGroup.headSequence;
            while (seq) {
                if (seq.isSystemCommand()) {
                    // parse system command
                    seq = _parseSystemCommandAfter(seqGroup, seq);
                } else {
                    // normal sequence
                    seq = seq.nextSequence;
                }
            }
        }
        
        
        /** Callback when table event was found. */
        override protected function onTableParse(prev:MMLEvent, table:String) : void
        {
            if (prev.id < envelopEventID || envelopEventID+10 < prev.id) throw _errorInternalTable();
            // {
            var rex:RegExp = /\{([^}]*)\}(.*)/ms;
            var res:* = rex.exec(table);
            var dat:String = String(res[1]);
            var pfx:String = String(res[2]);
            if (!_parseTableMacro(dat, pfx)) throw _errorParameterNotValid("{..}", dat);
            SiMMLData(mmlData)._setEnvelopTable(_internalTableIndex, _tempNumberList.next, _tempNumberListLast);
            prev.data = _internalTableIndex;
            _tempNumberList.next = null;
            _internalTableIndex--;
        }
        
        
        /** Processing audio */
        override protected function onProcess(sampleLength:int, e:MMLEvent) : void
        {
            currentTrack.process(sampleLength);
        }
        
        
        /** Callback when the tempo is changed. */
        override protected function onTempoChanged(changingRatio:Number) : void
        {
            for (var i:int=0; i<_trackCount; i++) {
                _tracks[i].executor._onTempoChanged(changingRatio);
            }
        }
        
        
        
        
    // sub routines for parser
    //--------------------------------------------------
        /** reset parser parameters. */
        protected function _resetParserParameters() : void
        {
            var i:int;
            
            // initialize
            _internalTableIndex = 511;
            _title = "";
            setting.octavePolarization = 1;
            setting.volumePolarization = 1;
            setting.defaultQuantRatio  = 6;
            setting.maxQuantRatio      = 8;
            macroExpandDynamic = false;
            MMLParser.keySign = "C";
            for (i=0; i<macroStrings.length; i++) {
                macroStrings[i] = "";
            }
        }
        
        
        /** Expand macro. */
        protected function _expandMacro(m:*, recursive:Boolean=false) : String
        {
            if (!recursive) macroExpanded = 0;
            if (m == undefined) return "";
            var charCodeA:int = "A".charCodeAt(0);
            return String(m).replace(/([A-Z])(\(([\-\d]+)\))?/g, 
                function() : String {
                    var t:int, i:int, f:int;
                    i = String(arguments[1]).charCodeAt() - charCodeA;
                    f = 1 << i;
                    if (macroExpanded && f) throw _errorCircularReference(m);
                    if (macroStrings[i]) {
                        if (arguments[2].length > 0) {
                            if (arguments[3].length > 0) t = int(arguments[3]);
                            return "!@ns" + String(t) + ((macroExpandDynamic) ? _expandMacro(macroStrings[i], true) : macroStrings[i]) + "!@ns" + String(-t);
                        }
                        return (macroExpandDynamic) ? _expandMacro(macroStrings[i], true) : macroStrings[i];
                    }
                    return "";
                }
            );
        }
        
        
        
        
    // system command parser
    //--------------------------------------------------
        /** Parse system command before parsing mml. returns false when it hasnt parsed. */
        protected function _parseSystemCommandBefore(cmd:String, prm:String) : Boolean
        {
            var i:int, param:SiOPMChannelParam
            
            // separating
            var rex:RegExp = /\s*(\d*)\s*(\{(.*?)\})?(.*)/ms;
            var res:* = rex.exec(prm);
            
            // abstructing
            var num:int        = int(res[1]),                       // number before {...} block
                noData:Boolean = (res[2] == undefined),             // true when no {...} block
                dat:String     = (noData) ? "" : String(res[3]),    // data string (inside of {...} block)
                pfx:String     = String(res[4]);                    // postfix string
            
            // executing
            switch (cmd) {
                // tone settings
                case '#@':    { __parseToneParam(Translator.parseParam);    return true; }
                case '#OPM@': { __parseToneParam(Translator.parseOPMParam); return true; }
                case '#OPN@': { __parseToneParam(Translator.parseOPNParam); return true; }
                case '#OPL@': { __parseToneParam(Translator.parseOPLParam); return true; }
                case '#OPX@': { __parseToneParam(Translator.parseOPXParam); return true; }
                case '#MA@':  { __parseToneParam(Translator.parseMA3Param); return true; }
                    
                // parser settings
                case '#TITLE': { mmlData.title = (noData) ? pfx : dat; return true; }
                case '#FPS':   { mmlData.defaultFPS = (num>0) ? num : ((noData) ? 60 : int(dat)); return true; }
                case '#SIGN':  { MMLParser.keySign = (noData) ? pfx : dat; return true; }
                case '#MACRO': { 
                    if (noData) dat = pfx; 
                         if (dat == "dynamic") macroExpandDynamic = true;
                    else if (dat == "static")  macroExpandDynamic = false;
                    else throw _errorParameterNotValid("#MACRO", dat);
                    return true;
                }
                case '#QUANT': {
                    if (num>0) {
                        setting.maxQuantRatio     = num;
                        setting.defaultQuantRatio = int(num*0.75);
                    }
                }
                case '#REV': {
                    if (noData) dat = pfx;
                    if (dat == "") {
                        setting.octavePolarization = -1;
                        setting.volumePolarization = -1;
                    } else 
                    if (dat == "octave") {
                        setting.octavePolarization = -1;
                    } else 
                    if (dat == "volume") {
                        setting.volumePolarization = -1;
                    } else {
                        throw _errorParameterNotValid("#REVERSE", dat);
                    }
                    return true;
                }

                // tables
                case '#TABLE': {
                    if (num < 0 || num > 254)        throw _errorParameterNotValid("#TABLE", String(num));
                    if (!_parseTableMacro(dat, pfx)) throw _errorParameterNotValid("#TABLE", dat);
                    SiMMLData(mmlData)._setEnvelopTable(num, _tempNumberList.next, _tempNumberListLast);
                    _tempNumberList.next = null;
                    return true;
                }
                case '#WAV': {
                    if (num < 0 || num > 255) throw _errorParameterNotValid("#WAV", String(num));
                    mmlData.setWaveTable(num, _parseWavMacro(dat, pfx), 5);
                    return true;
                }
                case '#WAVB': {
                    if (num < 0 || num > 255) throw _errorParameterNotValid("#WAVB", String(num));
                    mmlData.setWaveTable(num, _parseWavbMacro((noData) ? pfx : dat), 5);
                    return true;
                }
                case '#PRPCM': {
                    if (num < 0 || num > 255) throw _errorParameterNotValid("#PRPCM", String(num));
                    _parsePreRenderPCM(dat, pfx);
                    return true;
                }
                    
                // system command after parsing
                case '#FM':
                    return false;
                
                // currently not suported
                case '#WAVEXP':
                case '#PCMB':
                case '#PCMC':
                    throw _errorSystemCommand("#" + cmd + " is not supported currently.");
                    
                // error
                default:
                    throw _errorSystemCommand("#" + cmd + " is not supported.");
            }
            
            throw _errorUnknown("@_parseSystemCommandBefore()");
            
            
            function __parseToneParam(func:Function) : void {
                param = SiMMLData(mmlData)._getSiOPMChannelParam(num);
                func(param, dat);
                if (pfx.length > 0) __parseInitSequence(param, pfx);
            }
        }
        
        
        /** Parse system command after parsing mml. */
        protected function _parseSystemCommandAfter(seqGroup:MMLSequenceGroup, syscmd:MMLSequence) : MMLSequence
        {
            var letter:String = syscmd.getSystemCommand();
            var rex:RegExp = /#(FM)[{ \\t\\r\\n]*([^}]*)/;
            var res:* = rex.exec(letter);
            
            // skip system command
            var seq:MMLSequence = syscmd.removeFromChain();
            
            // parse command
            if (res) {
                switch (res[1]) {
                case 'FM':
                    if (res[2] == undefined) throw _errorSystemCommand(letter);
                    connector.parse(res[2]);
                    seq = connector.connect(seqGroup, seq);
                    break;
                default:
                    throw _errorSystemCommand(letter);
                    break;
                }
            }
            
            return seq.nextSequence;
        }
        
        
        
        
    // system command parser subs
    //--------------------------------------------------
        static private var _tempNumberList    :SLLint = SLLint.alloc(0);
        static private var _tempNumberListLast:SLLint = null;
        static private var _tempWaveTable     :Vector.<Number> = new Vector.<Number>(1024, false);

        
        // #TABLE
        private function _parseTableMacro(dat:String, pfx:String) : Boolean
        {
            return (__parseTableNumbers(dat, pfx, 8192) != null);
        }
        
        
        // #WAV
        private function _parseWavMacro(dat:String, pfx:String) : Vector.<Number>
        {
            var i:int, j:int, jmax:int, v:Number;
            
            var num:SLLint = __parseTableNumbers(dat, pfx, 32);
            for (i=0; i<32 && num!=null; i++) {
                v = (num.i + 0.5) * 0.0078125;
                _tempWaveTable[j++] = (v>1) ? 1 : (v<-1) ? -1 : v;
                num = num.next;
            }
            while (i<32) { _tempWaveTable[i++] = 0; }
            
            return _tempWaveTable;
        }
        
        
        // #WAVB
        private function _parseWavbMacro(dat:String) : Vector.<Number>
        {
            var ub:int, i:int, j:int, jmax:int, v:Number;
            
            dat = dat.replace(/\s+/gm, '');
            for (i=0; i<32; i++) {
                ub = (i*2+1 < dat.length) ? int("0x" + dat.substr(i*2,2)) : 0;
                _tempWaveTable[j++] = (ub<128) ? (ub * 0.0078125) : ((ub-256) * 0.0078125);
            }
            
            return _tempWaveTable;
        }
        
        
        // #PRPCM
        private function _parsePreRenderPCM(dat:String, pfx:String) : void
        {
            return;
            
/*
            var seq:MMLSequence, count:int, prev:MMLEvent, e:MMLEvent;
            
            // parse
            //var seqGroup:MMLSequenceGroup = newSequenceGroup().parse(_expandMacro(dat));

            // expand internal tables
            for (seq = seqGroup.headSequence; seq != null; seq = seq.nextSequence) {
                count = seq.headEvent.data;
                if (count == 0) continue;
                for (prev = seq.headEvent; prev.next != null; prev = e) {
                    e = prev.next;
                    if (e.id == MMLEvent.TABLE_EVENT) {
                        _callOnTableParse(prev);
                        e = prev;
                    }
                }
            }
            
            // #FM connections
            onAfterParse(seqGroup);
*/
        }
        
        
        // parse initializing sequence, called by __splitDataString()
        private function __parseInitSequence(param:SiOPMChannelParam, mml:String) : void
        {
            var seq:MMLSequence = param.initSequence;
            var prev:MMLEvent, e:MMLEvent;
            
            MMLParser.prepareParse(setting, mml);
            e = MMLParser.parse();
            
            if (e != null) {
                seq._cutout(e);
                for (prev = seq.headEvent; prev.next != null; prev = e) {
                    e = prev.next;
                    // initializing sequence cannot include procssing events
                    if (e.length != 0) throw _errorInitSequence(mml);
                    // initializing sequence cannot include % and @.
                    if (e.id == MMLEvent.MOD_TYPE || e.id == MMLEvent.MOD_PARAM) throw _errorInitSequence(mml);
                    // parse table event
                    if (e.id == MMLEvent.TABLE_EVENT) {
                        callOnTableParse(prev);
                        e = prev;
                    }
                }
            }
        }
        
        
        // parse table numbers
        private function __parseTableNumbers(dat:String, pfx:String, maxIndex:int) : SLLint
        {
            var index:int = 0, i:int, imax:int, j:int, v:int, ti0:int, ti1:int, tr:Number, 
                t:Number, s:Number, r:Number, o:Number, jmax:int, last:SLLint, rep:SLLint;
            var regexp:RegExp, res:*, array:Array, itpl:Vector.<int> = new Vector.<int>();

            // clear list
            if (_tempNumberList.next) {
                _tempNumberListLast.next = null;
                SLLint.freeList(_tempNumberList.next);
                _tempNumberList.next = null;
                _tempNumberListLast = null;
            }
            
            // initialize
            last = _tempNumberList;
            rep = null;

            // magnification
            regexp = /(\d+)?(\*(-?[\d.]+))?(([+-])([\d.]+))?/;
            res    = regexp.exec(pfx);
            jmax = (res[1]) ? int(res[1]) : 1;
            r    = (res[2]) ? Number(res[3]) : 1;
            o    = (res[4]) ? ((res[5] == '+') ? Number(res[6]) : -Number(res[6])) : 0;
            
            // res[1];(n..),m {res[2];n, res[3];m} / res[4];n / res[5];|
            regexp = /(\(([,\-\d\s]+)\)[,\s]*(\d+))|(-?\d+)|(\|)/gm;
            res    = regexp.exec(dat);
            while (res && index<maxIndex) {
                if (res[1]) {
                    // interpolation "(res[2]..),res[3]"
                    array = String(res[2]).split(/[,\s]+/);
                    imax = int(res[3]);
                    if (imax < 2 || array.length < 1) throw _errorParameterNotValid("#WAV", dat);
                    itpl.length = array.length;
                    for (i=0; i<itpl.length; i++) { itpl[i] = int(array[i]); }
                    if (itpl.length > 1) {
                        t = 0;
                        s = Number(itpl.length - 1) / imax;
                        for (i=0; i<imax && index<maxIndex; i++) {
                            ti0 = int(t);
                            ti1 = ti0 + 1;
                            tr  = t - Number(ti0);
                            v = int(itpl[ti0] * (1-tr) + itpl[ti1] * tr + 0.5);
                            v = int(v * r + o + 0.5);
                            for (j=0; j<jmax; j++, index++) {
                                last.next = SLLint.alloc(v);
                                last = last.next;
                            }
                            t += s;
                        }
                    } else {
                        // repeat
                        v = int(itpl[0] * r + o + 0.5);
                        for (i=0; i<imax && index<maxIndex; i++) {
                            for (j=0; j<jmax; j++, index++) {
                                last.next = SLLint.alloc(v);
                                last = last.next;
                            }
                        }
                    }
                } else
                if (res[4]) {
                    // single number
                    v = int(int(res[4]) * r + o + 0.5);
                    for (j=0; j<jmax; j++) {
                        last.next = SLLint.alloc(v);
                        last = last.next;
                    }
                    index++;
                } else 
                if (res[5]) {
                    // repeat point
                    rep = last;
                } else {
                    // unknown error
                    throw _errorUnknown("@parseWav()");
                }
                res = regexp.exec(dat);
            }
            
            //for(var e:SLLint=_tempNumberList.next; e!=null; e=e.next) { trace(e.i); }
            
            _tempNumberListLast = last;
            if (rep) last.next = rep.next;
            // returns length
            return _tempNumberList.next;
        }
        
        
        
        
    // event handlers
    //----------------------------------------------------------------------------------------------------
        // register process events
        private function _registerProcessEvent() : void {
            setMMLEventListener(MMLEvent.NOP,       _default_onNoOperation);
            setMMLEventListener(MMLEvent.PROCESS,   _default_onProcess);
            setMMLEventListener(MMLEvent.REST,      _onRest);
            setMMLEventListener(MMLEvent.NOTE,      _onNote);
            setMMLEventListener(MMLEvent.SLUR,      _onSlur);
            setMMLEventListener(MMLEvent.SLUR_WEAK, _onSlurWeak);
            setMMLEventListener(MMLEvent.PITCHBEND, _onPitchBend);
        }
        
        // register dummy process events
        private function _registerDummyProcessEvent() : void {
            setMMLEventListener(MMLEvent.NOP,       _nop);
            setMMLEventListener(MMLEvent.PROCESS,   _dummy_onProcess);
            setMMLEventListener(MMLEvent.REST,      _dummy_onProcessEvent);
            setMMLEventListener(MMLEvent.NOTE,      _dummy_onProcessEvent);
            setMMLEventListener(MMLEvent.SLUR,      _dummy_onProcessEvent);
            setMMLEventListener(MMLEvent.SLUR_WEAK, _dummy_onProcessEvent);
            setMMLEventListener(MMLEvent.PITCHBEND, _dummy_onProcessEvent);
        }
        
        // dummy process event
        private function _dummy_onProcessEvent(e:MMLEvent) : MMLEvent
        {
            return currentExecutor.publishProessingEvent(e);
        }
        
        
    // processing events
    //--------------------------------------------------
        // rest
        private function _onRest(e:MMLEvent) : MMLEvent
        {
            currentTrack._setRest();
            return currentExecutor.publishProessingEvent(e);
        }
        
        // note
        private function _onNote(e:MMLEvent) : MMLEvent
        {
            currentTrack._setNote(e.data, calcSampleCount(e.length));
            return currentExecutor.publishProessingEvent(e);
        }
        
        // &
        private function _onSlur(e:MMLEvent) : MMLEvent
        {
            currentTrack._setSlur();
            return currentExecutor.publishProessingEvent(e);
        }
    
        // &&
        private function _onSlurWeak(e:MMLEvent) : MMLEvent
        {
            currentTrack._setSlurWeak();
            return currentExecutor.publishProessingEvent(e);
        }
        
        // *
        private function _onPitchBend(e:MMLEvent) : MMLEvent
        {
            if (e.next == null || e.next.id != MMLEvent.NOTE) return e.next;    // check next note
            var term:int = calcSampleCount(e.length);                           // chenging time
            currentTrack._setPitchBend(e.next.data, term);                       // pitch bending
            return currentExecutor.publishProessingEvent(e);
        }
        
        
    // driver track events
    //--------------------------------------------------
        // quantize ratio
        private function _onQuantRatio(e:MMLEvent) : MMLEvent
        {
            if (currentTrack.eventMask & MASK_QUANTIZE) return e.next;  // check mask
            currentTrack.quantRatio = e.data / setting.maxQuantRatio;   // quantize ratio
            return e.next;
        }
        
        // quantize count
        private function _onQuantCount(e:MMLEvent) : MMLEvent
        {
            e = e.getParameters(_p, 2);
            _p[0] = (_p[0] == int.MIN_VALUE) ? 0 : (_p[0] * setting.resolution / setting.maxQuantCount);
            _p[1] = (_p[1] == int.MIN_VALUE) ? 0 : (_p[1] * setting.resolution / setting.maxQuantCount);
            if (currentTrack.eventMask & MASK_QUANTIZE) return e.next;  // check mask
            currentTrack.quantCount = calcSampleCount(_p[0]);           // quantize count
            currentTrack.keyOnDelay = calcSampleCount(_p[1]);           // key on delay
            return e.next;
        }

        // @mask
        private function _onEventMask(e:MMLEvent) : MMLEvent
        {
            currentTrack.eventMask = (e.data != int.MIN_VALUE) ? e.data : 0;
            return e.next;
        }

        // k
        private function _onDetune(e:MMLEvent) : MMLEvent
        {
            currentTrack.pitchShift = (e.data == int.MIN_VALUE) ? 0 : e.data;
            return e.next;
        }
    
        // kt
        private function _onKeyTrans(e:MMLEvent) : MMLEvent
        {
            currentTrack.noteShift = (e.data == int.MIN_VALUE) ? 0 : e.data;
            return e.next;
        }
    
        // !@kr
        private function _onRelativeDetune(e:MMLEvent) : MMLEvent
        {
            currentTrack.pitchShift += (e.data == int.MIN_VALUE) ? 0 : e.data;
            return e.next;
        }

    
    // envelop events
    //--------------------------------------------------
        // @fps
        private function _onEnvelopFPS(e:MMLEvent) : MMLEvent
        {
            var frame:int = (e.data == int.MIN_VALUE || e.data == 0) ? 60 : e.data;
            if (frame > 1000) frame = 1000;
            currentTrack.setEnvelopFPS(frame);
            return e.next;
        }
        
        // @@
        private function _onToneEnv(e:MMLEvent) : MMLEvent
        {
            e = e.getParameters(_p, 2);
            if (currentTrack.eventMask & MASK_ENVELOP) return e.next;   // check mask
            if (_p[1] == int.MIN_VALUE) _p[1] = 1;
            currentTrack.setToneEnvelop(1, _p[0], _p[1]);
            return e.next;
        }
        
        // na
        private function _onAmplitudeEnv(e:MMLEvent) : MMLEvent
        {
            e = e.getParameters(_p, 2);
            if (currentTrack.eventMask & MASK_ENVELOP) return e.next;   // check mask
            if (_p[1] == int.MIN_VALUE) _p[1] = 1;
            currentTrack.setAmplitudeEnvelop(1, _p[0], _p[1]);
            return e.next;
        }
        
        // !na
        private function _onAmplitudeEnvTSSCP(e:MMLEvent) : MMLEvent
        {
            e = e.getParameters(_p, 2);
            if (currentTrack.eventMask & MASK_ENVELOP) return e.next;   // check mask
            if (_p[1] == int.MIN_VALUE) _p[1] = 1;
            currentTrack.setAmplitudeEnvelop(1, _p[0], _p[1], true);
            return e.next;
        }
        
        // np
        private function _onPitchEnv(e:MMLEvent) : MMLEvent
        {
            e = e.getParameters(_p, 2);
            if (currentTrack.eventMask & MASK_ENVELOP) return e.next;   // check mask
            if (_p[1] == int.MIN_VALUE) _p[1] = 1;
            currentTrack.setPitchEnvelop(1, _p[0], _p[1]);
            return e.next;
        }
        
        // nt
        private function _onNoteEnv(e:MMLEvent) : MMLEvent
        {
            e = e.getParameters(_p, 2);
            if (currentTrack.eventMask & MASK_ENVELOP) return e.next;   // check mask
            if (_p[1] == int.MIN_VALUE) _p[1] = 1;
            currentTrack.setNoteEnvelop(1, _p[0], _p[1]);
            return e.next;
        }
    
        // nf
        private function _onFilterEnv(e:MMLEvent) : MMLEvent
        {
            e = e.getParameters(_p, 2);
            if (currentTrack.eventMask & MASK_ENVELOP) return e.next;   // check mask
            if (_p[1] == int.MIN_VALUE) _p[1] = 1;
            currentTrack.setFilterEnvelop(1, _p[0], _p[1]);
            return e.next;
        }
        
        // _@@
        private function _onToneReleaseEnv(e:MMLEvent) : MMLEvent
        {
            e = e.getParameters(_p, 2);
            if (currentTrack.eventMask & MASK_ENVELOP) return e.next;   // check mask
            if (_p[1] == int.MIN_VALUE) _p[1] = 1;
            currentTrack.setToneEnvelop(0, _p[0], _p[1]);
            return e.next;
        }
        
        // _na
        private function _onAmplitudeReleaseEnv(e:MMLEvent) : MMLEvent
        {
            e = e.getParameters(_p, 2);
            if (currentTrack.eventMask & MASK_ENVELOP) return e.next;   // check mask
            if (_p[1] == int.MIN_VALUE) _p[1] = 1;
            currentTrack.setAmplitudeEnvelop(0, _p[0], _p[1]);
            return e.next;
        }
        
        // _np
        private function _onPitchReleaseEnv(e:MMLEvent) : MMLEvent
        {
            e = e.getParameters(_p, 2);
            if (currentTrack.eventMask & MASK_ENVELOP) return e.next;   // check mask
            if (_p[1] == int.MIN_VALUE) _p[1] = 1;
            currentTrack.setPitchEnvelop(0, _p[0], _p[1]);
            return e.next;
        }
        
        // _nt
        private function _onNoteReleaseEnv(e:MMLEvent) : MMLEvent
        {
            e = e.getParameters(_p, 2);
            if (currentTrack.eventMask & MASK_ENVELOP) return e.next;   // check mask
            if (_p[1] == int.MIN_VALUE) _p[1] = 1;
            currentTrack.setNoteEnvelop(0, _p[0], _p[1]);
            return e.next;
        }
    
        // _nf
        private function _onFilterReleaseEnv(e:MMLEvent) : MMLEvent
        {
            e = e.getParameters(_p, 2);
            if (currentTrack.eventMask & MASK_ENVELOP) return e.next;   // check mask
            if (_p[1] == int.MIN_VALUE) _p[1] = 1;
            currentTrack.setFilterEnvelop(0, _p[0], _p[1]);
            return e.next;
        }

    
    // internal table envelop events
    //--------------------------------------------------
        // @f
        private function _onFilter(e:MMLEvent) : MMLEvent
        {
            e = e.getParameters(_p, 10);
            var cut:int = (_p[0] == int.MIN_VALUE) ? 128 : _p[0],
                res:int = (_p[1] == int.MIN_VALUE) ?   0 : _p[1],
                ar :int = (_p[2] == int.MIN_VALUE) ?   0 : _p[2],
                dr1:int = (_p[3] == int.MIN_VALUE) ?   0 : _p[3],
                dr2:int = (_p[4] == int.MIN_VALUE) ?   0 : _p[4],
                rr :int = (_p[5] == int.MIN_VALUE) ?   0 : _p[5],
                dc1:int = (_p[6] == int.MIN_VALUE) ? 128 : _p[6],
                dc2:int = (_p[7] == int.MIN_VALUE) ?  64 : _p[7],
                sc :int = (_p[8] == int.MIN_VALUE) ?  32 : _p[8],
                rc :int = (_p[9] == int.MIN_VALUE) ? 128 : _p[9];
            
            if (cut == 128 && res == 0 && ar == 0 && rr == 0) {
                currentTrack.channel.activateFilter(false);
            } else {
                currentTrack.channel.activateFilter(true);
                currentTrack.channel.setFilterResonance(res);
                currentTrack.channel.setFilterEnvelop(ar, dr1, dr2, rr, cut, dc1, dc2, sc, rc);
            }
            return e.next;
        }

        // @lfo[cycle_frames],[ws]
        private function _onLFO(e:MMLEvent) : MMLEvent
        {
            // get parameters
            e = e.getParameters(_p, 2);
            currentTrack.channel.initializeLFO((_p[1] == int.MIN_VALUE) ? SiOPMTable.LFO_WAVE_TRIANGLE : _p[1]);
            currentTrack.channel.setLFOCycleTime((_p[0] == int.MIN_VALUE) ? 333 : _p[0]*1000/60);
            return e.next;
        }
        
        // mp [depth],[end_depth],[delay],[term]
        private function _onPitchModulation(e:MMLEvent) : MMLEvent
        {
            e = e.getParameters(_p, 4);
            if (currentTrack.eventMask & MASK_MODULATE) return e.next;   // check mask
            if (_p[0] == int.MIN_VALUE) _p[0] = 0;
            if (_p[1] == int.MIN_VALUE) _p[1] = 0;
            if (_p[2] == int.MIN_VALUE) _p[2] = 0;
            if (_p[3] == int.MIN_VALUE) _p[3] = 0;
            currentTrack.setModulationEnvelop(true, _p[0], _p[1], _p[2], _p[3]);
            return e.next;
        }
        
        // ma [depth],[end_depth],[delay],[term]
        private function _onAmplitudeModulation(e:MMLEvent) : MMLEvent
        {
            e = e.getParameters(_p, 4);
            if (currentTrack.eventMask & MASK_MODULATE) return e.next;   // check mask
            if (_p[0] == int.MIN_VALUE) _p[0] = 0;
            if (_p[1] == int.MIN_VALUE) _p[1] = 0;
            if (_p[2] == int.MIN_VALUE) _p[2] = 0;
            if (_p[3] == int.MIN_VALUE) _p[3] = 0;
            currentTrack.setModulationEnvelop(false, _p[0], _p[1], _p[2], _p[3]);
            return e.next;
        }
        
        // po
        private function _onPortament(e:MMLEvent) : MMLEvent
        {
            if (e.data == int.MIN_VALUE) e.data = 0;
            currentTrack.setPortament(e.data);
            return e.next;
        }
        
        
    // i/o events
    //--------------------------------------------------
        // v
        private function _onVolume(e:MMLEvent) : MMLEvent
        {
            if (currentTrack.eventMask & MASK_VOLUME) return e.next;  // check mask
            currentTrack.velocity = e.data<<3;                        // velocity (data<<3 = 16->128)
            return e.next;
        }
        
        // (, )
        private function _onVolumeShift(e:MMLEvent) : MMLEvent
        {
            if (currentTrack.eventMask & MASK_VOLUME) return e.next;  // check mask
            currentTrack.velocity += e.data<<3;                       // velocity (data<<3 = 16->128)
            return e.next;
        }
    
        // x
        private function _onExpression(e:MMLEvent) : MMLEvent
        {
            if (currentTrack.eventMask & MASK_VOLUME) return e.next; // check mask
            var x:int = (e.data == int.MIN_VALUE) ? 128 : e.data;    // default value = 128
            currentTrack.expression = x;                             // expression
            return e.next;
        }

        // @v
        private function _onMasterVolume(e:MMLEvent) : MMLEvent
        {
            if (currentTrack.eventMask & MASK_VOLUME) return e.next;    // check mask
            currentTrack.masterVolume = e.data;                         // master volume
            return e.next;
        }
        
        // p
        private function _onPan(e:MMLEvent) : MMLEvent
        {
            if (currentTrack.eventMask & MASK_PAN) return e.next;               // check mask
            currentTrack.pan = (e.data == int.MIN_VALUE) ? 0 : (e.data<<4)-64;  // pan
            return e.next;
        }

        // @p
        private function _onFinePan(e:MMLEvent) : MMLEvent
        {
            if (currentTrack.eventMask & MASK_PAN) return e.next;         // check mask
            currentTrack.pan = (e.data == int.MIN_VALUE) ? 0 : (e.data);  // pan
            return e.next;
        }
        
        // @i
        private function _onInput(e:MMLEvent) : MMLEvent
        {
            e = e.getParameters(_p, 2);
            if (_p[0] == int.MIN_VALUE) _p[0] = 5;
            if (_p[1] == int.MIN_VALUE) _p[1] = 0;
            currentTrack.channel.setInput(_p[0], _p[1]);
            return e.next;
        }
        
        // @o
        private function _onOutput(e:MMLEvent) : MMLEvent
        {
            e = e.getParameters(_p, 2);
            if (_p[0] == int.MIN_VALUE) _p[0] = 2;
            if (_p[1] == int.MIN_VALUE) _p[1] = 0;
            currentTrack.channel.setOutput(_p[0], _p[1]);
            return e.next;
        }
        
        // @r
        private function _onRingModulation(e:MMLEvent) : MMLEvent
        {
            e = e.getParameters(_p, 2);
            if (_p[0] == int.MIN_VALUE) _p[0] = 4;
            if (_p[1] == int.MIN_VALUE) _p[1] = 0;
            currentTrack.channel.setRingModulation(_p[0], _p[1]);
            return e.next;
        }
        
        
    // sound channel events
    //--------------------------------------------------
        // %
        private function _onModuleType(e:MMLEvent) : MMLEvent
        {
            e = e.getParameters(_p, 2);
            if (_p[0] < 0 || _p[0] >= SiMMLTable.MT_MAX) _p[0] = SiMMLTable.MT_ALL;
            currentTrack.setChannelModuleType(_p[0], _p[1]);
            return e.next;
        }
        
        // %e
        private function _onModuleEffect(e:MMLEvent) : MMLEvent
        {
            e = e.getParameters(_p, 2);
            var id:int = _p[0] + SiMMLTable.MT_EFFECT;
            if (id < SiMMLTable.MT_EFFECT || id >= SiMMLTable.MT_EFFECT_MAX) _p[0] = SiMMLTable.MT_DELAY;
            currentTrack.setChannelModuleType(id, _p[1]);
            return e.next;
        }
    
        // @al
        private function _onAlgorism(e:MMLEvent) : MMLEvent
        {
            e = e.getParameters(_p, 2);
            if (currentTrack.eventMask & MASK_OPERATOR) return e.next;      // check mask
            var cnt:int = (_p[0] != int.MIN_VALUE) ? _p[0] : 0;
            var alg:int = (_p[1] != int.MIN_VALUE) ? _p[1] : SiMMLTable.instance.alg_init[cnt];
            currentTrack.channel.setAlgorism(cnt, alg);
            return e.next;
        }
        
        // @
        private function _onOpeParameter(e:MMLEvent) : MMLEvent
        {
            e = e.getParameters(_p, PARAM_MAX);
            if (currentTrack.eventMask & MASK_OPERATOR) return e.next;      // check mask
            var seq:MMLSequence = currentTrack.setChannelParameters(_p);
            if (seq) {
                seq.connectBefore(e.next);
                return seq.headEvent.next;
            }
            return e.next;
        }
        
        // @fb
        private function _onFeedback(e:MMLEvent) : MMLEvent
        {
            e = e.getParameters(_p, 2);
            if (currentTrack.eventMask & MASK_OPERATOR) return e.next;      // check mask
            var fb :int = (_p[0] != int.MIN_VALUE) ? _p[0] : 0;
            var fbc:int = (_p[1] != int.MIN_VALUE) ? _p[1] : 0;
            currentTrack.channel.setFeedBack(fb, fbc);
            return e.next;
        }
        
        // i
        private function _onSlotIndex(e:MMLEvent) : MMLEvent
        {
            if (currentTrack.eventMask & MASK_OPERATOR) return e.next;      // check mask
            currentTrack.channel.activeOperatorIndex = (e.data == int.MIN_VALUE) ? 4 : e.data;
            return e.next;
        }

        
        // @rr
        private function _onOpeReleaseRate(e:MMLEvent) : MMLEvent
        {
            e = e.getParameters(_p, 2);
            if (currentTrack.eventMask & MASK_OPERATOR) return e.next;      // check mask
            if (_p[0] != int.MIN_VALUE) currentTrack.channel.rr = _p[0];
            if (_p[1] == int.MIN_VALUE) _p[1] = 0;
            currentTrack.setReleaseSweep(_p[1]);
            return e.next;
        }
        
        // @tl
        private function _onOpeTotalLevel(e:MMLEvent) : MMLEvent
        {
            if (currentTrack.eventMask & MASK_OPERATOR) return e.next;      // check mask
            currentTrack.channel.tl = (e.data == int.MIN_VALUE) ? 0 : e.data;
            return e.next;
        }
        
        // @ml
        private function _onOpeMultiple(e:MMLEvent) : MMLEvent
        {
            e = e.getParameters(_p, 2);
            if (currentTrack.eventMask & MASK_OPERATOR) return e.next;      // check mask
            if (_p[0] == int.MIN_VALUE) _p[0] = 0;
            if (_p[1] == int.MIN_VALUE) _p[1] = 0;
            currentTrack.channel.fmul = (_p[0] << 7) + _p[1];
            return e.next;
        }
        
        // @dt
        private function _onOpeDetune(e:MMLEvent) : MMLEvent
        {
            if (currentTrack.eventMask & MASK_OPERATOR) return e.next;      // check mask
            currentTrack.channel.detune = (e.data == int.MIN_VALUE) ? 0 : e.data;
            return e.next;
        }
        
        // @ph
        private function _onOpePhase(e:MMLEvent) : MMLEvent
        {
            if (currentTrack.eventMask & MASK_OPERATOR) return e.next;      // check mask
            currentTrack.channel.phase = e.data;
            return e.next;
        }
        
        // @fx
        private function _onOpeFixedNote(e:MMLEvent) : MMLEvent
        {
            e = e.getParameters(_p, 2);
            if (currentTrack.eventMask & MASK_OPERATOR) return e.next;      // check mask
            if (_p[0] == int.MIN_VALUE) _p[0] = 0;
            if (_p[1] == int.MIN_VALUE) _p[1] = 0;
            currentTrack.channel.fixedPitch = (_p[0] << 6) + _p[1];
            return e.next;
        }
        
        // @se
        private function _onOpeSSGEnvelop(e:MMLEvent) : MMLEvent
        {
            if (currentTrack.eventMask & MASK_OPERATOR) return e.next;      // check mask
            currentTrack.channel.ssgec = (e.data == int.MIN_VALUE) ? 0 : e.data;
            return e.next;
        }
        
        // s
        private function _onSustain(e:MMLEvent) : MMLEvent
        {
            e = e.getParameters(_p, 2);
            if (currentTrack.eventMask & MASK_OPERATOR) return e.next;      // check mask
            if (_p[0] != int.MIN_VALUE) currentTrack.channel.setAllReleaseRate(_p[0]);
            if (_p[1] == int.MIN_VALUE) _p[1] = 0;
            currentTrack.setReleaseSweep(_p[1]);
            return e.next;
        }
        
        
        
        
    // errors
    //--------------------------------------------------
        private function _errorSyntax(str:String) : Error
        {
            return new Error("SiMMLSequencer error : Syntax error. " + str);
        }
        
        
        private function _errorOutOfRange(cmd:String, n:int) : Error
        {
            return new Error("SiMMLSequencer error : Out of range. '" + cmd + "' = " + String(n));
        }
        
        
        private function _errorToneParameterNotValid(cmd:String, chParam:int, opParam:int) : Error
        {
            return new Error("SiMMLSequencer error : Parameter count is not valid in '" + cmd + "'. " + String(chParam) + " parameters for channel and " + String(opParam) + " parameters for each operator.");
        }
        
        
        private function _errorParameterNotValid(cmd:String, param:String) : Error
        {
            return new Error("SiMMLSequencer error : Parameter not valid. '" + param + "' in " + cmd);
        }
        
            
        private function _errorInternalTable() : Error
        {
            return new Error("SiMMLSequencer error : Internal table is available only for envelop commands.");
        }
        
        
        private function _errorCircularReference(mcr:String) : Error
        {
            return new Error("SiMMLSequencer error : Circular reference in dynamic macro. " + mcr);
        }
        
        
        private function _errorInitSequence(mml:String) : Error
        {
            return new Error("SiMMLSequencer error : Initializing sequence cannot include note, rest, '%' nor '@'. " + mml);
        }
        
        
        private function _errorSystemCommand(str:String) : Error
        {
            return new Error("SiMMLSequencer error : System command error. "+str);
        }
        
        
        private function _errorUnknown(str:String) : Error
        {
            return new Error("SiMMLSequencer error : Unknown. "+str);
        }
    }
}

