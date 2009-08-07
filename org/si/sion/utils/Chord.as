//----------------------------------------------------------------------------------------------------
// Chord class
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sion.utils {
    /** This represents chord */
    public class Chord
    {
        /** Chord name */
        protected var _chordName:String;
        
        
        public function get chordName() : String { return _chordName; }
        public function set chordName(name:String) : void {
            _chordName = name;
        }
        
        
        function Chord(chordName:String="") {
            this.chordName = chordName;
        }
    }
}

