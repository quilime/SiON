//----------------------------------------------------------------------------------------------------
// Track group class.
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.sequencer {
    import org.si.sion.sequencer.base.BeatPerMinutes;
    

    /** Track group class. <br/>
     */
    public class SiMMLTrackGroup
    {
    // valiables
    //--------------------------------------------------
        /** Member tracks */
        public var members:Vector.<SiMMLTrack>;
        /** mml data to play */
        public var mmlData:SiMMLData;
        /** @private [internal use] Beat per minutes */
        internal var _bpm:BeatPerMinutes;
        
        
        
        
    // properties
    //--------------------------------------------------
        
        
        
        
    // constructor
    //--------------------------------------------------
        function SiMMLTrackGroup()
        {
            members = new Vector.<SiMMLTrack>();
            _bpm = null;
        }
        
        
        
        
    // operation for all tracks
    //--------------------------------------------------
    }
}

