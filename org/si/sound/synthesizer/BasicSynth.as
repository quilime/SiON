// Basic Synthesizer 
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound.synthesizer {
    import org.si.sion.*;
    import org.si.sion.module.SiOPMChannelParam;
    import org.si.sion.sequencer.SiMMLTrack;
    import org.si.sound.base.SoundObject;
    
    
    /** Basic Synthesizer */
    public class BasicSynth extends VoiceReference
    {
    // namespace
    //----------------------------------------
        use namespace _synthesizer_internal;
        
        
        
        
    // variables
    //----------------------------------------
        // tracks to control
        private var _tracks:Vector.<SiMMLTrack>;
        
        
        
        
    // properties
    //----------------------------------------
        /** @private */
        override public function set voice(v:SiONVoice) : void {
            _voice.copyFrom(v); // copy from passed voice
            _requireVoiceUpdate = true;
        }
        
        
        /** cutoff(0-1) */
        public function get cutoff() : Number { return _voice.channelParam.cutoff * 0.0078125; }
        public function set cutoff(c:Number) : void {
            var i:int, imax:int = _tracks.length, p:SiOPMChannelParam = _voice.channelParam;
            p.cutoff = (c<=0) ? 0 : (c>=1) ? 128 : int(c*128);
            for (i=0; i<imax; i++) {
                _tracks[i].channel.setLPFilter(p.cutoff, p.resonance, p.far, p.fdr1, p.fdr2, p.frr, p.fdc1, p.fdc2, p.fsc, p.frc);
            }
        }
        
        
        /** resonance(0-1) */
        public function get resonance() : Number { return _voice.channelParam.resonance * 0.1111111111111111; }
        public function set resonance(r:Number) : void {
            var i:int, imax:int = _tracks.length, p:SiOPMChannelParam = _voice.channelParam;
            p.resonance = (r<=0) ? 0 : (r>=1) ? 9 : int(r*9);
            for (i=0; i<imax; i++) {
                _tracks[i].channel.setLPFilter(p.cutoff, p.resonance, p.far, p.fdr1, p.fdr2, p.frr, p.fdc1, p.fdc2, p.fsc, p.frc);
            }
        }
        
        
        /** amplitude modulation */
        public function get amplitudeModulation() : int { return _voice.amDepth; }
        public function set amplitudeModulation(m:int) : void {
            _voice.channelParam.amd = _voice.amDepth = m;
            var i:int, imax:int = _tracks.length;
            for (i=0; i<imax; i++) {
                _tracks[i].channel.setAmplitudeModulation(m);
            }
        }
        
        
        /** pitch modulation */
        public function get pitchModulation() : int { return _voice.pmDepth; }
        public function set pitchModulation(m:int) : void {
            _voice.channelParam.pmd = _voice.pmDepth = m;
            var i:int, imax:int = _tracks.length;
            for (i=0; i<imax; i++) {
                _tracks[i].channel.setPitchModulation(m);
            }
        }
        
        
        
        
    // constructor
    //----------------------------------------
        /** constructor */
        function BasicSynth()
        {
            _voice = new SiONVoice();
            _tracks = new Vector.<SiMMLTrack>();
        }
        
        
        
        
    // operations
    //----------------------------------------
        /** set low-pass filter envelop.
         *  @param cutoff LP filter cutoff (0-128)
         *  @param resonance LP filter resonance (0-9)
         *  @param far LP filter attack rate (0-63)
         *  @param fdr1 LP filter decay rate 1 (0-63)
         *  @param fdr2 LP filter decay rate 2 (0-63)
         *  @param frr LP filter release rate (0-63)
         *  @param fdc1 LP filter decay cutoff 1 (0-128)
         *  @param fdc2 LP filter decay cutoff 2 (0-128)
         *  @param fsc LP filter sustain cutoff (0-128)
         *  @param frc LP filter release cutoff (0-128)
         */
        public function setLPFEnvelop(cutoff:int=128, resonance:int=0, far:int=0, fdr1:int=0, fdr2:int=0, frr:int=0, fdc1:int=128, fdc2:int=64, fsc:int=32, frc:int=128) : void
        {
            _voice.setLPFEnvelop(cutoff, resonance, far, fdr1, fdr2, frr, fdc1, fdc2, fsc, frc);
            _requireVoiceUpdate = true;
        }
        
        
        /** Set amplitude modulation parameters (same as "ma" command of MML).
         *  @param depth start modulation depth (same as 1st argument)
         *  @param end_depth end modulation depth (same as 2nd argument)
         *  @param delay changing delay (same as 3rd argument)
         *  @param term changing term (same as 4th argument)
         *  @return this instance
         */
        public function setAmplitudeModulation(depth:int=0, end_depth:int=0, delay:int=0, term:int=0) : void
        {
            _voice.setAmplitudeModulation(depth, end_depth, delay, term);
            _requireVoiceUpdate = true;
        }
        
        
        /** Set amplitude modulation parameters (same as "mp" command of MML).
         *  @param depth start modulation depth (same as 1st argument)
         *  @param end_depth end modulation depth (same as 2nd argument)
         *  @param delay changing delay (same as 3rd argument)
         *  @param term changing term (same as 4th argument)
         *  @return this instance
         */
        public function setPitchModulation(depth:int=0, end_depth:int=0, delay:int=0, term:int=0) : void
        {
            _voice.setPitchModulation(depth, end_depth, delay, term);
            _requireVoiceUpdate = true;
        }
        
        
        
        
    // internals
    //----------------------------------------
        /** @private [synthesizer internal] register single track */
        override public function _registerTrack(track:SiMMLTrack) : void
        {
            _tracks.push(track);
        }
        
        
        /** @private [synthesizer internal] register prural tracks */
        override public function _registerTracks(tracks:Vector.<SiMMLTrack>) : void
        {
            var i0:int = _tracks.length, imax:int = tracks.length, i:int;
            _tracks.length = i0 + imax;
            for (i=0; i<imax; i++) _tracks[i0+i] = tracks[i];
        }
        
        
        /** @private [synthesizer internal] unregister tracks */
        override public function _unregisterTracks(firstTrack:SiMMLTrack, count:int=1) : void
        {
            var index:int = _tracks.indexOf(firstTrack);
            if (index >= 0) _tracks.splice(index, count);
        }
    }
}


