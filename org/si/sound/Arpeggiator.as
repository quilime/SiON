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
    
    
    /** Arpeggiator */
    public class Arpeggiator extends Scaler
    {
    // variables
    //----------------------------------------
        /** portament */
        protected var _portament:int;
        /** arepggio pattern */
        protected var _arpeggio:Vector.<int>;
        /** Note events in the sequence */
        protected var _noteEventsNormal:Vector.<MMLEvent>;
        /** Note events in the sequence with portament */
        protected var _noteEventsPort:Vector.<MMLEvent>;
        /** Note length */
        protected var _step:int;
        /** Data for normal arpeggio */
        protected var _dataNormal:SiONData;
        /** Data for arpeggio with portament */
        protected var _dataPort:SiONData;
        
        
        
        
    // properties
    //----------------------------------------
        /** portament */
        public function get portament() : int { return _portament; }
        public function set portament(p:int) : void {
            _portament = p;
            if (_portament < 0) _portament = 0;
            var t:SiMMLTrack = track;
            if (t) t.setPortament(_portament);
            _data = (_portament == 0) ? _dataNormal : _dataPort;
        }
        
        /** note */
        override public function set note(n:int) : void {
            super.note = n;
            var i:int, imax:int = _noteEventsNormal.length;
            for (i=0; i<imax; i++) {
                var note:int = scale.getNote(_arpeggio[i] + _scaleIndex);
                _noteEventsNormal[i].data = note;
                _noteEventsPort[i].data   = note;
            }
        }
        
        
        /** index on scale */
        override public function set scaleIndex(index:int) : void {
            super.scaleIndex = index;
            var i:int, imax:int = _noteEventsNormal.length;
            for (i=0; i<imax; i++) {
                var note:int = scale.getNote(_arpeggio[i] + _scaleIndex);
                _noteEventsNormal[i].data = note;
                _noteEventsPort[i].data   = note;
            }
        }
        
        
        /** note length in 16th beat. */
        public function get noteLength() : Number {
            return _step / 120;
        }
        public function set noteLength(l:Number) : void {
            _step = l * 120;
            var i:int, imax:int = _noteEventsNormal.length;
            for (i=0; i<imax; i++) {
                _noteEventsNormal[i].length = _step;
                _noteEventsPort[i].length   = _step;
            }
        }
        
        
        /** Note index array of the arpeggio pattern. If the index is out of range, insert rest instead.*/
        public function set pattern(pat:Array) : void
        {
            if (track) {
                _dataNormal.clear();
                _dataPort.clear();
                if (pat) {
                    _arpeggio = Vector.<int>(pat);
                    var i:int, imax:int = pat.length, note:int,
                        seqNormal:MMLSequence = _dataNormal.appendNewSequence(),
                        seqPort:MMLSequence   = _dataPort.appendNewSequence();
                    _noteEventsNormal.length = imax;
                    _noteEventsPort.length = imax;
                    seqNormal.alloc().appendNewEvent(MMLEvent.REPEAT_ALL, 0);
                    seqPort.alloc().appendNewEvent(MMLEvent.REPEAT_ALL, 0);
                    for (i=0; i<imax; i++) {
                        note = scale.getNote(pat[i]);
                        if (note>=0 && note<128) {
                            _noteEventsNormal[i] = seqNormal.appendNewEvent(MMLEvent.NOTE, note, _step);
                            _noteEventsPort[i]   = seqPort.appendNewEvent(MMLEvent.NOTE, note, 0);
                            seqPort.appendNewEvent(MMLEvent.SLUR, 0, _step);
                        } else {
                            _noteEventsNormal[i] = seqNormal.appendNewEvent(MMLEvent.REST, 0, _step);
                            _noteEventsPort[i]   = seqPort.appendNewEvent(MMLEvent.REST, 0, _step);
                        }
                    }
                    _data = (_portament == 0) ? _dataNormal : _dataPort;
                }
            }
        }
        
        
        
        
    // constructor
    //----------------------------------------
        /** constructor 
         *  @param scale Scale instance.
         *  @param noteLength length for each note
         *  @param pattern arpegio pattern 
         *  @see org.si.sion.utils.Scale
         */
        function Arpeggiator(scale:Scale, noteLength:Number=2, pattern:Array=null) {
            super(scale);
            _dataNormal = new SiONData();
            _dataPort = new SiONData();
            _noteEventsNormal = new Vector.<MMLEvent>();
            _noteEventsPort = new Vector.<MMLEvent>();
            this.noteLength = noteLength;
            this.pattern = pattern;
            _portament = 0;
        }
        
        
        
        
    // operations
    //----------------------------------------
        /** Play sound. */
        override public function play() : void { 
            _data = (_portament == 0) ? _dataNormal : _dataPort;
            sequenceOn();
            var t:SiMMLTrack = track;
            if (t) t.setPortament(_portament);
        }
        
        
        /** Stop sound. */
        override public function stop() : void {
            var t:SiMMLTrack = track;
            if (t && _portament>0) t.keyOff();
            sequenceOff();
        }
    }
}

