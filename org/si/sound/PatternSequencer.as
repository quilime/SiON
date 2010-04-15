//----------------------------------------------------------------------------------------------------
// Pattern sequencer class
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound {
    import org.si.sion.*;
    import org.si.sion.sequencer.base.*;
    import org.si.sion.sequencer.SiMMLTrack;
    import org.si.sound.patterns.*;
    import org.si.sound.namespaces._sound_object_internal;
    import org.si.sound.synthesizers._synthesizer_internal;
    
    
    /** Pattern sequencer class provides simple one track pattern player. The sequence pattern is represented as Vector.<Note>. @see org.si.sound.patterns.Note 
@example Simple usage
<listing version="3.0">
// create new instance
var ps:PatternSequencer = new PatternSequencer();
    
// set sequence pattern by Note vector
var pat:Vector.<Note> = new Vector.<Note>();
pat.push(new Note(60, 60, 1));  // note C
pat.push(new Note(60, 62, 1));  // note D
pat.push(new Note(60, 64, 2));  // note E with length of 2
pat.push(null);                 // rest; null means no operation
pat.push(new Note(60, 62, 2));  // note D with length of 2
pat.push(new Note().setRest()); // rest; Note.setRest() method set no operation

// PatternSequencer.sequencer is the sound player
ps.sequencer.pattern = pat;
    
// play sequence "l16 $cde8d8" in MML
ps.play();
</listing>
     */
    public class PatternSequencer extends SoundObject
    {
    // namespace
    //----------------------------------------
        use namespace _sound_object_internal;
        
        
        
        
    // variables
    //----------------------------------------
        /** @private Sequencer instance */
        protected var _sequencer:Sequencer;
        /** @private Sequence data */
        protected var _data:SiONData;
        
        
        
        
    // properties
    //----------------------------------------
        /** the Sequencer instance belonging to this PatternSequencer, where the sequence pattern appears. */
        public function get sequencer() : Sequencer { return _sequencer; }
        
        
        /** portament */
        public function get portament() : int { return _sequencer.portament; }
        public function set portament(p:int) : void { _sequencer.setPortament(p); }
        
        
        
        
    // constructor
    //----------------------------------------
        /** constructor 
         *  @param defaultNote Default note, this value is referenced when Note.note property is -1.
         *  @param defaultVelocity Default velocity, this value is referenced when Note.velocity property is -1.
         *  @param defaultLength Default length, this value is referenced when Note.length property is Number.NaN.
         */
        function PatternSequencer(defaultNote:int=60, defaultVelocity:int=128, defaultLength:Number=0)
        {
            super("PatternSequencer");
            _data = new SiONData();
            _sequencer = new Sequencer(this, _data, defaultNote, defaultVelocity, defaultLength);
        }
        
        
        
        
    // operations
    //----------------------------------------
        /** start sequence */
        override public function play() : void
        {
            stop();
            var list:Vector.<SiMMLTrack> = _sequenceOn(_data, false, false);
            if (list.length > 0) {
                _track = _sequencer.play(list[0]);
                _synthesizer._registerTrack(_track);
            }
        }
        
        
        /** stop sequence */
        override public function stop() : void
        {
            if (_track) {
                _sequencer.stop();
                _synthesizer._unregisterTracks(_track);
                _track.setDisposable();
                _track = null;
                _sequenceOff(false);
            }
            _stopEffect();
        }
        
        
        
        
    // internal
    //----------------------------------------
    }
}

