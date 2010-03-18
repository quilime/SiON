//----------------------------------------------------------------------------------------------------
// Preset patterns for RhythmBox
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound {
    import org.si.sion.*;
    import org.si.sound.base.*;
    import org.si.sion.sequencer.SiMMLTrack;
    import org.si.sion.sequencer.SiMMLSequencer;
    import org.si.sion.sequencer.base.MMLSequence;
    
    
    /** Preset patterns for RhythmBox */
    public dynamic class RhythmBoxPresetPattern 
    {
    // variables
    //----------------------------------------
        /** categoly list. */
        public var categolies:Array;
        
        
        
        
    // constructor
    //----------------------------------------
        /** constructor */
        function RhythmBoxPresetPattern()
        {
            _categoly("bass");
            
            _categoly("snare");
            
            _categoly("hihat");
            
            _categoly("percus");
        }
        
        
        
        
    // internals
    //----------------------------------------
        private var _pattern(key:String, name:String, pattern:Array) : void {
            
        }
        
        
        // register categoly
        private var _categolyList:Array;
        private function _categoly(key:String) : void {
            _categolyList = [];
            _categolyList["name"] = key;
            categolies.push(_categolyList);
            this[key] = _categolyList;
        }
    }
}

