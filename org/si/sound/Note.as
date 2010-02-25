//----------------------------------------------------------------------------------------------------
// Note object used in PatternSequencer
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound {
    /** Note object used in PatternSequencer. */
    public class Note
    {
        /** Note number[0-127], -1 sets playing with sequencers default note, -2 sets rest. */
        public var note:int = 0;
        /** Velocity[0-128], 0 sets playing with sequencers default velocity. */
        public var velocity:int = 0;
        /** Length in tick count[1920 for whole tone], 0 sets playing with sequencers default length. */
        public var tickLength:int = 0;
        
        
        /** constructor
         *  @param note Note number[0-127], -1 sets playing with sequencers default note and -2 sets as rest.
         *  @param velocity Velocity[0-128], 0 sets playing with sequencers default velocity.
         *  @param length Length in tick count[1920 for whole tone], 0 sets playing with sequencers default length.
         */
        function Note(note:int=-2, velocity:int=0, tickLength:int=0)
        {
            setNote(note, velocity, tickLength);
        }

        
        /** Set note.
         *  @param note Note number[0-127], -1 sets playing with sequencers default note and -2 sets as rest.
         *  @param velocity Velocity[0-128], 0 sets playing with sequencers default velocity.
         *  @param length Length in tick count[1920 for whole tone], 0 sets playing with sequencers default length.
         *  @return this instance.
         */
        public function setNote(note:int=-1, velocity:int=0, tickLength:int=0) : Note
        {
            this.note = note;
            this.velocity = velocity;
            this.tickLength = tickLength;
            return this;
        }
        
        
        /** Set as rest. */
        public function setRest() : Note
        {
            note = -2;
            return this;
        }
    }
}

