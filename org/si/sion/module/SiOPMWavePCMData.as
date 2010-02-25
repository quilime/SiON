//----------------------------------------------------------------------------------------------------
// class for SiOPM PCM data
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.module {
    import flash.media.Sound;
    import org.si.sion.utils.SiONUtil;
    import org.si.sion.sequencer.SiMMLTable;
    
    
    /** PCM data class */
    public class SiOPMWavePCMData extends SiOPMWaveBase
    {
    // valiables
    //----------------------------------------
        /** wave data */
        public var wavelet:Vector.<int>;
        
        /** bits for fixed decimal */
        public var pseudoFixedBits:int;
        
        /** wave starting position in sample count. */
        public var startPoint:int;
        
        /** wave end position in sample count. */
        public var endPoint:int;
        
        /** wave looping position in sample count. -1 means no repeat. */
        public var loopPoint:int;
        
        
        
        
    // properties
    //----------------------------------------
        /** Sampling data's octave */
        public function get samplingOctave() : int { return pseudoFixedBits - 11 + 5; }
        
        
        
        
    // constructor
    //----------------------------------------
        /** Constructor. 
         *  @param data wave data, Sound, Vector.<Number> or Vector.<int>. The Sound is extracted inside.
         *  @param samplingOctave sampling data's octave (octave 5 as 44.1kHz)
         */
        function SiOPMWavePCMData(data:*=null, samplingOctave:int=5)
        {
            super(SiMMLTable.MT_PCM);
            if (data) initialize(data, samplingOctave);
        }
        
        
        
        
    // oprations
    //----------------------------------------
        /** Initializer.
         *  @param data wave data, Sound, Vector.<Number> or Vector.<int>. The Sound is extracted inside.
         *  @param samplingOctave sampling data's octave (octave 5 as 44.1kHz)
         *  @return this instance.
         */
        public function initialize(data:*, samplingOctave:int=5) : SiOPMWavePCMData
        {
            if (data is Sound) wavelet = SiONUtil.logTrans(data as Sound);
            else if (data is Vector.<Number>) wavelet = SiONUtil.logTransVector(data as Vector.<Number>);
            else if (data is Vector.<int>) wavelet = data as Vector.<int>;
            else throw new Error("SiOPMWavePCMData; not suitable data type");
            this.pseudoFixedBits = 11 + (samplingOctave-5);
            this.startPoint = 0;
            this.endPoint   = wavelet.length - 1;
            this.loopPoint  = -1;
            return this;
        }
        
        
        /** Slicer setting. You can cut samples and set repeating.
         *  @param startPoint slicing point to start data.
         *  @param endPoint slicing point to end data, The negative value calculates from the end.
         *  @param loopPoint slicing point to repeat data, -1 means no repeat
         *  @return this instance.
         */
        public function slice(startPoint:int=0, endPoint:int=-1, loopPoint:int=-1) : SiOPMWavePCMData 
        {
            if (endPoint < 0) endPoint = wavelet.length + endPoint;
            if (wavelet.length < endPoint) endPoint = wavelet.length - 1;
            if (endPoint < loopPoint)  loopPoint = -1;
            if (endPoint < startPoint) endPoint = wavelet.length - 1;
            this.startPoint = startPoint;
            this.endPoint   = endPoint;
            this.loopPoint  = loopPoint;
            return this;
        }
        
        
        /** Get initial sample index. 
         *  @param phase Starting phase, ratio from start point to end point(0-1).
         */
        public function getInitialSampleIndex(phase:Number=0) : int
        {
            return int(startPoint*(1-phase) + endPoint*phase);
        }
    }
}

