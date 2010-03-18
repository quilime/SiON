// Synthesizer using various frequency modulation sound chip
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound.synthesizer {
    import org.si.sion.*;
    import org.si.sion.sequencer.SiMMLTrack;
    import org.si.sound.base.SoundObject;
    
    
    /** Synthesizer using various frequency modulation sound chip
     */
    public class FMSynth extends SynthesizerBase
    {
    // namespace
    //----------------------------------------
        use namespace _synthesizer_internal;
        
        
        
        
    // variables
    //----------------------------------------
        /** FM Operators vector [m1,c1,m2,c2] */
        public var operators:Vector.<FMSynthOperator>;
        
        
        
        
    // properties
    //----------------------------------------
        /** ALG; connection algorism [0-15]. */
        public function get alg() : int { return _voice.channelParam.alg; }
        public function set alg(i:int) : void {
            if ( _voice.channelParam.alg == i || i<0 || i>15) return;
             _voice.channelParam.alg = i;
            _requireVoiceUpdate = true;
        }
        
        /** FB; feedback [0-7]. */
        public function get fb() : int { return _voice.channelParam.fb; }
        public function set fb(i:int) : void {
            if ( _voice.channelParam.fb == i || i<0 || i>7) return;
             _voice.channelParam.fb = i;
            _requireVoiceUpdate = true;
        }
        
        /** FBC; feedback connection [0-3]. */
        public function get fbc() : int { return _voice.channelParam.fbc; }
        public function set fbc(i:int) : void {
            if ( _voice.channelParam.fbc == i || i<0 || i>3) return;
             _voice.channelParam.fbc = i;
            _requireVoiceUpdate = true;
        }
        
        
        /** @private */
        public function set voice(v:SiONVoice) : void {
            _voice.copyFrom(v); // copy from passed voice
            _requireVoiceUpdate = true;
        }
        
        
        
        
    // constructor
    //----------------------------------------
        /** constructor */
        function FMSynth()
        {
            _requireVoiceUpdate = false;
            _voice = new SiONVoice();
            operators = new Vector.<FMSynthOperator>(4);
            for (var i:int=0; i<4; i++) operators[i] = new FMSynthOperator(this, i);
        }
        
        
        
        
    // operation
    //----------------------------------------
    }
}


