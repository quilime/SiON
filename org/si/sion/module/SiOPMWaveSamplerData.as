//----------------------------------------------------------------------------------------------------
// class for SiOPM samplers wave
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.module {
    import flash.media.Sound;
    import org.si.sion.sequencer.SiMMLTable;
    import org.si.sion.utils.SiONUtil;
    
    
    /** SiOPM samplers wave data */
    public class SiOPMWaveSamplerData extends SiOPMWaveBase
    {
    // constant
    //----------------------------------------
        /** length borderline for extracting Sound [ms] */
        static public const EXTRACT_THRESHOLD:int = 4000;
        
        
        
    // valiables
    //----------------------------------------
        /** Is extracted ? */
        public var isExtracted:Boolean;
        /** Sound data */
        public var soundData:Sound;
        /** Wave data */
        public var waveData:Vector.<Number>;
        /** channel count of this data. */
        public var channelCount:int;
        
        /** wave starting position in sample count. */
        private var _startPoint:int;
        /** wave end position in sample count. */
        private var _endPoint:int;
        /** wave looping position in sample count. -1 means no repeat. */
        private var _loopPoint:int;
        
        // flag to ignore note off
        private var _ignoreNoteOff:Boolean;
        
        
        
        
    // properties
    //----------------------------------------
        /** Sammple length */
        public function get length() : int {
            if (isExtracted) return (waveData.length >> (channelCount-1));
            if (soundData) return (soundData.length * 44.1);
            return 0;
        }
        
        
        /** flag t ignore note off */
        public function get ignoreNoteOff() : Boolean { return _ignoreNoteOff; }
        public function set ignoreNoteOff(b:Boolean) : void {
            _ignoreNoteOff = (_loopPoint == -1) && b;
        }
        
        
        /** wave starting position in sample count. */
        public function get startPoint() : int { return _startPoint; }
        
        /** wave end position in sample count. */
        public function get endPoint()   : int { return _endPoint; }
        
        /** wave looping position in sample count. -1 means no repeat. */
        public function get loopPoint()  : int { return _loopPoint; }
        
        
        
        
    // constructor
    //----------------------------------------
        /** constructor 
         *  @param data wave data, Sound or Vector.&lt;Number&gt;. The Sound is extracted when the length is shorter than 4[sec].
         *  @param ignoreNoteOff flag to ignore note off
         *  @param channelCount channel count of streaming, 1 for monoral, 2 for stereo.
         */
        function SiOPMWaveSamplerData(data:*=null, ignoreNoteOff:Boolean=true, channelCount:int=2) 
        {
            super(SiMMLTable.MT_SAMPLE);
            if (data) initialize(data, ignoreNoteOff, channelCount);
        }
        
        
        
        
    // oprations
    //----------------------------------------
        /** initialize 
         *  @param data wave data, Sound or Vector.&lt;Number&gt;. The Sound is extracted when the length is shorter than 4[sec].
         *  @param ignoreNoteOff flag to ignore note off
         *  @param channelCount channel count of streaming, 1 for monoral, 2 for stereo.
         *  @return this instance.
         */
        public function initialize(data:*, ignoreNoteOff:Boolean=true, channelCount:int=2) : SiOPMWaveSamplerData
        {
            if (data is Vector.<Number>) {
                this.soundData = null;
                this.waveData = data;
                isExtracted = true;
            } else if (data is Sound) {
                this.soundData = data;
                if (this.soundData.length <= EXTRACT_THRESHOLD) {
                    this.waveData = SiONUtil.extract(this.soundData, null, channelCount);
                    isExtracted = true;
                } else {
                    this.waveData = null;
                    isExtracted = false;
                }
            } else if (data == null) {
                this.soundData = null;
                this.waveData = null;
                isExtracted = false;
            } else {
                throw new Error("SiOPMWaveSamplerData; not suitable data type");
            }
            this.channelCount = (channelCount == 1) ? 1 : 2;
            
            this._startPoint = 0;
            this._endPoint   = length;
            this._loopPoint  = -1;
            this.ignoreNoteOff = ignoreNoteOff;
            return this;
        }
        
        
        /** Slicer setting. You can cut samples and set repeating.
         *  @param startPoint slicing point to start data.
         *  @param endPoint slicing point to end data. The negative value plays whole data.
         *  @param loopPoint slicing point to repeat data. -1 means no repeat
         *  @return this instance.
         */
        public function slice(startPoint:int=0, endPoint:int=-1, loopPoint:int=-1) : SiOPMWaveSamplerData
        {
            if (endPoint < 0) endPoint = length-1;
            if (endPoint < loopPoint)  loopPoint = -1;
            if (endPoint < startPoint) endPoint = length-1;
            _startPoint = startPoint;
            _endPoint   = endPoint;
            _loopPoint  = loopPoint;
            if (_loopPoint != -1) _ignoreNoteOff = false;
            return this;
        }
        
        
        /** Get initial sample index. 
         *  @param phase Starting phase, ratio from start point to end point(0-1).
         */
        public function getInitialSampleIndex(phase:Number=0) : int
        {
            return int(startPoint*(1-phase) + endPoint*phase);
        }
        
        
        
        
    // factory
    //----------------------------------------
        public function free() : void
        {
            _freeList.push(this);
        }
        
        
        static private var _freeList:Vector.<SiOPMWaveSamplerData> = new Vector.<SiOPMWaveSamplerData>();
        
        static public function alloc(data:*, ignoreNoteOff:Boolean, channelCount:int) : SiOPMWaveSamplerData
        {
            var newInstance:SiOPMWaveSamplerData = _freeList.pop() || new SiOPMWaveSamplerData();
            newInstance.initialize(data, ignoreNoteOff, channelCount);
            return newInstance;
        }
    }
}

