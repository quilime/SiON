// Analog "LIKE" Synthesizer 
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound.synthesizers {
    import org.si.sion.*;
    import org.si.sion.sequencer.SiMMLTrack;
    import org.si.sion.module.SiOPMOperatorParam;
    import org.si.sion.module.SiOPMTable;
    import org.si.sion.module.channels.SiOPMChannelFM;
    import org.si.sound.base.SoundObject;
    
    
    /** Analog "LIKE" Synthesizer 
     */
    public class AnalogSynth extends BasicSynth
    {
    // namespace
    //----------------------------------------
        use namespace _synthesizer_internal;
        
        
        
        
    // constants
    //----------------------------------------
        /** nromal connection */
        static public const CONNECT_NORMAL:int = 0;
        /** ring connection */
        static public const CONNECT_RING:int = 0;
        /** sync connection */
        static public const CONNECT_SYNC:int = 0;
        /** wave shape number of saw wave */
        static public const SAW:int = SiOPMTable.PG_SAW_UP;
        /** wave shape number of square wave */
        static public const SQUARE:int = SiOPMTable.PG_SQUARE;
        /** wave shape number of triangle wave */
        static public const TRIANGLE:int = SiOPMTable.PG_TRIANGLE;
        /** wave shape number of sine wave */
        static public const SINE:int = SiOPMTable.PG_SINE;
        /** wave shape number of noise wave */
        static public const NOISE:int = SiOPMTable.PG_NOISE;
        
        
        
        
    // variables
    //----------------------------------------
        /** operator parameter for op0 */
        protected var _opp0:SiOPMOperatorParam;
        /** operator parameter for op1 */
        protected var _opp1:SiOPMOperatorParam;
        /** mixing balance of 2 oscillators.*/
        protected var _balance:int;
        
        
        
    // properties
    //----------------------------------------
        /** connection algorism of 2 oscillators */
        public function get con() : int { return _voice.channelParam.alg; }
        public function set con(c:int) : void {
            _voice.channelParam.alg = (c<0 || c>2) ? 0 : c;
            _requireVoiceUpdate = true;
        }
        
        
        /** wave shape of 1st oscillator */
        public function get ws1() : int { return _opp0.pgType; }
        public function set ws1(ws:int) : void {
            _opp0.pgType = ws & SiOPMTable.PG_FILTER;
            _opp0.ptType = (ws == NOISE) ? SiOPMTable.PT_PCM : SiOPMTable.PT_OPM;
            var i:int, imax:int = _tracks.length, ch:SiOPMChannelFM;
            for (i=0; i<imax; i++) {
                ch = _tracks[i].channel as SiOPMChannelFM;
                if (ch != null) {
                    ch.operator[0].pgType = _opp0.pgType;
                    ch.operator[0].ptType = _opp0.ptType;
                }
            }
        }
        
        
        /** wave shape of 2nd oscillator */
        public function get ws2() : int { return _opp1.pgType; }
        public function set ws2(ws:int) : void {
            _opp1.pgType = ws & SiOPMTable.PG_FILTER;
            _opp1.ptType = (ws == NOISE) ? SiOPMTable.PT_PCM : SiOPMTable.PT_OPM;
            var i:int, imax:int = _tracks.length, ch:SiOPMChannelFM;
            for (i=0; i<imax; i++) {
                ch = _tracks[i].channel as SiOPMChannelFM;
                if (ch != null) {
                    ch.operator[1].pgType = _opp1.pgType;
                    ch.operator[1].ptType = _opp1.ptType;
                }
            }
        }
        
        
        /** mixing balance of 2 oscillators (-64<->64), -64=1st only, 64=2nd only. */
        public function get balance() : int { return _opp1.pgType; }
        public function set balance(b:int) : void {
            _balance = b;
            if (_balance > 64) _balance = 64;
            else if (_balance < -64) _balance = -64;
            _opp0.tl = SiOPMTable.instance.eg_tlTable[64-_balance] >> SiOPMTable.ENV_LSHIFT;
            _opp1.tl = SiOPMTable.instance.eg_tlTable[_balance+64] >> SiOPMTable.ENV_LSHIFT;
            var i:int, imax:int = _tracks.length, ch:SiOPMChannelFM;
            for (i=0; i<imax; i++) {
                ch = _tracks[i].channel as SiOPMChannelFM;
                if (ch != null) {
                    ch.operator[0].tl = _opp0.tl;
                    ch.operator[1].tl = _opp1.tl;
                }
            }
        }
        
        
        /** pitch difference in osc1 and 2. 64 for 1 halftone. */
        public function get vco2pitch() : int { return _opp1.detune - _opp0.detune; }
        public function set vco2pitch(p:int) : void {
            _opp1.detune = _opp0.detune + p;
            var i:int, imax:int = _tracks.length, ch:SiOPMChannelFM;
            for (i=0; i<imax; i++) {
                ch = _tracks[i].channel as SiOPMChannelFM;
                if (ch != null) {
                    ch.operator[1].detune = _opp1.detune;
                }
            }
        }
        
        
        
        
        
    // constructor
    //----------------------------------------
        /** constructor 
         *  @param connectionType Connection type, 0=normal, 1=ring, 2=sync.
         *  @param ws1 Wave shape for osc1.
         *  @param ws2 Wave shape for osc2.
         *  @param balance mixing balance of 2 osccilators (-64<->64), -64=1st only, 64=2nd only.
         *  @param vco2pitch pitch difference in osc1 and 2. 64 for 1 halftone.
         */
        function AnalogSynth(connectionType:int, ws1:int=0, ws2:int=0, balance:int=0, vco2pitch:int=0)
        {
            super();
            _balance = balance;
            if (_balance > 64) _balance = 64;
            else if (_balance < -64) _balance = -64;
            _voice.setAnalogLike(connectionType, ws1, ws2, _balance, vco2pitch);
            _opp0 = _voice.channelParam.operatorParam[0];
            _opp1 = _voice.channelParam.operatorParam[1];
        }
        
        
        
        
    // operation
    //----------------------------------------
    }
}


