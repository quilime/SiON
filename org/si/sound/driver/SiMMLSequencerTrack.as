//----------------------------------------------------------------------------------------------------
// Track for SiMMLSequencer.
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------




package org.si.sound.driver {
    import org.si.sound.module.SiOPMChannelBase;
    import org.si.sound.module.SiOPMTable;
    import org.si.sound.mml.MMLEvent;
    import org.si.sound.mml.MMLSequence;
    import org.si.sound.mml.MMLExecutor;
    
    import org.si.utils.SLLint;
    
    


    /** Track for SiMMLSequencer. <br/>
     *  There are 2 types of SiMMLSequencerTrack. One is "sequence track", and other is "controlable track". 
     *  The "sequence track" plays a sequence in the mml data, and the "controlable track" plays interavtive sound.
     */
    public class SiMMLSequencerTrack
    {
    // constants
    //--------------------------------------------------
        /** sweep step finess */
        static public const SWEEP_FINESS:int = 128;
        /** Fixed decimal bits. */
        static public const FIXED_BITS:int = 16;
        /** Maximum value of _sweep */
        static private const SWEEP_MAX:int = 8192<<FIXED_BITS;
        
        // _processMode
        static private const NORMAL  :int = 0;
        static private const ENVELOP :int = 2;

        
        
        
    // valiables
    //--------------------------------------------------
        /** Sound channel */
        public var channel:SiOPMChannelBase;
        
        /** Channel module setting */
        public var channelModuleSetting:SiMMLChannelSetting;

        /** MML sequence executor */
        public var executor:MMLExecutor;
        
        /** note shift */
        public var noteShift:int = 0;
        /** detune */
        public var pitchShift:int = 0;
        /** key on delay */
        public var keyOnDelay:int = 0;
        /** quantize ratio */
        public var quantRatio:Number = 0;
        /** quantize count */
        public var quantCount:int = 0;
        /** Event mask */
        public var eventMask:int = 0;
        
        /** call back function before noteOn */
        private var _callbackBeforeNoteOn:Function = null;
        /** call back function before noteOff */
        private var _callbackBeforeNoteOff:Function = null;

        // internal use
        private var _table:SiMMLTable;      // table
        private var _keyOnCounter:int;      // key on counter
        private var _keyOnLength:int;       // key on length
        private var _flagNoKeyOn:Boolean;   // key on flag
        private var _processMode:int;       // processing mode
        private var _newPitch:int;          // new pitch after key on


        // settings
        // velocity
        private var _velocity:int;
        // expression
        private var _expression:int;
        // tone number
        private var _tone:int;
        // note number
        private var _note:int;
        // default fps
        private var _defaultFPS:int;

        
        // setting
        private var _set_processMode:Vector.<int>;

        // envelop settings
        private var _set_env_exp:Vector.<SLLint>;
        private var _set_env_tone:Vector.<SLLint>;
        private var _set_env_note:Vector.<SLLint>;
        private var _set_env_pitch:Vector.<SLLint>;
        private var _set_env_filter:Vector.<SLLint>;
        private var _set_exp_offset:Vector.<Boolean>;
        private var _pns_or:Vector.<Boolean>;
        
        private var _set_cnt_exp:Vector.<int>;
        private var _set_cnt_tone:Vector.<int>;
        private var _set_cnt_note:Vector.<int>;
        private var _set_cnt_pitch:Vector.<int>;
        private var _set_cnt_filter:Vector.<int>;
        
        private var _table_env_ma:Vector.<SLLint>;
        private var _table_env_mp:Vector.<SLLint>;
        private var _set_sweep_step:Vector.<int>;
        private var _set_sweep_end:Vector.<int>;
        private var _env_internval:int;
        
        // executing envelop
        private var _env_exp:SLLint;
        private var _env_tone:SLLint;
        private var _env_note:SLLint;
        private var _env_pitch:SLLint;
        private var _env_filter:SLLint;
        
        private var _cnt_exp:int,    _max_cnt_exp:int;
        private var _cnt_tone:int,   _max_cnt_tone:int;
        private var _cnt_note:int,   _max_cnt_note:int;
        private var _cnt_pitch:int,  _max_cnt_pitch:int;
        private var _cnt_filter:int, _max_cnt_filter:int;
        
        private var _env_mp:SLLint;
        private var _env_ma:SLLint;
        private var _sweep_step:int;
        private var _sweep_end :int;
        private var _env_pitch_offset:int;
        private var _env_exp_offset:int;
        private var _env_pitch_active:Boolean;
        
        // zero table
        static private var _env_zero_table:SLLint = SLLint.allocRing(1);
        
        // residue of previous envelop process 
        private var _residue:int;
        
        // track number
        private var _trackNumber:int
        
        
        
        
    // properties
    //--------------------------------------------------
        /** track number */
        public function get trackNumber() : int { return _trackNumber; }
        
        /** Note number */
        public function get note() : int { return (channel.isNoteOn()) ? _note : -1; }
        
        
        /** Is controlable ? */
        public function get isControlable() : Boolean { return (!executor.pointer); }
        
        /** Is activate ? In the sequence track, this function always returns true. */
        public function get isActive() : Boolean { return (executor.pointer || channel.isNoteOn() || _keyOnCounter); }
        
        
        /** velocity(0-256). linked to operator's total level. */
        public function get velocity()        : int  { return _velocity; }
        public function set velocity(v:int)   : void { 
            _velocity = (v<0) ? 0 : (v>256) ? 256 : v;
            channel.offsetVolume(_expression, _velocity);
        }
        
        /** expression(0-128). linked to operator's total level. */
        public function get expression()      : int  { return _expression; }
        public function set expression(x:int) : void { 
            _expression = (x<0) ? 0 : (x>128) ? 128 : x;
            channel.offsetVolume(_expression, _velocity);
        }
        
        
        
    // constructor
    //--------------------------------------------------
        function SiMMLSequencerTrack() 
        {
            _table = SiMMLTable.instance;
            executor = new MMLExecutor();
            
            _set_processMode = new Vector.<int>(2, true);
            
            _set_env_exp    = new Vector.<SLLint>(2, true);
            _set_env_tone   = new Vector.<SLLint>(2, true);
            _set_env_note   = new Vector.<SLLint>(2, true);
            _set_env_pitch  = new Vector.<SLLint>(2, true);
            _set_env_filter = new Vector.<SLLint>(2, true);
            _pns_or         = new Vector.<Boolean>(2, true);
            _set_exp_offset = new Vector.<Boolean>(2, true);
            _set_cnt_exp    = new Vector.<int>(2, true);
            _set_cnt_tone   = new Vector.<int>(2, true);
            _set_cnt_note   = new Vector.<int>(2, true);
            _set_cnt_pitch  = new Vector.<int>(2, true);
            _set_cnt_filter = new Vector.<int>(2, true);
            _set_sweep_step = new Vector.<int>(2, true);
            _set_sweep_end  = new Vector.<int>(2, true);
            _table_env_ma   = new Vector.<SLLint>(2, true);
            _table_env_mp   = new Vector.<SLLint>(2, true);
        }
        
        
        
        
    // operations
    //--------------------------------------------------
        /** @private [internal use] initialize track. [NOTE] Have to call reset() after this. */
        internal function _initialize(seq:MMLSequence, fps:int, trackNumber:int) : SiMMLSequencerTrack
        {
            _trackNumber = trackNumber;
            _defaultFPS = fps;
            executor.initialize(seq);
            
            return this;
        }
        
        
        /** reset */
        public function reset(bufferIndex:int) : void
        {
            var i:int;
            
            // channel module setting
            channelModuleSetting = _table.channelModuleSetting[SiMMLTable.MT_PSG];
            
            // initialize channel by channelModuleSetting
            _velocity = 128;
            _expression = 128;
            _note = -1;
            channel = null;
            _tone = channelModuleSetting.initializeTone(this, 0, bufferIndex);
            
            // initialize parameters
            noteShift = 0;
            pitchShift = 0;
            _keyOnCounter = 0;
            _keyOnLength = 0;
            _flagNoKeyOn = false;
            _processMode = NORMAL;
            _newPitch = 0;
            keyOnDelay = 0;
            quantRatio = 0;
            quantCount = 0;
            eventMask = 0;
            _env_pitch_active = false;
            _env_pitch_offset = 0;
            _env_exp_offset = 0;
            setEnvelopFPS(_defaultFPS);
            _callbackBeforeNoteOn = null;
            _callbackBeforeNoteOff = null;
            _residue = 0;
            
            // reset envelop tables
            for (i=0; i<2; i++) {
                _set_processMode[i] = NORMAL;
                _set_env_exp[i]    = null;
                _set_env_tone[i]   = null;
                _set_env_note[i]   = _env_zero_table;
                _set_env_pitch[i]  = _env_zero_table;
                _set_env_filter[i] = null;
                _pns_or[i]         = false;
                _set_exp_offset[i] = false;
                _set_cnt_exp[i]    = 1;
                _set_cnt_tone[i]   = 1;
                _set_cnt_note[i]   = 1;
                _set_cnt_pitch[i]  = 1;
                _set_cnt_filter[i] = 1;
                _set_sweep_step[i] = 0;
                _set_sweep_end[i]  = 0;
                _table_env_ma[i]   = null;
                _table_env_mp[i]   = null;
            }
            
            // reset pointer
            executor.resetPointer();
        }
        
        
        
        
    // processing
    //--------------------------------------------------
        /** @private [internal use] process */
        internal function process(length:int) : void
        {
            if (_keyOnCounter == 0) {
                // no status changing
                _process(length);
            } else 
            if (_keyOnCounter > length) {
                // decrement _keyOnCounter
                _process(length);
                _keyOnCounter -= length;
            } else {
                // process -> toggle key -> process
                length -= _keyOnCounter;
                _process(_keyOnCounter);
                _toggleKey();
                if (length>0) _process(length);
            }
        }
        
        
        // processing
        private function _process(length:int) : void
        {
            switch(_processMode) {
            case NORMAL:
                channel.buffer(length);
                break;
            case ENVELOP:
                _residue = _processEnvelop(length, _residue);
                break;
            }
        }
        
        
        // process envelops
        private function _processEnvelop(length:int, step:int) : int
        {
            var x:int;
            
            while (length >= step) {
                // processing
                if (step > 0) channel.buffer(step);
                
                // change expression
                if (_env_exp && --_cnt_exp == 0) {
                    x = _env_exp_offset + _env_exp.i;
                    if (x<0) {x=0;} else if (x>128) {x=128;}
                    channel.offsetVolume(x, _velocity);
                    _env_exp = _env_exp.next;
                    _cnt_exp = _max_cnt_exp;
                }
                
                // change pitch/note
                if (_env_pitch_active) {
                    channel.pitch = _env_pitch.i + (_env_note.i<<6) + (_env_pitch_offset>>FIXED_BITS);
                    // pitch envelop
                    if (--_cnt_pitch == 0) {
                        _env_pitch = _env_pitch.next;
                        _cnt_pitch = _max_cnt_pitch;
                    }
                    // note envelop
                    if (--_cnt_note == 0) {
                        _env_note = _env_note.next;
                        _cnt_note = _max_cnt_note;
                    }
                    // sweep
                    _env_pitch_offset += _sweep_step;
                    if (_sweep_step>0) {
                        if (_env_pitch_offset > _sweep_end) {
                            _env_pitch_offset = _sweep_end;
                            _sweep_step = 0;
                        }
                    } else {
                        if (_env_pitch_offset < _sweep_end) {
                            _env_pitch_offset = _sweep_end;
                            _sweep_step = 0;
                        }
                    }
                }
                
                // change filter
                if (_env_filter && --_cnt_filter == 0) {
                    channel.setFilterOffset(_env_filter.i);
                    _env_filter = _env_filter.next;
                    _cnt_filter = _max_cnt_filter;
                }
                
                // change tone
                if (_env_tone && --_cnt_tone == 0) {
                    channelModuleSetting.selectTone(this, _env_tone.i);
                    _env_tone = _env_tone.next;
                    _cnt_tone = _max_cnt_tone;
                }
                
                // change modulations
                if (_env_ma) {
                    channel.setAmplitudeModulation(_env_ma.i);
                    _env_ma = _env_ma.next;
                }
                if (_env_mp) {
                    channel.setPitchModulation(_env_mp.i);
                    _env_mp = _env_mp.next;
                }
                
                // index increment
                length -= step;
                step = _env_internval;
            }

            // rest process
            if (length > 0) channel.buffer(length);
            
            // next rest length
            return _env_internval - length;
        }
        
        
        
        
    // note on/off
    //--------------------------------------------------
        // toggle note
        private function _toggleKey() : void
        {
            if (channel.isNoteOn()) _keyOff();
            else _keyOn();
        }
        
        
        // note off
        private function _keyOff() : void
        {
            // callback
            if (_callbackBeforeNoteOff != null) {
                if (!_callbackBeforeNoteOff(this)) return;
            }
            
            // note off
            channel.noteOff();
            // no key off after this
            _keyOnCounter = 0;
             // update process
            _updateProcess(0);
        }
        
        
        // note on
        private function _keyOn() : void
        {
            // callback
            if (_callbackBeforeNoteOn != null) {
                if (!_callbackBeforeNoteOn(this, _newPitch)) return;
            }
            
            // change pitch
            channel.pitch = _newPitch;

            // note on
            if (!_flagNoKeyOn) {
                // reset previous envelop
                if (_processMode == ENVELOP) {
                    channel.offsetVolume(_expression, _velocity);
                    channelModuleSetting.selectTone(this, _tone);
                    channel.setFilterOffset(128);
                }
                // previous note off
                if (channel.isNoteOn()) {
                    // callback
                    if (_callbackBeforeNoteOff != null) _callbackBeforeNoteOff(this);
                    channel.noteOff();
                }
                // update process
                _updateProcess(1);
                // note on
                channel.noteOn();
            } else {
                // try to set envelop off
                _envelopOff(1);
            }
            
            _flagNoKeyOn = false;
            
            // set key on counter
            _keyOnCounter = _keyOnLength;
            if (_keyOnCounter <= 0) _keyOff();
        }
        
        
        private function _updateProcess(keyOn:int) : void
        {
            // prepare next process
            _processMode = _set_processMode[keyOn];
            
            if (_processMode == ENVELOP) {
                // set envelop tables
                _env_exp    = _set_env_exp[keyOn];
                _env_tone   = _set_env_tone[keyOn];
                _env_note   = _set_env_note[keyOn];
                _env_pitch  = _set_env_pitch[keyOn];
                _env_filter = _set_env_filter[keyOn];
                // set envelop counters
                _max_cnt_exp    = _set_cnt_exp[keyOn];
                _max_cnt_tone   = _set_cnt_tone[keyOn];
                _max_cnt_note   = _set_cnt_note[keyOn];
                _max_cnt_pitch  = _set_cnt_pitch[keyOn];
                _max_cnt_filter = _set_cnt_filter[keyOn];
                _cnt_exp    = 1;
                _cnt_tone   = 1;
                _cnt_note   = 1;
                _cnt_pitch  = 1;
                _cnt_filter = 1;
                // set modulation envelops
                _env_ma = _table_env_ma[keyOn];
                _env_mp = _table_env_mp[keyOn];
                // set sweep
                _sweep_step = _set_sweep_step[keyOn];
                _sweep_end  = _set_sweep_end[keyOn];
                // set pitch values
                _env_pitch_offset = channel.pitch << FIXED_BITS;
                _env_exp_offset   = (_set_exp_offset[keyOn]) ? _expression : 0;
                _env_pitch_active = _pns_or[keyOn];
                // activate filter
                channel.activateFilter(Boolean(_env_filter));
                // reset index
                _residue = 0;
            }
        }
        
        
        
        
    // event handlers
    //--------------------------------------------------
        /** @private [internal use] handler for rest. */
        internal function _setRest() : void
        {
        }
        

        /** @private [internal use] handler for note. */
        internal function _setNote(note:int, length:int) : void
        {
            _note = note;
            _newPitch = ((note + noteShift)<<6) + pitchShift;
            _keyOnLength = int(length * quantRatio) - quantCount - keyOnDelay;
            
            if (length) {
                if (keyOnDelay) {
                    _keyOff();
                    _keyOnCounter = keyOnDelay;
                } else {
                    _keyOn();
                }
            } else {
                // slur event after this note
                _keyOnLength = 1;   // not to switch key off in keyOn().
                _keyOn();           // key on
                _keyOnCounter = 0;  // keep key on in process
            }
        }
        
        
        /** @private [internal use] slur with next notes key on. */
        internal function _setSlurWeak() : void
        {
            _keyOnCounter = 0;
        }
        
        
        /** @private [internal use] slur without next notes key on. */
        internal function _setSlur() : void
        {
            _flagNoKeyOn = true;
            _keyOnCounter = 0;
        }
        
        
        /** @private [internal use] pitch bend (and slur) */
        internal function _setPitchBend(nextNote:int, term:int) : void
        {
            var startPitch:int = channel.pitch,
                endPitch  :int = (((nextNote + noteShift)<<6) || (startPitch & 63)) + pitchShift;
            _setSlur();
            if (startPitch == endPitch) return;
            
            _sweep_step = ((endPitch - startPitch) << FIXED_BITS) * _env_internval / term;
            _sweep_end  = endPitch << FIXED_BITS;
            _env_pitch_offset = startPitch << FIXED_BITS;
            _env_pitch_active = true;
            _env_note  = _set_env_note[1];
            _env_pitch = _set_env_pitch[1];
            
            _processMode = ENVELOP;
        }
        
        
        
        
    // interface
    //--------------------------------------------------
        /** Set track callback function. The callback functions are called at the timing of streaming before SiOPMEvent.STREAM event.
         *  @param noteOn Callback function before note on. This function refers this track instance and new pitch (0-8192) as an arguments. When the function returns false, noteOn will be canceled.</br>
         *  function callbackNoteOn(track:SiMMLSequencerTrack, newPitch:int) : Boolean { return true; }
         *  @param noteOff Callback function before note off. This function refers this track instance as an argument. When the function returns false, noteOff will be canceled.<br/>
         *  function callbackNoteOff(track:SiMMLSequencerTrack) : Boolean { return true; }
         */
        public function setTrackCallback(noteOn:Function=null, noteOff:Function=null) : void
        {
            _callbackBeforeNoteOn  = noteOn;
            _callbackBeforeNoteOff = noteOff;
        }

        
        /** Key on. 
         *  @param note Note number.
         *  @param length Length in samples. The argument of 0 sets no key off.
         */
        public function keyOn(note:int, length:int=0) : void
        {
            _note = note;
            _newPitch = ((note + noteShift)<<6) + pitchShift;
            _keyOnLength = length;
            
            if (length) {
                if (keyOnDelay) {
                    _keyOff();
                    _keyOnCounter = keyOnDelay;
                } else {
                    _keyOn();
                }
            } else {
                _keyOnLength = 1;   // not to switch key off in keyOn().
                _keyOn();           // key on
                _keyOnCounter = 0;  // keep key on in process
            }
        }
        
        
        /** Force key off */
        public function keyOff() : void
        {
            _keyOff();
        }
        
        
        
        
    // mml events
    //--------------------------------------------------
        /** Channel module type (%, %e).
         *  @param type Channel module type
         *  @param channelNum Channel number to emulate.
         */
        public function setChannelModuleType(type:int, channelNum:int) : void
        {
            // change module type
            channelModuleSetting = _table.channelModuleSetting[type];
            
            // reset operator pgType
            _tone = channelModuleSetting.initializeTone(this, channelNum, channel.bufferIndex);
        }
        
        
        /** Channel parameters (@)
         *  @param param Parameters of @ command.
         */
        public function setChannelParameters(param:Vector.<int>) : MMLSequence
        {
            var ret:MMLSequence = null;
            if (param[0] != int.MIN_VALUE) {
                _tone = param[0];
                ret = channelModuleSetting.selectTone(this, _tone);
            }
            channel.setParameters(param);
            return ret;
        }
        
        
        /** portament (po) */
        public function setPortament(frame:int) : void
        {
        }
        
        
        /** set envelop step (@fps) */
        public function setEnvelopFPS(fps:int) : void
        {
            _env_internval = SiOPMTable.instance.rate / fps;
        }
        
        
        /** release sweep (s,) */
        public function setReleaseSweep(sweep:int) : void
        {
            _set_sweep_step[0] = sweep << FIXED_BITS;
            _set_sweep_end[0]  = (sweep<0) ? 0 : SWEEP_MAX;
            if (sweep) {
                _pns_or[0] = true;
                _envelopOn(0);
            } else {
                _envelopOff(0);
            }
        }
        
        
        /** amplitude/pitch modulation envelop (ma, mp) */
        public function setModulationEnvelop(isPitchMod:Boolean, depth:int, end_depth:int, delay:int, term:int) : void
        {
            // select table
            var table:Vector.<SLLint> = (isPitchMod) ? _table_env_mp : _table_env_ma;
            
            // free previous table
            if (table[1]) SLLint.freeList(table[1]);
            
            if (depth < end_depth) {
                // make table and envelop on
                table[1] = _makeModulationTable(depth, end_depth, delay, term);
                _envelopOn(1);
            } else {
                // free table and envelop off
                table[1] = null;
                if (isPitchMod) channel.setPitchModulation(depth);
                else            channel.setAmplitudeModulation(depth);
                _envelopOff(1);
            }
        }
        
        
        
        
    // table envelop
    //--------------------------------------------------
        /** set tone envelop (@@, _@@) */
        public function setToneEnvelop(noteOn:int, tableNum:int, step:int) : void
        {
            if (tableNum != 255 && step != 0 && tableNum != int.MIN_VALUE && _table.envelopTables[tableNum]) {
                _set_env_tone[noteOn] = _table.envelopTables[tableNum].head;
                _set_cnt_tone[noteOn] = step;
                _envelopOn(noteOn);
            } else {
                _set_env_tone[noteOn] = null;
                _envelopOff(noteOn);
            }
        }
        
        
        /** set amplitude envelop (na, _na) */
        public function setAmplitudeEnvelop(noteOn:int, tableNum:int, step:int, offset:Boolean = false) : void
        {
            if (tableNum != 255 && step != 0 && tableNum != int.MIN_VALUE && _table.envelopTables[tableNum]) {
                _set_env_exp[noteOn] = _table.envelopTables[tableNum].head;
                _set_cnt_exp[noteOn] = step;
                _set_exp_offset[noteOn] = offset;
                _envelopOn(noteOn);
            } else {
                _set_env_exp[noteOn] = null;
                _envelopOff(noteOn);
            }
        }
        
        
        /** set filter envelop (nf, _nf) */
        public function setFilterEnvelop(noteOn:int, tableNum:int, step:int) : void
        {
            if (tableNum != 255 && step != 0 && tableNum != int.MIN_VALUE && _table.envelopTables[tableNum]) {
                _set_env_filter[noteOn] = _table.envelopTables[tableNum].head;
                _set_cnt_filter[noteOn] = step;
                _envelopOn(noteOn);
            } else {
                _set_env_filter[noteOn] = null;
                _envelopOff(noteOn);
            }
        }
        
        
        /** set pitch envelop (np, _np) */
        public function setPitchEnvelop(noteOn:int, tableNum:int, step:int) : void
        {
            if (tableNum != 255 && step != 0 && tableNum != int.MIN_VALUE && _table.envelopTables[tableNum]) {
                _set_env_pitch[noteOn] = _table.envelopTables[tableNum].head;
                _set_cnt_pitch[noteOn] = step;
                _pns_or[noteOn]        = true;
                _envelopOn(noteOn);
            } else {
                _set_env_pitch[noteOn] = _env_zero_table;
                _envelopOff(noteOn);
            }
        }
        
        
        /** set note envelop (nt, _nt) */
        public function setNoteEnvelop(noteOn:int, tableNum:int, step:int) : void
        {
            if (tableNum != 255 && step != 0 && tableNum != int.MIN_VALUE && _table.envelopTables[tableNum]) {
                _set_env_note[noteOn] = _table.envelopTables[tableNum].head;
                _set_cnt_note[noteOn] = step;
                _pns_or[noteOn]       = true;
                _envelopOn(noteOn);
            } else {
                _set_env_note[noteOn]  = _env_zero_table;
                _envelopOff(noteOn);
            }
        }
        
        
        
        
    // private subs
    //--------------------------------------------------
        // envelop off
        private function _envelopOff(noteOn:int) : void
        {
            // update (pitch || note || sweep)
            if (_set_sweep_step[0] == 0  && 
                _set_env_pitch[noteOn] === _env_zero_table && 
                _set_env_note[noteOn]  === _env_zero_table)
            {
                _pns_or[noteOn] = false;
            }
            
            // all envelops are off -> update processMode
            if (!_pns_or[noteOn]         && 
                !_table_env_ma[noteOn]   && 
                !_table_env_mp[noteOn]   && 
                !_set_env_exp[noteOn]    && 
                !_set_env_filter[noteOn] && 
                !_set_env_tone[noteOn])
            {
                _set_processMode[noteOn] = NORMAL;
            }
        }
        
        
        // envelop on
        private function _envelopOn(noteOn:int) : void
        {
            _set_processMode[noteOn] = ENVELOP;
        }
        
        
        // make modulation table
        private function _makeModulationTable(depth:int, end_depth:int, delay:int, term:int) : SLLint
        {
            // initialize
            var list:SLLint = SLLint.allocList(delay + term + 1),
                i:int, elem:SLLint, step:int;
            
            // delay
            elem = list;
            if (delay) {
                for (i=0; i<delay; i++, elem=elem.next) {
                    elem.i = depth;
                }
            }
            // changing
            if (term) {
                depth <<= FIXED_BITS;
                step = ((end_depth<<FIXED_BITS) - depth) / term;
                for (i=0; i<term; i++, elem=elem.next) { 
                    elem.i = (depth >> FIXED_BITS);
                    depth += step;
                }
            }
            // last data
            elem.i = end_depth;
            
            return list;
        }
    }
}

