//----------------------------------------------------------------------------------------------------
// SiOPM effect basic class
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------




package org.si.sound.effect {
    /** Effector basic class */
    public class SiEffectBase
    {
        /** @private [internal use] used by manager */
        public var _isFree:Boolean = true;
        
        
        /** initializer. */
        public function initialize() : void
        {
        }
        
        /** parameter setting by mml arguments 
         *  @param args The arguments refer from mml. The value of Number.NaN is put when its abbriviated.
         */
        public function mmlCallback(args:Vector.<Number>) : void
        {
        }

        /** prepare processing. 
         *  @return requesting channels count.
         */
        public function prepareProcess() : int
        {
            return 1;
        }
        
        /** process effect to stream buffer 
         *  @param channels Stream channel count. 1=monoral(same data on buffer[i] ans buffer[i+1]). 2=stereo.
         *  @param buffer Stream buffer to apply effect. This is standard stereo stream buffer like [L0,R0,L1,R1,L2,R2 ... ].
         *  @param startIndex startIndex to apply effect. You CANNOT use this index to the stream buffer directly. Should be x2 because its a stereo stream.
         *  @param length length to apply effect. You CANNOT use this length to the stream buffer directly. Should be x2 because its a stereo stream.
         *  @return output channels count.
         */
        public function process(channels:int, buffer:Vector.<Number>, startIndex:int, length:int) : int
        {
            return channels;
        }
    }
}

