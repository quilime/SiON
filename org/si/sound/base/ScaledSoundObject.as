//----------------------------------------------------------------------------------------------------
// Module to play one note in specifyed scale
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound.base {
    import org.si.sion.*;
    import org.si.sion.utils.Scale;
    
    
    /** Module to play one note in specifyed scale */
    public class ScaledSoundObject extends SoundObject
    {
    // variables
    //----------------------------------------
        /** default scale */
        static private var _defaultScale:Scale = new Scale("C");
        
        /** Table of notes on scale */
        protected var _scale:Scale;
        
        /** scale index */
        protected var _scaleIndex:int;
        
        
        
        
    // properties
    //----------------------------------------
        /** @inheritDoc */
        override public function get note() : int {
            return _scale.baseNote;
        }
        override public function set note(n:int) : void {
            _scale.baseNote = n;
        }
        
        
        /** scale instance */
        public function get scale() : Scale { return _scale; }
        public function set scale(s:Scale) : void { _scale = s || _defaultScale; }
        
        
        /** index on scale */
        public function get scaleIndex() : int { return _scaleIndex; }
        public function set scaleIndex(i:int) : void {
            _scaleIndex = i;
            _note = _scale.getNote(i);
        }
        
        
        
        
    // constructor
    //----------------------------------------
        /** constructor.
         *  @param scaleInstance Scale setting.
         *  @see org.si.sion.utils.Scale
         */
        function ScaledSoundObject(scaleInstance:Scale=null) {
            super((scaleInstance) ? scaleInstance.scaleName : "");
            _scale = scaleInstance || _defaultScale;
            _scaleIndex = 0;
        }
        
        
        
        
    // operations
    //----------------------------------------
    }
}

