//----------------------------------------------------------------------------------------------------
// SiOPM sound channel base class
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------




package org.si.sound.module {
    import org.si.utils.SLLint;
    import org.si.utils.SLLNumber;
    
    
    
    
    /** SiOPM sound channel base class. */
    public class SiOPMChannelBase
    {
    // constants
    //--------------------------------------------------
        static public const OUTPUT_STANDARD:int = 0;
        static public const OUTPUT_OVERWRITE:int = 1;
        static public const OUTPUT_ADD:int = 2;
        
        static public const INPUT_ZERO:int = 0;
        static public const INPUT_PIPE:int = 1;
        static public const INPUT_FEEDBACK:int = 2;
        
        static public const EG_ATTACK:int = 0;
        static public const EG_DECAY1:int = 1;
        static public const EG_DECAY2:int = 2;
        static public const EG_SUSTAIN:int = 3;
        static public const EG_RELEASE:int = 4;
        static public const EG_OFF:int = 5;
        
        
        
        
    // valiables
    //--------------------------------------------------
        /** table */
        protected var _table:SiOPMTable;
        /** chip */
        protected var _chip:SiOPMModule;
        /** standard stereo out (_chip.outputBuffer) */
        protected var _output:SLLNumber;
        /** functor to process */
        protected var _funcProcess:Function = _nop;
        
        // Pipe buffer
        /** buffering index */  protected var _bufferIndex:int;
        /** input level */      protected var _inputLevel:int;
        /** ringmod level */    protected var _ringmodLevel:Number;
        /** input level */      protected var _inputMode:int;
        /** output mode */      protected var _outputMode:int;
        /** in pipe */          protected var _inPipe  :SLLint;
        /** ringmod pipe */     protected var _ringPipe:SLLint;
        /** base pipe */        protected var _basePipe:SLLint;
        /** out pipe */         protected var _outPipe :SLLint;
        
        // Volume
        /** left volume */      protected var _left_volume :Number;
        /** right volume */     protected var _right_volume:Number;
        
        // LPFilter
        /** filter switch */    protected var _filterOn:Boolean;
        /** cutoff frequency */ protected var _cutoff:int;
        /** cutoff frequency */ protected var _cutoff_offset:int;
        /** resonance */        protected var _resonance:Number;
        /** previous I */       protected var _prevI:int;
        /** previous V */       protected var _prevV:int;
        /** eg step residue */  protected var _prevStepRemain:int;
        /** eg step */          protected var _filter_eg_step:int;
        /** eg phase shift l.*/ protected var _filter_eg_next:int;
        /** eg direction */     protected var _filter_eg_cutoff_inc:int;
        /** eg state */         protected var _filter_eg_state:int;
        /** eg rate */          protected var _filter_eg_time:Vector.<int>;
        /** eg level */         protected var _filter_eg_cutoff:Vector.<int>;
        
        // Low frequency oscillator
        /** frequency ratio */  protected var _freq_ratio:int;
        /** lfo switch */       protected var _lfo_on:int;
        /** lfo timer */        protected var _lfo_timer:int;
        /** lfo timer step */   protected var _lfo_timer_step:int;
        /** lfo phase */        protected var _lfo_phase:int;
        /** lfo wave table */   protected var _lfo_waveTable:Vector.<int>;
        /** lfo wave shape */   protected var _lfo_waveShape:int;
        

        
        
    // constructor
    //--------------------------------------------------
        /** Constructor @param chip Managing SiOPMModule. */
        function SiOPMChannelBase(chip:SiOPMModule)
        {
            _table = SiOPMTable.instance;
            _chip = chip;
            _isActive = false;
            
            _filter_eg_time   = new Vector.<int>(6, true);
            _filter_eg_cutoff = new Vector.<int>(6, true);
        }
        
        
        
        
    // interfaces
    //--------------------------------------------------
        /** Set by SiOPMChannelParam. */
        public function setSiOPMChannelParam(param:SiOPMChannelParam, withVolume:Boolean) : void {}
        /** Get SiOPMChannelParam. */
        public function getSiOPMChannelParam(param:SiOPMChannelParam) : void {}
        
        /** algorism (@al) */
        public function setAlgorism(cnt:int, alg:int) : void {}
        /** feedback (@fb) */
        public function setFeedBack(fb:int, fbc:int) : void {}
        /** parameters (@ call from SiMMLSequencerTrack.setChannelParameters()) */
        public function setParameters(param:Vector.<int>) : void {}
        /** pgType & ptType (@ call from SiMMLChannelSetting.selectTone()/initializeTone()) */
        public function setType(pgType:int, ptType:int) : void {}
        /** Release rate (s) */
        public function setAllReleaseRate(rr:int) : void {}
        
        /** active operator index (i). */
        public function set activeOperatorIndex(i:int) : void { }
        /** Release rate (@rr) */
        public function set rr(r:int) : void {}
        /** total level (@tl)  */
        public function set tl(i:int) : void {}
        /** fine multiple (@ml)  */
        public function set fmul(i:int) : void {}
        /** phase (@ph) */
        public function set phase(i:int) : void {}
        /** detune (@dt) */
        public function set detune(i:int) : void {}
        /** fixed pitch (@fx) */
        public function set fixedPitch(i:int) : void {}
        /** ssgec (@se) */
        public function set ssgec(i:int) : void {}
        
        /** pitch */
        public function get pitch()      : int  { return 0; }
        public function set pitch(i:int) : void {}
        
        
        
        
    // volume control
    //--------------------------------------------------
        /** Stereo volume */
        public function setStereoVolume(l:Number, r:Number) : void
        {
            _left_volume  = l;
            _right_volume = r;
        }
        
        
        /** offset volume */
        public function offsetVolume(expression:int, velocity:int) : void
        {
        }
        
        
        
        
    // LFO control
    //--------------------------------------------------
        /** set chip "PSEUDO" frequency ratio by [%]. */
        public function setFrequencyRatio(ratio:int) : void
        {
            _freq_ratio = ratio;
        }
        
        
        /** initialize LFO */
        public function initializeLFO(waveform:int) : void
        {
            waveform = (0<=waveform && waveform<=3) ? waveform : SiOPMTable.LFO_WAVE_TRIANGLE;
            _lfo_waveTable = _table.lfo_waveTables[waveform];
            _lfo_waveShape = waveform;
            _lfo_timer = 1;
            _lfo_timer_step = 0;
            _lfo_phase = 0;
        }
        
        
        /** set LFO cycle time */
        public function setLFOCycleTime(ms:Number) : void
        {
            _lfo_timer = 0;
            // 0.17294117647058824 = 44100/(1000*255)
            _lfo_timer_step = SiOPMTable.LFO_TIMER_INITIAL/(ms*0.17294117647058824);
            
            //set OPM LFO frequency
            //_lfo_timer = 0;
            //_lfo_timer_step = _table.lfo_timerSteps[freq & 255];
        }
        
        
        /** amplitude modulation (ma) */
        public function setAmplitudeModulation(depth:int) : void {}
        
        
        /** pitch modulation (mp) */
        public function setPitchModulation(depth:int) : void {}
        
        
        
        
    // filter control
    //--------------------------------------------------
        /** Filter activation */
        public function activateFilter(b:Boolean) : void
        {
            _filterOn = b;
        }
        
        
        /** LP Filter envelop (@f).
         *  @param ar attack rate.
         *  @param dr1 decay rate 1.
         *  @param dr2 decay rate 2.
         *  @param rr release rate.
         *  @param ac initial cutoff.
         *  @param dc1 decay cutoff level 1.
         *  @param dc2 decay cutoff level 2.
         *  @param sc sustain cutoff level.
         *  @param rc release cutoff level.
         */
        public function setFilterEnvelop(ar:int, dr1:int, dr2:int, rr:int, ac:int, dc1:int, dc2:int, sc:int, rc:int) : void
        {
            _filter_eg_cutoff[EG_ATTACK]  = (ac<0)  ? 0 : (ac>128)  ? 128 : ac;
            _filter_eg_cutoff[EG_DECAY1]  = (dc1<0) ? 0 : (dc1>128) ? 128 : dc1;
            _filter_eg_cutoff[EG_DECAY2]  = (dc2<0) ? 0 : (dc2>128) ? 128 : dc2;
            _filter_eg_cutoff[EG_SUSTAIN] = (sc<0)  ? 0 : (sc>128)  ? 128 : sc;
            _filter_eg_cutoff[EG_RELEASE] = 0;
            _filter_eg_cutoff[EG_OFF]     = (rc<0) ? 0 : (rc>128) ? 128 : rc;
            _filter_eg_time  [EG_ATTACK]  = _table.filter_eg_rate[ar & 63];
            _filter_eg_time  [EG_DECAY1]  = _table.filter_eg_rate[dr1 & 63];
            _filter_eg_time  [EG_DECAY2]  = _table.filter_eg_rate[dr2 & 63];
            _filter_eg_time  [EG_SUSTAIN] = int.MAX_VALUE;
            _filter_eg_time  [EG_RELEASE] = _table.filter_eg_rate[rr & 63];
            _filter_eg_time  [EG_OFF]     = int.MAX_VALUE;
        }
        
        
        /** LP Filter resonance (@f) [0,9]. */
        public function setFilterResonance(i:int) : void
        {
            i = 1 << (9 - ((i<0) ? 0 : (i>9) ? 9 : i));
            _resonance = i * 0.001953125;   // 0.001953125=1/512
        }
        
        
        /** LP Filter cutoff offset (nf) */
        public function setFilterOffset(i:int) : void
        {
            _cutoff_offset = i-128;
        }
        
        
        
        
    // connection control
    //--------------------------------------------------
        /** Set input pipe (@i). 
         *  @param level Input level. The value for a standard FM sound module is 15.
         *  @param pipeIndex Input pipe index (0-3).
         */
        public function setInput(level:int, pipeIndex:int) : void
        {
            var i:int;

            // pipe index
            pipeIndex &= 3;
            
            // input level
            _inputLevel = level;
            
            // set pipe
            if (level > 0) {
                _inPipe = _chip.getPipe(pipeIndex);
                for (i=0; i<_bufferIndex; i++) { _inPipe = _inPipe.next; }
                _inputMode = INPUT_PIPE;
            } else {
                _inPipe = _chip.zeroBuffer;
                _inputMode = INPUT_ZERO;
            }
        }
        
        
        /** Set ring modulation pipe (@r).
         *  @param level. Input level(0-8).
         *  @param pipeIndex Input pipe index (0-3).
         */
        public function setRingModulation(level:int, pipeIndex:int) : void
        {
            var i:int;

            // pipe index
            pipeIndex &= 3;
            
            // ring modulation level
            _ringmodLevel = level*4/Number(1<<SiOPMTable.LOG_VOLUME_BITS);
            
            // set pipe
            if (level > 0) {
                _ringPipe = _chip.getPipe(pipeIndex);
                for (i=0; i<_bufferIndex; i++) { _ringPipe = _ringPipe.next; }
            } else {
                _ringPipe = null;
            }
        }
        
        
        /** Set output pipe  (@o).
         *  @param outputMode Output mode. 0=standard stereo out, 1=overwrite pipe. 2=add pipe.
         *  @param pipeIndex Output pipe index (0-3).
         */
        public function setOutput(outputMode:int, pipeIndex:int) : void
        {
            if (pipeIndex > 3) return;
            var i:int, flagAdd:Boolean;

            // set pipe
            if (outputMode == OUTPUT_STANDARD) {
                flagAdd = false;        // ovewrite mode
                pipeIndex = 4;          // pipe[4] is used.
            } else {
                flagAdd = (outputMode == OUTPUT_ADD);  // ovewrite/additional mode
            }

            // output mode
            _outputMode = outputMode;

            // set output pipe
            _outPipe = _chip.getPipe(pipeIndex);
            for (i=0; i<_bufferIndex; i++) { _outPipe = _outPipe.next; }
            
            // set base pipe
            _basePipe = (flagAdd) ? (_outPipe) : (_chip.zeroBuffer);
        }
        
        
        
        
    // operations
    //--------------------------------------------------
        /** Initialize. */
        public function initialize()   : void
        {
            // output buffer
            _output = _chip.outputBuffer;
            _bufferIndex = 0;
            
            // volume
            _left_volume  = 1;
            _right_volume = 1;
            
            // LFO
            initializeLFO(SiOPMTable.LFO_WAVE_TRIANGLE);
            setLFOCycleTime(1000);
            setFrequencyRatio(100);
            
            // Connection
            setInput(0, 0);
            setRingModulation(0, 0);
            setOutput(OUTPUT_STANDARD, 0);
            
            // LPFilter
            _filterOn = false;
            _prevI = 0;
            _prevV = 0;
            _resonance = 1;
            _cutoff_offset = 0;
            setFilterEnvelop(0, 0, 0, 0, 128, 128, 128, 128, 128);
            shiftLPFilterState(EG_OFF);
        }
        
        
        /** Reset */
        public function reset() : void
        {
        }
        
        
        /** Note on */
        public function noteOn() : void
        {
            // typical operations below
            _lfo_phase = 0;
            if (_filterOn) {
                resetLPFilterState();
                shiftLPFilterState(EG_ATTACK);
            }
        }
        
        
        /** Note off */
        public function noteOff() : void
        {
            // typical operations below
            if (_filterOn) {
                shiftLPFilterState(EG_RELEASE);
            }
        }
        
        
        /** Check note on */
        public function isNoteOn() : Boolean 
        {
            return false;
        }
        
        
        
        
    // processing
    //--------------------------------------------------
        /** Prepare buffering */
        public function prepareBuffer() : void
        {
            _bufferIndex = 0;
        }
        
        
        /** Buffering */
        public function buffer(len:int) : void
        {
            var i:int, n:Number;
            
            // preserve _outPipe
            var monoOut:SLLint = _outPipe;
            
            // processing (update _outPipe inside)
            _funcProcess(len);
            
            // ring modulation here
            if (_ringPipe) _ringModulation(monoOut, len);
            
            // overwrite standard stereo output
            var stereoOut:SLLNumber = _output;
            if (_outputMode == OUTPUT_STANDARD) {
                if (_filterOn) {
                    _LPFilter(monoOut, stereoOut, len);
                } else {
                    for (i=0; i<len; i++) {
                        n = Number(monoOut.i);
                        stereoOut.n      += n * _left_volume;
                        stereoOut.next.n += n * _right_volume;
                        monoOut   = monoOut.next;
                        stereoOut = stereoOut.next.next;
                    }
                    _output = stereoOut;
                }
            } else {
                for (i=0; i<len; i++) {
                    stereoOut = stereoOut.next.next;
                }
                _output = stereoOut;
            }
            
            // update buffer index
            _bufferIndex += len;
        }
        
        
        // ring modulation
        private function _ringModulation(op:SLLint, len:int) : void
        {
            var i:int, rp:SLLint = _ringPipe;
            for (i=0; i<len; i++) {
                op.i *= rp.i * _ringmodLevel;
                rp   = rp.next;
                op   = op.next;
            }
            _ringPipe = rp;
        }
        
        
        // low-pass filter
        private function _LPFilter(monoOut:SLLint, stereoOut:SLLNumber, len:int) : void
        {
            var i:int, step:int, I:int, V:int, out:int, cut:Number, fb:Number;
            out = _cutoff + _cutoff_offset;
            if (out<0) out=0 
            else if (out>128) out=128;
            cut = _table.filter_cutoffTable[out];
            fb  = _resonance;// * _table.filter_feedbackTable[out];

            // previous setting
            step = _prevStepRemain;
            I = _prevI;
            V = _prevV;

            while (len >= step) {
                // processing
                for (i=0; i<step; i++) {
                    I += (Number(monoOut.i) - V - I * fb) * cut;
                    V += I * cut;
                    stereoOut.n      += V * _left_volume;
                    stereoOut.next.n += V * _right_volume;
                    monoOut   = monoOut.next;
                    stereoOut = stereoOut.next.next;
                }
                len -= step;
                
                // change cutoff and shift state
                _cutoff += _filter_eg_cutoff_inc;
                out = _cutoff + _cutoff_offset;
                if (out<0) out=0 
                else if (out>128) out=128;
                cut = _table.filter_cutoffTable[out];
                fb  = _resonance;// * _table.filter_feedbackTable[out];
                if (_cutoff == _filter_eg_next) shiftLPFilterState(_filter_eg_state+1);

                // next step
                step = _filter_eg_step;
            }
            
            // process remains
            for (i=0; i<len; i++) {
                I += (Number(monoOut.i) - V - I * fb) * cut;
                V += I * cut;
                stereoOut.n      += V * _left_volume;
                stereoOut.next.n += V * _right_volume;
                monoOut   = monoOut.next;
                stereoOut = stereoOut.next.next;
            }
            _output = stereoOut;
            
            // next setting
            _prevStepRemain = _filter_eg_step - len;
            _prevI = I;
            _prevV = V;
        }

        
        /** reset LPFilter */
        protected function resetLPFilterState() : void
        {
            _cutoff = _filter_eg_cutoff[EG_ATTACK];
        }
        
        
        /** shift LPFilter state */
        protected function shiftLPFilterState(state:int) : void
        {
            switch (state) {
            case EG_ATTACK:
                if (__shift()) break;
                state++;
                // fail through
            case EG_DECAY1:
                if (__shift()) break; 
                state++;
                // fail through
            case EG_DECAY2:
                if (__shift()) break;
                state++;
                // fail through
            case EG_SUSTAIN:
                // catch all
                _filter_eg_state = EG_SUSTAIN;
                _filter_eg_step  = int.MAX_VALUE;
                _filter_eg_next  = _cutoff + 1;
                _filter_eg_cutoff_inc = 0;
                break;
            case EG_RELEASE:
                if (__shift()) break;
                state++;
                // fail through
            case EG_OFF:
                // catch all
                _filter_eg_state = EG_OFF;
                _filter_eg_step  = int.MAX_VALUE;
                _filter_eg_next  = _cutoff + 1;
                _filter_eg_cutoff_inc = 0;
                break;
            }
            _prevStepRemain = _filter_eg_step;
            
            function __shift() : Boolean
            {
                if (_filter_eg_time[state] == 0) return false;
                _filter_eg_state = state;
                _filter_eg_step  = _filter_eg_time[state];
                _filter_eg_next  = _filter_eg_cutoff[state + 1];
                _filter_eg_cutoff_inc = (_cutoff < _filter_eg_next) ? 1 : -1;
                return (_cutoff != _filter_eg_next);
            }
        }
        
        

        /** No process (default functor of _funcProcess). */
        static protected function _nop(len:int) : void
        {
        }
        
        
        
        
    // for channel manager operation [internal use]
    //--------------------------------------------------
        /** @private [internal use] DLL of channels */
        internal var _isActive:Boolean = false;
        /** @private [internal use] DLL of channels */
        internal var _channelType:int = -1;
        /** @private [internal use] DLL of channels */
        internal var _next:SiOPMChannelBase = null;
        /** @private [internal use] DLL of channels */
        internal var _prev:SiOPMChannelBase = null;
        
        /** channel type */
        public function get channelType() : int { return _channelType; }
    }
}


