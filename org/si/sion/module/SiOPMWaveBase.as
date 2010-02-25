//----------------------------------------------------------------------------------------------------
// basic class sfor SiOPM wave data
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.module {
    /** basic class for SiOPM wave data */
    public class SiOPMWaveBase {
        /** module type */
        public var moduleType:int;
        
        
        /** constructor */
        function SiOPMWaveBase(moduleType:int)
        {
            this.moduleType = moduleType;
        }
    }
}

