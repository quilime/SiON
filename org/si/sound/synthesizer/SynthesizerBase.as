// Synthesizer object
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound.synthesizer {
    import org.si.sion.*;
    import org.si.sion.sequencer.SiMMLTrack;
    import org.si.sound.base.SoundObject;
    
    
    /** The Synthesizer object is a wrapper of SiONVoice.
     */
    public class SynthesizerBase
    {
    // namespace
    //----------------------------------------
        use namespace _synthesizer_internal;
        
        
        
        
    // valiables
    //----------------------------------------
        /** Owner sound object */
        _synthesizer_internal var _owner:SoundObject = null;
        
        /** Instance of voice setting */
        _synthesizer_internal var _voice:SiONVoice = null;
        
        /** Flag to require voice update */
        _synthesizer_internal var _requireVoiceUpdate:Boolean;
        
        
        
        
    // valiables
    //----------------------------------------
        /** voice setting */
        public function get voice() : SiONVoice { return _voice; }
        public function set voice(v:SiONVoice) : void {
            _requireVoiceUpdate = (_voice !== v);
            _voice = v;
        }
        
        
        
        
    // constructor
    //----------------------------------------
        /** constructor */
        function SynthesizerBase()
        {
            _requireVoiceUpdate = false;
        }
        
        
        
        
    // operation
    //----------------------------------------
        /** set track voice */
        public function setTrackVoice(track:SiMMLTrack) : void 
        {
            voice.setTrackVoice(track);
            _requireVoiceUpdate = false;
        }
        
        
        /** request voice update */
        public function requestUpdateVoice() : void
        {
            _requireVoiceUpdate = true;
        }
    }
}


