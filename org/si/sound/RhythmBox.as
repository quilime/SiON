//----------------------------------------------------------------------------------------------------
// Class for play rhythm tracks
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound {
    import org.si.sion.*;
    import org.si.sound.base.*;
    import org.si.sion.sequencer.SiMMLTrack;
    import org.si.sion.sequencer.SiMMLSequencer;
    import org.si.sion.sequencer.base.MMLSequence;
    
    
    /** Sound object playng rhythm tracks */
    public class RhythmBox extends SoundObjectContainer
    {
    // variables
    //----------------------------------------
        /** bass drum pattern sequencer */
        public var bass:PatternSequencer;
        /** snare drum pattern sequencer */
        public var snare:PatternSequencer;
        /** hi-hat cymbal pattern sequencer */
        public var hihat:PatternSequencer;
        
        
        
        
    // properties
    //----------------------------------------
        /** bass drum pattern number */
        public function set bassPattern(index:int) : void
        {
        }
        
        
        /** snare drum pattern number */
        public function set snarePattern(index:int) : void
        {
        }
        
        
        /** close hi-hat cymbal pattern number */
        public function set hihatPattern(index:int) : void
        {
        }
        
        
        
        
    // constructor
    //----------------------------------------
        /** constructor */
        function RhythmBox()
        {
            super("RhythmBox");
            addChild(bass  = new PatternSequencer(16, 36, 255, 1));
            addChild(snare = new PatternSequencer(16, 68, 128, 1));
            addChild(hihat = new PatternSequencer(16, 68, 64,  1));
        }
    }
}

