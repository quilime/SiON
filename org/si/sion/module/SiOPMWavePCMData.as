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
        private var _startPoint:int;
        /** wave end position in sample count. */
        private var _endPoint:int;
        /** wave looping position in sample count. -1 means no repeat. */
        private var _loopPoint:int;
        
        
        
        
    // properties
    //----------------------------------------
        /** Sampling data's octave */
        public function get samplingOctave() : int { return pseudoFixedBits - 11 + 5; }
        
        
        /** wave starting position in sample count. */
        public function get startPoint() : int { return _startPoint; }
        
        /** wave end position in sample count. */
        public function get endPoint()   : int { return _endPoint; }
        
        /** wave looping position in sample count. -1 means no repeat. */
        public function get loopPoint()  : int { return _loopPoint; }
        
        
        
        
    // constructor
    //----------------------------------------
        /** Constructor. 
         *  @param data wave data, Sound, Vector.&lt;Number&gt; or Vector.&lt;int&gt;. The Sound is extracted inside.
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
         *  @param data wave data, Sound, Vector.&lt;Number&gt; or Vector.&lt;int&gt;. The Sound is extracted inside.
         *  @param samplingOctave sampling data's octave (specified octave as 44.1kHz)
         *  @return this instance.
         */
        public function initialize(data:*, samplingOctave:int=5) : SiOPMWavePCMData
        {
            if (data is Sound) wavelet = SiONUtil.logTrans(data as Sound, null, 1048576, 0);
            else if (data is Vector.<Number>) wavelet = SiONUtil.logTransVector(data as Vector.<Number>);
            else if (data is Vector.<int>) wavelet = data as Vector.<int>;
            else if (data == null) wavelet = null;
            else throw new Error("SiOPMWavePCMData; not suitable data type");
            this.pseudoFixedBits = 11 + (samplingOctave-5);
            _startPoint = 0;
            _endPoint   = wavelet.length - 1;
            _loopPoint  = -1;
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
            _startPoint = startPoint;
            _endPoint   = endPoint;
            _loopPoint  = loopPoint;
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

