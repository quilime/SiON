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
    
    
    /** Pattern sequencer class provides simple one track pattern player. The sequence pattern is represented as Vector.<Note>. @see org.si.sound.patterns.Note */
    public class PatternSequencer extends SoundObject
    {
    // namespace
    //----------------------------------------
        use namespace _sound_object_internal;
        
        
        
        
    // variables
    //----------------------------------------
        /** @private the Sequencer instance */
        protected var _sequencer:Sequencer;
        
        
        
    // properties
    //----------------------------------------
        /** the Sequencer instance belonging to this PatternSequencer, where the sequence pattern appears. */
        public function get sequencer() : Sequencer { return _sequencer; }
        
        
        /** portament */
        public function get portament() : int { return _sequencer.portament; }
        public function set portament(p:int) : void { _sequencer.setPortament(p); }
        
        
        
        
    // constructor
    //----------------------------------------
        /** constructor */
        function PatternSequencer(defaultNote:int=60, defaultVelocity:int=128, defaultLength:Number=0)
        {
            super("PatternSequencer");
            _sequencer = new Sequencer(this, defaultNote, defaultVelocity, defaultLength);
        }
        
        
        
        
    // operations
    //----------------------------------------
        /** start sequence */
        override public function play() : void
        {
            var list:Vector.<SiMMLTrack> = _sequenceOn(_sequencer.data, false, false);
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
        }
        
        
        
        
    // internal
    //----------------------------------------
    }
}

