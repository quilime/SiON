//----------------------------------------------------------------------------------------------------
// Arpeggiator class
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound {
    import org.si.sion.*;
    import org.si.sion.utils.Scale;
    import org.si.sion.sequencer.base.MMLEvent;
    import org.si.sion.sequencer.base.MMLSequence;
    import org.si.sion.sequencer.SiMMLTrack;
    import org.si.sound.base.ScaledSoundObject;
    import org.si.sound.synthesizer._synthesizer_internal;
    
    
    /** Arpeggiator */
    public class Arpeggiator extends ScaledSoundObject
    {
    // variables
    //----------------------------------------
        /** portament */
        protected var _portament:int;
        /** arepggio pattern */
        protected var _arpeggio:Vector.<int>;
        /** Note events in the sequence with portament */
        protected var _noteEvents:Vector.<MMLEvent>;
        /** Slur events in the sequence with portament */
        protected var _slurEvents:Vector.<MMLEvent>;
        /** Note length */
        protected var _step:int;
        /** Sequence data. */
        protected var _data:SiONData;
        /** Sequence for arppegio pattern. */
        protected var _sequence:MMLSequence;
        /** Next arpeggio pattern to change while playing. */
        protected var _nextPattern:Array;
        
        
        
        
    // properties
    //----------------------------------------
        /** portament */
        public function get portament() : int { return _portament; }
        public function set portament(p:int) : void {
            _portament = p;
            if (_portament < 0) _portament = 0;
            if (_track) {
                _track.setPortament(_portament);
                _track.eventMask = (_portament) ? 0 : SiMMLTrack.MASK_SLUR;
            }
        }
        
        /** @private */
        override public function set note(n:int) : void {
            super.note = n;
            _scaleIndexUpdated();
        }
        
        
        /** @private */
        override public function set scaleIndex(index:int) : void {
            super.scaleIndex = index;
            _scaleIndexUpdated();
        }
        
        
        /** @private */
        override public function set scale(s:Scale) : void {
            super.scale = s;
            _scaleIndexUpdated();
        }
        
        
        /** note length in 16th beat. */
        public function get noteLength() : Number { return _step / 120; }
        public function set noteLength(l:Number) : void {
            _step = l * 120;
            var i:int, imax:int = _slurEvents.length;
            for (i=0; i<imax; i++) _slurEvents[i].length = _step;
        }
        
        
        /** Note index array of the arpeggio pattern. If the index is out of range, insert rest instead. */
        public function set pattern(pat:Array) : void
        {
            if (!isPlaying) _setArpeggioPattern(pat);
            else _nextPattern = pat;
        }
        
        
        /** @internal This property is only for the compatibility before version 0.58. */
        public function get noteQuantize() : int { return gateTime * 8; }
        public function set noteQuantize(q:int) : void { gateTime = q * 0.125; }
        
                
        
        
    // constructor
    //----------------------------------------
        /** constructor 
         *  @param scaleInstance Scale instance.
         *  @param noteLength length for each note
         *  @param pattern arpegio pattern 
         *  @see org.si.sion.utils.Scale
         */
        function Arpeggiator(scaleInstance:Scale=null, noteLength:Number=2, pattern:Array=null) 
        {
            super(scaleInstance);
            _data = new SiONData();
            _sequence = _data.appendNewSequence();
            _noteEvents = new Vector.<MMLEvent>();
            _slurEvents = new Vector.<MMLEvent>();
            _portament = 0;
            _nextPattern = null;
            _step = noteLength * 120;
            _setArpeggioPattern(pattern);
        }
        
        
        
        
    // operations
    //----------------------------------------
        /** Play sound. */
        override public function play() : void
        {
            stop();
            var list:Vector.<SiMMLTrack> = _sequenceOn(_data, false);
            if (list.length >= 1) {
                _track = list[0];
                _track.setPortament(_portament);
                _track.eventMask = (_portament) ? 0 : SiMMLTrack.MASK_SLUR;
                _synthesizer._synthesizer_internal::_registerTrack(_track);
            }
        }
        
        
        /** Stop sound. */
        override public function stop() : void
        {
            if (_track) {
                _synthesizer._synthesizer_internal::_uregisterTracks(_track);
                _track.setDisposable();
                _track = null;
                _sequenceOff(true);
            }
        }
        
        
        
        
    // internal
    //----------------------------------------
        /** call this after the update of note or scale index */
        protected function _scaleIndexUpdated() : void {
            var i:int, imax:int = _noteEvents.length;
            for (i=0; i<imax; i++) {
                _noteEvents[i].data = _scale.getNote(_arpeggio[i] + _scaleIndex);
            }
        }
        
        
        // callback on patterns tail
        private function _callbackAtTail(data:int) : MMLEvent {
            if (_nextPattern != null) {
                _setArpeggioPattern(_nextPattern);
                _nextPattern = null;
            }
            return _sequence.headEvent.next;
        }
        
        
        // set arpeggio pattern
        private function _setArpeggioPattern(pat:Array) : void {
            _sequence.initialize();
            if (pat) {
                _arpeggio = Vector.<int>(pat);
                var i:int, imax:int = pat.length, note:int = 60;
                _noteEvents.length = imax;
                _slurEvents.length = imax;
                for (i=0; i<imax; i++) {
                    var newNote:int = _scale.getNote(pat[i]);
                    if (newNote>=0 && newNote<128) note = newNote;
                    _noteEvents[i] = _sequence.appendNewEvent(MMLEvent.NOTE, note, 0);
                    _slurEvents[i] = _sequence.appendNewEvent(MMLEvent.SLUR, 0, _step);
                }
                _sequence.appendNewCallback(_callbackAtTail, 0);
            }
        }
    }
}

