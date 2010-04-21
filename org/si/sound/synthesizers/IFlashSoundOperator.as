// Interface class for all flash Sound operating synthesizers
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound.synthesizers {
    import flash.media.Sound;
    
    /** Interface class for all flash Sound operating synthesizers */
    public class IFlashSoundOperator extends BasicSynth
    {
        /** @private */
        public function slice(startPoint:int=0, endPoint:int=-1, loopPoint:int=-1) : void {}
        /** @private */
        public function setSound(sound:Sound, keyRangeFrom:int=0, keyRangeTo:int=127, startPoint:int=0, endPoint:int=-1, loopPoint:int=-1) : void {}
    }
}

