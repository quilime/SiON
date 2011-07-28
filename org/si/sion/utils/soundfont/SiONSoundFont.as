//----------------------------------------------------------------------------------------------------
// SiON sound font loader
//  Copyright (c) 2011 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.utils.soundfont {
    import flash.media.Sound;
    import org.si.sion.*;
    import org.si.sion.module.*;
    import org.si.sion.sequencer.*;
    
    
    /** SiON Sound font class. */
    public class SiONSoundFont
    {
    // variables
    //--------------------------------------------------
        /** all loaded Sound instances, access them by id */
        public var sounds:*;
        
        /** all SiMMLEnvelopTable instances */
        public var envelopes:Vector.<SiMMLEnvelopTable> = new Vector.<SiMMLEnvelopTable>(SiMMLTable.ENV_TABLE_MAX, true);
        
        /** all SiOPMWaveTable inetances */
        public var waveTables:Vector.<SiOPMWaveTable> = new Vector.<SiOPMWaveTable>(SiOPMTable.WAVE_TABLE_MAX, true);
        
        /** all fm voice instances */
        public var fmVoices:Vector.<SiONVoice> = new Vector.<SiONVoice>(SiMMLTable.VOICE_MAX, true);
        
        /** all pcm voice instances */
        public var pcmVoices:Vector.<SiONVoice> = new Vector.<SiONVoice>(SiOPMTable.PCM_DATA_MAX, true);
        
        /** all sampler table instances */
        public var samplerTables:Vector.<SiOPMWaveSamplerTable> = new Vector.<SiOPMWaveSamplerTable>(SiOPMTable.SAMPLER_TABLE_MAX, true);
        
        /** default FPS */
        public var defaultFPS:Number = 60;
        /** default velocity mode */
        public var defaultVelocityMode:int = 0;
        /** default expression mode */
        public var defaultExpressionMode:int = 0;
        /** default v command shoft */
        public var defaultVCommandShift:int = 4;
        
        
        
        
    // constructor
    //--------------------------------------------------
        /** constructor */
        public function SiONSoundFont(sounds:* = null)
        {
            this.sounds = sounds || {};
        }
    }
}

