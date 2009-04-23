//----------------------------------------------------------------------------------------------------
// SiOPM Sampler pad channel.
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------




package org.si.sound.module {
    import org.si.utils.SLLNumber;
    import org.si.utils.SLLint;
    
    
    
    
    /** Sampler pad channel. */
    public class SiOPMChannelSampler extends SiOPMChannelBase
    {
    // valiables
    //--------------------------------------------------
        /** note on flag */  protected var _isNoteOn:Boolean;
        
        /** bank number */   protected var _bankNumber:int;
        /** wave number */   protected var _waveNumber:int;
        /** one shot flag */ protected var _isOneShot:Boolean;
        
        /** expression */    protected var _expression:Number;
        
        /** sample data */   protected var _sample:Vector.<int>;
        /** sample length */ protected var _sampleLength:int;
        /** sample index */  protected var _sampleIndex:int;
        /** phase reset */   protected var _samplePhaseReset:Boolean;
        /** channel count */ protected var _sampleChannelCount:int;
        
        
        
        
    // toString
    //--------------------------------------------------
        /** Output parameters. */
        public function toString() : String
        {
            var str:String = "SiOPMChannelSampler : ";
            $2("vol", _volume[0]*_expression,  "pan", _pan-64);
            return str;
            function $2(p:String, i:*, q:String, j:*) : void { str += "  " + p + "=" + String(i) + " / " + q + "=" + String(j) + "\n"; }
        }
        
        
        
        
    // constructor
    //--------------------------------------------------
        /** constructor */
        function SiOPMChannelSampler(chip:SiOPMModule)
        {
            super(chip);
        }




    // parameter setting
    //--------------------------------------------------
        /** Set by SiOPMChannelParam. 
         *  @param param SiOPMChannelParam.
         *  @param withVolume Set volume when its true.
         */
        override public function setSiOPMChannelParam(param:SiOPMChannelParam, withVolume:Boolean) : void
        {
            var i:int;
            if (param.opeCount == 0) return;
            
            if (withVolume) {
                var imax:int = SiOPMModule.STREAM_SIZE_MAX;
                for (i=0; i<imax; i++) _volume[i] = param.volumes[i];
                for (_hasEffectSend=false, i=1; i<imax; i++) if (_volume[i] > 0) _hasEffectSend = true;
                _pan = param.pan;
            }
        }
        
        
        /** Get SiOPMChannelParam.
         *  @param param SiOPMChannelParam.
         */
        override public function getSiOPMChannelParam(param:SiOPMChannelParam) : void
        {
            var i:int, imax:int = SiOPMModule.STREAM_SIZE_MAX;
            for (i=0; i<imax; i++) param.volumes[i] = _volume[i];
            param.pan = _pan;
        }
        
        
        
        
    // interfaces
    //--------------------------------------------------
        /** Set algorism (@al) 
         *  @param cnt Operator count.
         *  @param alg Algolism number of the operator's connection.
         */
        override public function setAlgorism(cnt:int, alg:int) : void
        {
        }
        
        
        /** Set parameters (@ command). */
        override public function setParameters(param:Vector.<int>) : void
        {
        }
        
        
        
        
    // interfaces
    //--------------------------------------------------
        /** pitch = (note << 6) | (kf & 63) [0,8191] */
        override public function get pitch() : int { return _waveNumber<<6; }
        override public function set pitch(p:int) : void {
            _waveNumber = p >> 6;
        }
        
        
        
        
    // volume controls
    //--------------------------------------------------
        /** update all tl offsets of final carriors */
        override public function offsetVolume(expression:int, velocity:int) : void {
            _expression = expression * velocity * 0.00006103515625; // 1/16384
        }
        
        /** phase (@ph) */
        override public function set phase(i:int) : void {
            _samplePhaseReset = (i!=-1);
        }
        
        
        
        
    // operation
    //--------------------------------------------------
        /** Initialize. */
        override public function initialize(prev:SiOPMChannelBase, bufferIndex:int) : void
        {
            _isNoteOn = false;
            _bankNumber = 0;
            _waveNumber = -1;
            _isOneShot = false;
            _sample = null;
            _sampleLength = 0;
            _sampleIndex = 0;
            _samplePhaseReset = true;
            _sampleChannelCount = 1;
            _expression = 0.5;
            super.initialize(prev, bufferIndex);
        }
        
        
        /** Reset. */
        override public function reset() : void
        {
            _isNoteOn = false;
            _isIdling = true;
            _bankNumber = 0;
            _waveNumber = -1;
            _isOneShot = false;
            _sample = null;
            _sampleLength = 0;
            _sampleIndex = 0;
            _samplePhaseReset = true;
            _sampleChannelCount = 1;
            _expression = 0.5;
        }
        
        
        /** Note on. */
        override public function noteOn() : void
        {
            if (_waveNumber >= 0) {
                _isNoteOn = true;
                _isIdling = false;
                var idx:int = _waveNumber + (_bankNumber<<7) + SiOPMTable.PG_SAMPLE;
                _sample = _table.waveTables[idx];
                _sampleLength = _sample.length;
                _sampleChannelCount = _table.waveFixedBits[idx];
                if (_samplePhaseReset) _sampleIndex = 0;
            }
        }
        
        
        /** Note off. */
        override public function noteOff() : void
        {
            _isNoteOn = false;
            if (!_isOneShot) {
                _isIdling = true;
                _sample = null;
                _sampleLength = 0;
            }
        }
        
        
        /** Check note on */
        override public function isNoteOn() : Boolean
        {
            return _isNoteOn;
        }
        
        
        /** Prepare buffering */
        override public function prepareBuffer() : void
        {
            _bufferIndex = 0;
            _isIdling = false;
        }
        
        
        /** Buffering */
        override public function buffer(len:int) : void
        {
            var i:int, imax:int, vol:Number;
            if (_isIdling || _sample == null) {
                _nop(len);  // idling
            } else {
                var residureLen:int = _sampleLength - _sampleIndex,
                    procLen:int = (len < residureLen) ? len : residureLen;
                if (_hasEffectSend) {
                    imax = _chip.streamBuffer.length;
                    for (i=0; i<imax; i++) {
                        vol = _volume[i] * _expression;
                        if (vol > 0) _chip.streamBuffer[i].writeVectorInt(_sample, _sampleIndex, _bufferIndex, procLen, vol, _pan, _sampleChannelCount);
                    }
                } else {
                    vol = _volume[0] * _expression;
                    _chip.streamBuffer[0].writeVectorInt(_sample, _sampleIndex, _bufferIndex, procLen, vol, _pan, _sampleChannelCount);
                }
                if (len > procLen) _nop(len - procLen);
            }
            
            // update buffer index
            _bufferIndex += len;
            _sampleIndex += len;
        }
    }
}

