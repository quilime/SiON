//----------------------------------------------------------------------------------------------------
// SiOPM effect wave shaper
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.effector {
    /** Stereo wave shaper. */
    public class SiEffectWaveShaper extends SiEffectBase
    {
    // variables
    //------------------------------------------------------------
        private var _coefficient:int;
        
        
        
        
    // constructor
    //------------------------------------------------------------
        /** constructor */
        function SiEffectWaveShaper() {}        
        
        
        
    // operations
    //------------------------------------------------------------
        /** set parameters
         *  @param distortion distortion(0-1).
         */
        public function setParameters(distortion:Number=0.5) : void {
            if (distortion >= 1) distortion = 0.9999847412109375; //65535/65536
            _coefficient = 2*distortion/(1-distortion);
        }
        
        
        
        
    // overrided funcitons
    //------------------------------------------------------------
        /** @private */
        override public function initialize() : void
        {
            setParameters();
        }
        

        /** @private */
        override public function mmlCallback(args:Vector.<Number>) : void
        {
            setParameters((!isNaN(args[0])) ? args[0]*0.01 : 0.5);
        }
        
        
        /** @private */
        override public function prepareProcess() : int
        {
            return 2;
        }
        
        
        /** @private */
        override public function process(channels:int, buffer:Vector.<Number>, startIndex:int, length:int) : int
        {
            startIndex <<= 1;
            length <<= 1;
            var i:int, n:Number, c1:Number=1 + _coefficient;
            for (i=startIndex; i<length; i++) {
                n = buffer[i];
                buffer[i] = c1 * n / (1 + _coefficient * ((n<0) ? -n : n));
            }
            return channels;
        }
    }
}

