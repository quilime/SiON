// Sampler Synthesizer
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound.synthesizers {
    import flash.media.Sound;
    import org.si.sion.*;
    import org.si.sion.module.*;
    import org.si.sion.sequencer.SiMMLTrack;
    
    
    /** Sampler Synthesizer
     */
    public class SamplerSynth extends BasicSynth
    {
    // namespace
    //----------------------------------------
        use namespace _synthesizer_internal;
        
        
        
        
    // variables
    //----------------------------------------
        /** sample table */
        protected var _samplerTable:SiOPMWaveSamplerTable;
        /** default PCM data */
        protected var _defaultSamplerData:SiOPMWaveSamplerData;
        
        
        
        
    // properties
    //----------------------------------------
        
        
        
        
    // constructor
    //----------------------------------------
        /** constructor 
         *  @param data wave data, Sound or Vector.<Number>, the Sound is extracted when the length is shorter than 4[sec].
         *  @param ignoreNoteOff flag to ignore note off
         *  @param channelCount channel count of streaming, 1 for monoral, 2 for stereo.
         */
        function SamplerSynth(data:*=null, ignoreNoteOff:Boolean=true, channelCount:int=2)
        {
            _defaultSamplerData = new SiOPMWaveSamplerData(data, ignoreNoteOff, channelCount);
            _samplerTable = new SiOPMWaveSamplerTable();
            _samplerTable.clear(_defaultSamplerData);
            _voice.waveData = _samplerTable;
        }
        
        
        
        
    // operation
    //----------------------------------------
        /** Slicer setting. You can cut samples and set repeating.
         *  @param startPoint slicing point to start data.
         *  @param endPoint slicing point to end data. The negative value plays whole data.
         *  @param loopPoint slicing point to repeat data. -1 means no repeat
         */
        public function slice(startPoint:int=0, endPoint:int=-1, loopPoint:int=-1) : void
        {
            _defaultSamplerData.slice(startPoint, endPoint, loopPoint);
            _requireVoiceUpdate = true;
        }
        
        
        /** Set sample with key range.
         *  @param data wave data, Sound or Vector.<Number> can be set, the Sound is extracted when the length is shorter than 4[sec].
         *  @param ignoreNoteOff flag to ignore note off
         *  @param channelCount channel count of streaming, 1 for monoral, 2 for stereo.
         *  @param keyRangeFrom Assigning key range starts from
         *  @param keyRangeTo Assigning key range ends at. -1 to set only at the key of argument "keyRangeFrom".
         *  @return assigned SiOPMWavePCMData.
         */
        public function setSamplerData(data:*, ignoreNoteOff:Boolean=true, channelCount:int=2, keyRangeFrom:int=0, keyRangeTo:int=127) : SiOPMWaveSamplerData
        {
            var sample:SiOPMWaveSamplerData;
            if (keyRangeFrom==0 && keyRangeTo==127) {
                _defaultSamplerData.initialize(data, ignoreNoteOff, channelCount);
                sample = _defaultSamplerData;
            } else {
                sample = new SiOPMWaveSamplerData(data, ignoreNoteOff, channelCount);
            }
            _requireVoiceUpdate = true;
            return _samplerTable.setSample(sample, keyRangeFrom, keyRangeTo);
        }
    }
}


