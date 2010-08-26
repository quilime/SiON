//----------------------------------------------------------------------------------------------------
// SiON data
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sion {
    import flash.media.Sound;
    import org.si.sion.sequencer.SiMMLData;
    import org.si.sion.sequencer.SiMMLEnvelopTable;
    import org.si.sion.sequencer.SiMMLEnvelopTable;
    import org.si.sion.utils.SiONUtil;
    import org.si.sion.module.SiOPMTable;
    import org.si.sion.module.SiOPMWavePCMTable;
    import org.si.sion.module.SiOPMWavePCMData;
    import org.si.sion.module.SiOPMWaveSamplerTable;
    import org.si.sion.module.SiOPMWaveSamplerData;

    
    /** The SiONData class provides musical score (and voice settings) data of SiON.
     */
    public class SiONData extends SiMMLData
    {
    // valiables
    //----------------------------------------
        
        
        
        
    // constructor
    //----------------------------------------
        function SiONData()
        {
        }
        
        
        
        
    // setter
    //----------------------------------------
        /** Set PCM data rederd by %7.
         *  @param index PCM data number.
         *  @param data Vector.&lt;Number&gt; stereo wave data. This type ussualy comes from SiONDriver.render().
         *  @param samplingOctave Sampling frequency. The value of 5 means that "o5a" is original frequency.
         *  @param keyRangeFrom Assigning key range starts from
         *  @param keyRangeTo Assigning key range ends at
         *  @see #render()
         */
        public function setPCMData(index:int, wavelet:Vector.<Number>, samplingOctave:int=5, keyRangeFrom:int=0, keyRangeTo:int=127) : SiOPMWavePCMData
        {
            index &= (SiOPMTable.PCM_DATA_MAX-1);
            if (!pcmData[index]) pcmData[index] = new SiOPMWavePCMTable();
            return pcmData[index].setSample(new SiOPMWavePCMData(wavelet, samplingOctave), keyRangeFrom, keyRangeTo);
        }
        
        
        /** Set PCM sound rederd from %7.
         *  @param index PCM data number.
         *  @param sound Sound instance to set.
         *  @param samplingOctave Sampling frequency. The value of 5 means that "o5a" is original frequency.
         *  @param keyRangeFrom Assigning key range starts from
         *  @param keyRangeTo Assigning key range ends at
         *  @param sampleMax The maximum sample count to extract. The length of returning vector is limited by this value.
         *  @return created instance
         */
        public function setPCMSound(index:int, sound:Sound, samplingOctave:int=5, keyRangeFrom:int=0, keyRangeTo:int=127, sampleMax:int=1048576) : SiOPMWavePCMData
        {
            return setPCMData(index, SiONUtil.extract(sound, null, 2, sampleMax), samplingOctave, keyRangeFrom, keyRangeTo);
        }
        
        
        /** Set sampler data refered by %10.
         *  @param index note number. 0-127 for bank0, 128-255 for bank1.
         *  @param data Vector.&lt;Number&gt; wave data. This type ussualy comes from SiONDriver.render().
         *  @param ignoreNoteOff True to set ignoring note off.
         *  @param channelCount 1 for monoral, 2 for stereo.
         *  @return created data instance
         *  @see #org.si.sion.SiONDriver.render()
         */
        public function setSamplerData(index:int, data:Vector.<Number>, ignoreNoteOff:Boolean=true, channelCount:int=2) : SiOPMWaveSamplerData
        {
            return sampleTable.setSample(new SiOPMWaveSamplerData(data, ignoreNoteOff, channelCount), index & (SiOPMTable.NOTE_TABLE_SIZE-1));
        }
        
        
        /** Set sampler sound refered by %10.
         *  @param index note number. 0-127 for bank0, 128-255 for bank1.
         *  @param sound Sound instance to set.
         *  @param ignoreNoteOff True to set ignoring note off.
         *  @param channelCount 1 for monoral, 2 for stereo.
         *  @param sampleMax The maximum sample count to extract. The length of returning vector is limited by this value.
         *  @return created instance
         */
        public function setSamplerSound(index:int, sound:Sound, ignoreNoteOff:Boolean=true, channelCount:int=2, sampleMax:int=1048576) : SiOPMWaveSamplerData
        {
            return setSamplerData(index, SiONUtil.extract(sound, null, channelCount, sampleMax), ignoreNoteOff, channelCount);
        }
        
        
    }
}

