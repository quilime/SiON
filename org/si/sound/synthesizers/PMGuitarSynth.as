// Physical Modeling Guitar Synthesizer 
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound.synthesizers {
    import org.si.sion.*;
    import org.si.sion.sequencer.SiMMLTrack;
    import org.si.sound.SoundObject;
    
    
    /** Physical Modeling Guitar Synthesizer (NOT IMPLEMENTED)
     */
    public class PMGuitarSynth extends BasicSynth
    {
    // namespace
    //----------------------------------------
        use namespace _synthesizer_internal;
        
        
        
        
    // variables
    //----------------------------------------
        /** @private [protected] plunk velocity [0-1]. */
        protected var _plunkVelocity:Number;
        
        
        
        
    // properties
    //----------------------------------------
        /** string tensoin [0-1]. */
        public function get tensoin() : Number { return _voice.pmsTension * 0.015873015873015872; }
        public function set tensoin(t:Number) : void {
            _voice.pmsTension = t * 63;
            _voiceUpdateNumber++;
/*
            var i:int, imax:int = _tracks.length, ch:SiOPMChannelFM;
            for (i=0; i<imax; i++) {
                ch = _tracks[i].channel as SiOPMChannelKS;
                if (ch != null) {
                    ch.operator[0].setAllReleaseRate(_voice.pmsTension);
                }
            }
*/        
        }
        
        
        /** strength of left hand mute [0-1]. */
        public function get mute() : Number { return _voice.pmsTension * 0.015873015873015872; }
        public function set mute(t:Number) : void {
            _voice.pmsTension = t * 63;
            _voiceUpdateNumber++;
/*
            var i:int, imax:int = _tracks.length, ch:SiOPMChannelFM;
            for (i=0; i<imax; i++) {
                ch = _tracks[i].channel as SiOPMChannelKS;
                if (ch != null) {
                    ch.operator[0].setAllReleaseRate(_voice.pmsTension);
                }
            }
*/        
        }
        
        
        /** plunk velocity [0-1]. */
        public function get plunkVelocity() : Number { return _plunkVelocity; }
        public function set plunkVelocity(v:Number) : void {
            _plunkVelocity = (v<0) ? 0 : (v>1) ? 1 : v;
            _voice.channelParam.operatorParam[0].tl = (_plunkVelocity==0) ? 127 : _plunkVelocity * 64;
            _voiceUpdateNumber++;
        }
        
        
        
        
        
    // constructor
    //----------------------------------------
        /** constructor 
         *  @param tension sustain rate of the tone
         */
        function PMGuitarSynth(tension:Number=0.125)
        {
        }
        
        
        
        
    // operation
    //----------------------------------------
    }
}


