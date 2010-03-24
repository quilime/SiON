//----------------------------------------------------------------------------------------------------
// Preset voices for RhythmBox
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound {
    import org.si.sion.*;
    import org.si.sound.base.*;
    import org.si.sion.sequencer.SiMMLTrack;
    import org.si.sion.sequencer.SiMMLSequencer;
    import org.si.sion.sequencer.base.MMLSequence;
    
    
    /** Preset voices for RhythmBox */
    public dynamic class RhythmBoxPresetVoice 
    {
    // variables
    //----------------------------------------
        /** categoly list. */
        public var categolies:Array = [];
        
        
        
        
    // constructor
    //----------------------------------------
        /** constructor */
        function RhythmBoxPresetVoice()
        {
            // bass drums
            _categoly("bass");
            _percuss1op("bass1",     "1 operator bass drum (sine)",          0, 0, 0, 63, 28, -128);
            _percuss1op("bass2",     "1 operator bass drum (sine) weak",     0, 4, 0, 63, 28, -128);
            _percuss1op("bass3",     "1 operator bass drum (triangle)",      0, 0, 3, 63, 28, -128);
            _percuss1op("bass4",     "1 operator bass drum (triangle) weak", 0, 4, 3, 63, 28, -128);
            _percuss1op("bass5",     "1 operator bass drum (pulse)",         0, 8, 6, 63, 28, -128);
            _percuss1op("bass6",     "1 operator bass drum (pulse) weak",    0,12, 6, 63, 28, -128);
            
            // snare drums
            _categoly("snare");
            _percuss1op("snare1",    "1 operator snare drum",      68,  8, 17, 63, 32, 0, 64, 1);
            _percuss1op("snare2",    "1 operator snare drum weak", 68, 12, 17, 63, 32, 0, 64, 1);
            
            // closed hihats
            _categoly("closedhh");
            _percuss1op("closedhh1", "1 operator closed hi-hat", 68, 8, 19, 63, 40, 0);
            _percuss1op("closedhh2", "1 operator closed hi-hat", 68, 8, 20, 63, 40, 0);
            
            // opened hihats
            _categoly("openedhh");
            _percuss1op("openedhh1", "1 operator opened hi-hat", 68, 8, 19, 63, 28, 0);
            _percuss1op("openedhh2", "1 operator opened hi-hat", 68, 8, 20, 63, 28, 0);
            
            // symbals
            _categoly("symbal");
            _percuss1op("symbal1",   "1 operator crash symbal",  68, 8, 16, 48, 24, 0);
            
            // others
            _categoly("percus");
        }
        
        
        
        
    // internals
    //----------------------------------------
        // create new 1operator percussive voice
        private function _percuss1op(key:String, name:String, note:int, tl:int, ws:int, ar:int, rr:int, sw:int, cut:int=128, res:int=0) : void {
            var voice:SiONVoice = new SiONVoice(5, ws, ar, rr);
            voice.gateTime = 0;
            voice.channelParam.operatorParam[0].fixedPitch = note<<6;
            voice.channelParam.operatorParam[0].tl = tl;
            voice.releaseSweep = sw;
            voice.setLPFEnvelop(cut, res);
            voice.name = name;
            _categolyList.push(voice);
            this[key] = voice;
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

