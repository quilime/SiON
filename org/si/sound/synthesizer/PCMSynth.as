// Pulse Code Modulation Synthesizer 
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound.synthesizer {
    import flash.media.Sound;
    import org.si.sion.*;
    import org.si.sion.module.*;
    import org.si.sion.sequencer.SiMMLTrack;
    import org.si.sound.base.SoundObject;
    
    
    /** Pulse Code Modulation Synthesizer 
     */
    public class PCMSynth extends BasicSynth
    {
    // namespace
    //----------------------------------------
        use namespace _synthesizer_internal;
        
        
        
        
    // variables
    //----------------------------------------
        /** PCM table */
        protected var _pcmTable:SiOPMWavePCMTable;
        /** default PCM data */
        protected var _defaultPCMData:SiOPMWavePCMData;
        
        
        
        
    // properties
    //----------------------------------------
        
        
        
        
    // constructor
    //----------------------------------------
        /** constructor
         *  @param data wave data, Sound or Vector.<Number> can be set, the Sound is extracted inside.
         *  @param samplingOctave sampling data's octave (specified octave is as 44.1kHz)
         */
        function PCMSynth(data:*=null, samplingOctave:int=5)
        {
            _defaultPCMData = new SiOPMWavePCMData(data, samplingOctave);
            _pcmTable = new SiOPMWavePCMTable();
            _pcmTable.clear(_defaultPCMData);
            _voice.waveData = _pcmTable;
        }
        
        
        
        
    // operation
    //----------------------------------------
        /** Slicer setting. You can cut samples and set repeating.
         *  @param startPoint slicing point to start data.
         *  @param endPoint slicing point to end data, The negative value calculates from the end.
         *  @param loopPoint slicing point to repeat data, -1 means no repeat
         */
        public function slice(startPoint:int=0, endPoint:int=-1, loopPoint:int=-1) : void
        {
            _defaultPCMData.slice(startPoint, endPoint, loopPoint);
            _requireVoiceUpdate = true;
        }
        
        
        /** Set PCM sample with key range (this feature is not available in currennt version).
         *  @param data wave data, Sound or Vector.<Number> can be set, the Sound is extracted inside.
         *  @param samplingOctave sampling data's octave (specified octave is as 44.1kHz)
         *  @param keyRangeFrom Assigning key range starts from
         *  @param keyRangeTo Assigning key range ends at. -1 to set only at the key of argument "keyRangeFrom".
         *  @return assigned SiOPMWavePCMData.
         */
        public function setPCMData(data:*, samplingOctave:int=5, keyRangeFrom:int=0, keyRangeTo:int=127) : SiOPMWavePCMData
        {
            var pcmData:SiOPMWavePCMData;
            if (keyRangeFrom==0 && keyRangeTo==127) {
                _defaultPCMData.initialize(data, samplingOctave);
                pcmData = _defaultPCMData;
            } else {
                pcmData = new SiOPMWavePCMData(data, samplingOctave);
            }
            _requireVoiceUpdate = true;
            return _pcmTable.setSample(pcmData, keyRangeFrom, keyRangeTo);
        }
    }
}


