//----------------------------------------------------------------------------------------------------
// Note object used in PatternSequencer
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound {
    /** Note object used in PatternSequencer. */
    public class Note
    {
        /** Note number[-1-127], -1 sets playing with sequencers default note. */
        public var note:int = 0;
        /** Velocity[-1-128], -1 sets playing with sequencers default velocity, 0 sets no note (rest). */
        public var velocity:int = 0;
        /** Length in 16th beat [16 for whole tone], Number.NaN sets playing with sequencers default length. */
        public var length:Number = 0;
        
        
        /** constructor
         *  @param note Note number[-1-127], -1 sets playing with sequencer's default note.
         *  @param velocity Velocity[-1-128], -1 sets playing with sequencer's default velocity, 0 sets no note (rest).
         *  @param length Length in 16th beat [16 for whole tone], Number.NaN sets playing with sequencers default length.
         */
        function Note(note:int=-1, velocity:int=0, length:Number=Number.NaN)
        {
            setNote(note, velocity, length);
        }

        
        /** Set note.
         *  @param note Note number[-1-127], -1 sets playing with sequencer's default note.
         *  @param velocity Velocity[-1-128], -1 sets playing with sequencer's default velocity, 0 sets no note (rest).
         *  @param length Length in 16th beat [16 for whole tone], Number.NaN sets playing with sequencers default length.
         *  @return this instance.
         */
        public function setNote(note:int=-1, velocity:int=-1, length:Number=Number.NaN) : Note
        {
            this.note = note;
            this.velocity = velocity;
            this.length = length;
            return this;
        }
        
        
        /** Set as rest. */
        public function setRest() : Note
        {
            velocity = 0;
            return this;
        }
    }
}

