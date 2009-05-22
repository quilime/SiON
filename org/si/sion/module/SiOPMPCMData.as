//----------------------------------------------------------------------------------------------------
// class for SiOPM wave table
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.module {
    public class SiOPMPCMData
    {
        public var wavelet:Vector.<int>;
        public var pseudoFixedBits:int;
        public var loopPoint:int;
        
        
        function SiOPMPCMData(data:Vector.<Number>=null, samplingOctave:int=5)
        {
            wavelet = null;
            pseudoFixedBits = 0;
            loopPoint = -1;
        }
        
        
        public function free() : void
        {
            _freeList.push(this);
        }
        
        
        static private var _freeList:Vector.<SiOPMPCMData> = new Vector.<SiOPMPCMData>();
        
        static public function alloc(wavelet:Vector.<int>, samplingOctave:int=5) : SiOPMPCMData
        {
            var newInstance:SiOPMPCMData = _freeList.pop() || new SiOPMPCMData();
            newInstance.wavelet = wavelet;
            newInstance.pseudoFixedBits = 14 + (samplingOctave-5);
            newInstance.loopPoint = -1;
            return newInstance;
        }
    }
}

