// Voice reference
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound.synthesizers {
    import org.si.sion.*;
    import org.si.sion.sequencer.SiMMLTrack;
    import org.si.sound.base.SoundObject;
   
    
    /** Voice reference, basic class of all synthesizers. */
    public class VoiceReference
    {
    // namespace
    //----------------------------------------
        use namespace _synthesizer_internal;
        
        
        
        
    // valiables
    //----------------------------------------
        /** @private [synthesizer internal] Instance of voice setting */
        _synthesizer_internal var _voice:SiONVoice = null;
        
        /** @private [synthesizer internal] Flag to require voice update */
        _synthesizer_internal var _requireVoiceUpdate:Boolean;
        
        
        
        
    // properties
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
        function VoiceReference()
        {
            _requireVoiceUpdate = false;
        }
        
        
        
        
    // operation
    //----------------------------------------
        /** @private [synthesizer internal] register single track */
        public function _registerTrack(track:SiMMLTrack) : void
        {
        }
        
        
        /** @private [synthesizer internal] register prural tracks */
        public function _registerTracks(tracks:Vector.<SiMMLTrack>) : void
        {
        }
        
        
        /** @private [synthesizer internal] unregister tracks */
        public function _unregisterTracks(firstTrack:SiMMLTrack, count:int=1) : void
        {
        }
    }
}


