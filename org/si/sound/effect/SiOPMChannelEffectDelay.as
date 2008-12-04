//  Distributed under BSD-style license (see org.si.license.txt).




package org.si.sound.effect {
    import org.si.sound.module.SiOPMChannelParam;
    import org.si.sound.module.SiOPMChannelBase;
    import org.si.sound.module.SiOPMModule;
    import org.si.sound.module.SiOPMTable;
    import org.si.utils.SLLint;
    
    
    
    
    /** Delay effect */
    public class SiOPMChannelEffectDelay extends SiOPMChannelBase
    {
    // variables
    //--------------------------------------------------
        private var _delayBuffer:Vector.<int>;
        private var _readPoint:int;
        private var _firstDelay:int;
        private var _feedbackDelay:int;
        private var _feedback:Number;
        
        private var _left_main_volume:Number;
        private var _right_main_volume:Number;
        private var _gain:Number;
        
        
        
    // constructor
    //--------------------------------------------------
        /** Constructor @param chip Managing SiOPMModule. */
        function SiOPMChannelEffectDelay(chip:SiOPMModule)
        {
            super(chip);
            _delayBuffer = new Vector.<int>(1);
            _readPoint = 0;
            _firstDelay = 0;
            _feedbackDelay = 0;
            _feedback = 0;
            _funcProcess = _nop;
            
            _left_main_volume = 1;
            _right_main_volume = 1;
            _gain = 1;
        }
        
        
        
        
    // interfaces
    //--------------------------------------------------
        /** parameters (@ call from SiMMLSequencerTrack.setChannelParameters()) */
        override public function setParameters(param:Vector.<int>) : void 
        {
            if (param[0] == int.MIN_VALUE) param[0] = 0;
            if (param[1] == int.MIN_VALUE) param[1] = 0;
            if (param[2] == int.MIN_VALUE) param[2] = 0;
            setDelay(int(param[0]*44.1), int(param[1]*44.1), param[2]*0.01);
        }
        /** pgType & ptType (@ call from SiMMLChannelSetting.selectTone()/initializeTone()) */
        override public function setType(pgType:int, ptType:int) : void 
        {
        }
        /** feedback (@fb) */
        override public function setFeedBack(fb:int, fbc:int) : void
        {
            _feedback    = fb*0.01;
            _funcProcess = (_firstDelay==0) ? _nop : ((_feedbackDelay==0 || _feedback==0) ? _buffer_fboff : _buffer_fbon);
        }
        
        
        /** Set by SiOPMChannelParam. */
        override public function setSiOPMChannelParam(param:SiOPMChannelParam, withVolume:Boolean) : void {}
        /** Get SiOPMChannelParam. */
        override public function getSiOPMChannelParam(param:SiOPMChannelParam) : void {}
        
        /** algorism (@al) */
        override public function setAlgorism(cnt:int, alg:int) : void {}
        /** Release rate (s) */
        override public function setAllReleaseRate(rr:int) : void {}
        
        /** active operator index (i). */
        override public function set activeOperatorIndex(i:int) : void {}
        /** Release rate (@rr) */
        override public function set rr(r:int) : void {}
        /** total level (@tl)  */
        override public function set tl(i:int) : void {}
        /** fine multiple (@ml)  */
        override public function set fmul(i:int) : void {}
        /** phase (@ph) */
        override public function set phase(i:int) : void {}
        /** detune (@dt) */
        override public function set detune(i:int) : void {}
        /** fixed pitch (@fx) */
        override public function set fixedPitch(i:int) : void {}
        /** ssgec (@se) */
        override public function set ssgec(i:int) : void {}
        
        /** pitch */
        override public function get pitch()      : int  { return 0; }
        override public function set pitch(i:int) : void {}
        
        
        
        
    // volume control
    //--------------------------------------------------
        /** Stereo volume */
        override public function setStereoVolume(l:Number, r:Number) : void
        {
            _left_main_volume  = l;
            _right_main_volume = r;
            _updateVolume();
        }
        
        
        /** offset volume */
        override public function offsetVolume(expression:int, velocity:int) : void
        {
            // 0.00006103515625 = 1/(128*128)
            _gain = expression * velocity * 0.00006103515625;
            _updateVolume();
        }
        
        
        /** Set input pipe (@i). do nothing. */
        override public function setInput(level:int, pipeIndex:int) : void { }
        
        
        /** Set filter envelop */
        override public function setFilterEnvelop(ar:int, dr1:int, dr2:int, rr:int, ac:int, dc1:int, dc2:int, sc:int, rc:int) : void
        {
            super.setFilterEnvelop(ar,dr1,dr2,rr,ac,dc1,dc2,sc,rc);
            // start LP-filter
            _lfo_phase = 0;
            if (_filterOn) {
                resetLPFilterState();
                shiftLPFilterState(EG_ATTACK);
            }
        }
        

        // update volume
        private function _updateVolume() : void
        {
            _left_volume  = _left_main_volume  * _gain;
            _right_volume = _right_main_volume * _gain;
        }
        
        
        
        
    // operations
    //--------------------------------------------------
        /** Initialize. */
        override public function initialize(prev:SiOPMChannelBase)   : void
        {
            super.initialize(prev);
            _funcProcess = _nop;
        }
       
        
        // Do nothing on note event
        override public function noteOn() : void { }
        override public function noteOff() : void { }
        
                
        
        
    // settings
    //--------------------------------------------------
        public function setDelay(firstDelay:int, feedbackDelay:int, feedback:Number) : void
        {
            var i:int, imax:int;

            // set delay time
            _firstDelay    = firstDelay;
            _feedbackDelay = feedbackDelay;
            _feedback      = feedback;
            _funcProcess = (_firstDelay==0) ? _nop : ((_feedbackDelay==0 || _feedback==0) ? _buffer_fboff : _buffer_fbon);
            var bufferSize:int = (_firstDelay > _feedbackDelay) ? _firstDelay : _feedbackDelay;
            
            // expand buffer
            imax = _delayBuffer.length;
            if (bufferSize > imax) {
                do { imax<<=1; } while (bufferSize > imax);
                _delayBuffer.length = imax;
            }
            
            // clear buffer
            for (i=0; i<imax; i++) { _delayBuffer[i] = 0; }
            
            // set input pipe
            _inPipe = _chip.getPipe(4);
            for (i=0; i<_bufferIndex; i++) { _inPipe = _inPipe.next; }
            _readPoint = 0;
        }
        
        
        
        
    // buffering
    //--------------------------------------------------
        private function _buffer_fboff(len:int) : void
        {
            var t:int, i:int, j:int, filter:int = _delayBuffer.length - 1;
            
            // buffering
            var ip:SLLint = _inPipe,
                bp:SLLint = _basePipe,
                op:SLLint = _outPipe;
            for (i=0; i<len; i++) {
                // input
                t = (_readPoint + _firstDelay) & filter;
                _delayBuffer[t] += ip.i;
                // output
                op.i = _delayBuffer[_readPoint] + bp.i;
                _delayBuffer[_readPoint] = 0;
                // increment
                ip = ip.next;
                bp = bp.next;
                op = op.next;
                _readPoint++;
                _readPoint &= filter;
            }
            
            // update pointers
            _inPipe   = ip;
            _basePipe = bp;
            _outPipe  = op;
        }

    
        private function _buffer_fbon(len:int) : void
        {
            var t:int, i:int, filter:int = _delayBuffer.length - 1;
            
            // buffering
            var ip:SLLint = _inPipe,
                bp:SLLint = _basePipe,
                op:SLLint = _outPipe;
            for (i=0; i<len; i++) {
                // input
                t = (_readPoint + _firstDelay) & filter;
                _delayBuffer[t] += ip.i;
                // output
                op.i = _delayBuffer[_readPoint] + bp.i;
                _delayBuffer[_readPoint] = 0;
                // feedback
                t = (_readPoint + _feedbackDelay) & filter;
                _delayBuffer[t] += op.i * _feedback;
                // increment
                ip = ip.next;
                bp = bp.next;
                op = op.next;
                _readPoint++;
                _readPoint &= filter;
            }
            
            // update pointers
            _inPipe   = ip;
            _basePipe = bp;
            _outPipe  = op;
        }
    }
}

