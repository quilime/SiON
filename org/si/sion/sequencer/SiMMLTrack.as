//----------------------------------------------------------------------------------------------------
// Track for SiMMLSequencer.
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.sequencer {
    import org.si.utils.SLLint;
    import org.si.sion.module.SiOPMChannelBase;
    import org.si.sion.module.SiOPMTable;
    import org.si.sion.sequencer.base.MMLEvent;
    import org.si.sion.sequencer.base.MMLSequence;
    import org.si.sion.sequencer.base.MMLExecutor;
    

    /** Track for SiMMLSequencer. <br/>
     *  There are 2 types of SiMMLTrack. One is "sequence track", and another is "controlable track". 
     *  The "sequence track" plays a sequence in the mml data, and the "controlable track" plays interavtive sound.
     */
    public class SiMMLTrack
    {
    // constants
    //--------------------------------------------------
        /** sweep step finess */
        static public const SWEEP_FINESS:int = 128;
        /** Fixed decimal bits. */
        static public const FIXED_BITS:int = 16;
        /** Maximum value of _sweep */
        static private const SWEEP_MAX:int = 8192<<FIXED_BITS;
        
        /** track id filter */
        static public const TRACK_ID_FILTER:int = 0xffff;
        /** track type filter */
        static public const TRACK_TYPE_FILTER:int = 0xff0000;
        /** MML track id offset */
        static public const MML_TRACK_ID_OFFSET:int = 0x10000;
        /** MIDI track id offset */
        static public const MIDI_TRACK_ID_OFFSET:int = 0x20000;
        /** driver track id offset */
        static public const DRIVER_NOTE_ID_OFFSET:int = 0x30000;
        /** driver track id offset */
        static public const DRIVER_SEQUENCE_ID_OFFSET:int = 0x30000;
        
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
        /** Channel number */
        public var channelNumber:int = 0;
        
        // call back function before noteOn/noteOff
        private var _callbackBeforeNoteOn:Function = null;
        private var _callbackBeforeNoteOff:Function = null;
        
        // event trriger
        private var _eventTriggerOn:Function = null;
        private var _eventTriggerOff:Function = null;
        private var _eventTriggerID:int;
        private var _eventTriggerTypeOn:int;
        private var _eventTriggerTypeOff:int;
        
        private var _trackID:int;           // track ID number

        // internal use
        private var _table:SiMMLTable;      // table
        private var _keyOnCounter:int;      // key on counter
        private var _keyOnLength:int;       // key on length
        private var _flagNoKeyOn:Boolean;   // key on flag
        private var _processMode:int;       // processing mode
        private var _newPitch:int;          // new pitch after key on
        private var _trackStartDelay:int;   // track delay to start
        private var _trackStopDelay:int;    // track delay to stop

        // settings
        private var _velocity:int;      // velocity
        private var _expression:int;    // expression
        private var _tone:int;          // tone number
        private var _note:int;          // note number
        private var _defaultFPS:int;    // default fps
        
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
        
        private var _residue:int;   // residue of previous envelop process 
        
        // zero table
        static private var _env_zero_table:SLLint = SLLint.allocRing(1);
        
        
        
        
    // properties
    //--------------------------------------------------
        /** track ID number. */
        public function get trackID() : int { return _trackID; }

        /** event trigger ID. eventTriggerID=-1 means tigger not set. */
        public function get eventTriggerID() : int { return _eventTriggerID; }
        /** Note on event trigger type. eventTriggerTypeOn=0 means tigger not set. */
        public function get eventTriggerTypeOn() : int { return _eventTriggerTypeOn; }
        /** Note off event trigger type. eventTriggerTypeOff=0 means tigger not set. */
        public function get eventTriggerTypeOff() : int { return _eventTriggerTypeOff; }
        
        /** Note number */
        public function get note() : int { return _note; }
        
        /** Start delay in sample count. Ussualy this returns 0 except after SiONDriver.noteOn. */
        public function get trackStartDelay() : int { return _trackStartDelay; }
        
        /** Stop delay in sample count. Ussualy this returns 0 except after SiONDriver.noteOff. */
        public function get trackStopDelay() : int { return _trackStopDelay; }
        
        /** Is controlable ? */
        public function get isControlable() : Boolean { return ((_trackID & TRACK_TYPE_FILTER) != MML_TRACK_ID_OFFSET); }
        
        /** Is activate ? This function always returns true from the MML sequence track. */
        public function get isActive() : Boolean { return (!isControlable || !channel.isIdling || _keyOnCounter>0 || _trackStartDelay>0); }
        
        /** Is finish to buffering ? */
        public function get isFinished() : Boolean { return (executor.pointer==null && channel.isIdling && _keyOnCounter==0 && _trackStartDelay==0); }
        
        
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
        
        /** output level = @v * v * x. */
        public function get outputLevel() : Number {
            return channel.masterVolume * _velocity * _expression * 4.76837158203125e-7; // 1/(128^3)
        }
        
        /** pannning */
        public function get pan() : int {
            return channel.pan;
        }
        
        /** program number. this value has no meaning. */
        public function get programNumber() : int {
            return _tone;
        }
        
        
        
    // constructor
    //--------------------------------------------------
        function SiMMLTrack() 
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
        internal function _initialize(seq:MMLSequence, fps:int, trackID:int, eventTriggerOn:Function, eventTriggerOff:Function) : SiMMLTrack
        {
            _trackID = trackID;
            _defaultFPS = fps;
            _eventTriggerOn = eventTriggerOn;
            _eventTriggerOff = eventTriggerOff;
            _eventTriggerID = -1;
            _eventTriggerTypeOn = 0;
            _eventTriggerTypeOff = 0;
            executor.initialize(seq);
            
            return this;
        }
        
        
        /** reset */
        public function reset(bufferIndex:int) : void
        {
            var i:int;
            
            // channel module setting
            channelModuleSetting = _table.channelModuleSetting[SiMMLTable.MT_PSG];
            channelNumber = 0;
            
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
            _trackStartDelay = 0;
            _trackStopDelay = 0;
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
        
        
        
        
    // interfaces for intaractive operations
    //--------------------------------------------------
        /** Set track callback function. The callback functions are called at the timing of streaming before SiOPMEvent.STREAM event.
         *  @param noteOn Callback function before note on. This function refers this track instance and new pitch (0-8192) as an arguments. When the function returns false, noteOn will be canceled.</br>
         *  function callbackNoteOn(track:SiMMLTrack, newPitch:int) : Boolean { return true; }
         *  @param noteOff Callback function before note off. This function refers this track instance as an argument. When the function returns false, noteOff will be canceled.<br/>
         *  function callbackNoteOff(track:SiMMLTrack) : Boolean { return true; }
         */
        public function setTrackCallback(noteOn:Function=null, noteOff:Function=null) : SiMMLTrack
        {
            _callbackBeforeNoteOn  = noteOn;
            _callbackBeforeNoteOff = noteOff;
            return this;
        }

        
        /** Key on. 
         *  @param note Note number.
         *  @param length Length in sample count. The argument of 0 sets no key off.
         *  @param delay Delaying time (in sample count).
         */
        public function keyOn(note:int, length:int=0, delay:int=0) : SiMMLTrack
        {
            _note = note;
            _newPitch = ((note + noteShift)<<6) + pitchShift;
            _keyOnLength = length;
            _trackStartDelay = delay;
            
            if (length > 0) {
                if (keyOnDelay) {
                    _keyOff();
                    _keyOnCounter = keyOnDelay;
                } else {
                    _keyOn();
                }
            } else {
                _keyOnLength = 1;   // not to switch key off in _keyOn().
                _keyOn();           // key on
                _keyOnCounter = 0;  // keep key on in process
            }
            return this;
        }
        
        
        /** Force key off */
        public function keyOff(delay:int=0) : SiMMLTrack
        {
            if (delay) {
                _trackStopDelay = delay;
            } else {
                _keyOff();
                _note = -1;
            }
            return this;
        }
        
        
        /** Play sequence.
         *  @param seq Sequence to play.
         *  @param delay Delaying time (in sample count).
         */
        public function sequenceOn(seq:MMLSequence, delay:int=0, length:int=0) : SiMMLTrack
        {
            _trackStartDelay = delay;
            _trackStopDelay = length;
            executor.initialize(seq);
            return this;
        }
        
        
        /** Force stop sequence. */
        public function sequenceOff(delay:int=0) : SiMMLTrack
        {
            if (delay) _trackStopDelay = delay;
            else executor.clear();
            return this;
        }
        
        
        /** Slur without next notes key on. This have to be called just after keyOn(). */
        public function setSlur() : void
        {
            _flagNoKeyOn = true;
            _keyOnCounter = 0;
        }

        
        /** Slur with next notes key on. This have to be called just after keyOn(). */
        public function setSlurWeak() : void
        {
            _keyOnCounter = 0;
        }
        
        
        /** Pitch bend (and slur) 
         *  @param nextNote The 2nd note to intergradate.
         *  @param term bending time in sample count.
         */
        public function setPitchBend(nextNote:int, term:int) : void
        {
            var startPitch:int = channel.pitch,
                endPitch  :int = (((nextNote + noteShift)<<6) || (startPitch & 63)) + pitchShift;
            setSlur();
            if (startPitch == endPitch) return;
            
            _sweep_step = ((endPitch - startPitch) << FIXED_BITS) * _env_internval / term;
            _sweep_end  = endPitch << FIXED_BITS;
            _env_pitch_offset = startPitch << FIXED_BITS;
            _env_pitch_active = true;
            _env_note  = _set_env_note[1];
            _env_pitch = _set_env_pitch[1];
            
            _processMode = ENVELOP;
        }
        
        
        /** Limit key on length. 
         *  @param stopDelay delay to key-off.
         */
        public function limitLength(stopDelay:int) : void
        {
            var length:int = stopDelay - _trackStartDelay;
            if (length < _keyOnCounter) {
                _keyOnLength = stopDelay - _trackStartDelay;
                _keyOnCounter = _keyOnLength;
            }
        }
        
        
        
        
    // interfaces for mml command
    //--------------------------------------------------
        /** Channel module type (%) and select tone (1st argument of '@').
         *  @param type Channel module type
         *  @param channelNum Channel number. For %2-5 and %7-10, this value is same as 1st argument of '@'.
         *  @param toneNum Tone number. Ussualy, this argument is used only in %0;PSG, %1;APU and %6;FM.
         */
        public function setChannelModuleType(type:int, channelNum:int, toneNum:int=-1) : void
        {
            // change module type
            channelModuleSetting = _table.channelModuleSetting[type];
            
            // reset operator pgType
            _tone = channelModuleSetting.initializeTone(this, channelNum, channel.bufferIndex);
            
            // select tone
            if (toneNum != -1) channelModuleSetting.selectTone(this, toneNum);
        }
        
        
        /** portament (po).
         *  @param frame portament changing time in frame count.
         */
        public function setPortament(frame:int) : void
        {
            _set_sweep_step[1] = frame;
            if (frame) {
                _pns_or[1] = true;
                _envelopOn(1);
            } else {
                _envelopOff(1);
            }
        }
        
        
        /** set event trigger (%t) 
         *  @param id Event trigger ID of this track. This value can be refered from SiONTrackEvent.eventTriggerID.
         *  @param noteOnType Dispatching event type at note on. 0=no events, 1=NOTE_ON_FRAME, 2=NOTE_ON_STREAM, 3=both.
         *  @param noteOffType Dispatching event type at note off. 0=no events, 1=NOTE_OFF_FRAME, 2=NOTE_OFF_STREAM, 3=both.
         *  @see org.si.sion.events.SiONTrackEvent
         */
        public function setEventTrigger(id:int, noteOnType:int=1, noteOffType:int=0) : void
        {
            _eventTriggerID = id;
            _eventTriggerTypeOn  = noteOnType;
            _eventTriggerTypeOff = noteOffType;
            _callbackBeforeNoteOn = (noteOnType) ? _eventTriggerOn : null;
            _callbackBeforeNoteOff = (noteOffType) ? _eventTriggerOff : null;
        }
        
        
        /** dispatch note on event once (%e) 
         *  @param id Event trigger ID of this track. This value can be refered from SiONTrackEvent.eventTriggerID.
         *  @param noteOnType Dispatching event type at note on. 0=no events, 1=NOTE_ON_FRAME, 2=NOTE_ON_STREAM, 3=both.
         *  @see org.si.sion.events.SiONTrackEvent
         */
        public function dispatchNoteOnEvent(id:int, noteOnType:int=1) : void
        {
            if (noteOnType) {
                var currentTID:int  = _eventTriggerID, 
                    currentType:int = _eventTriggerTypeOn;
                _eventTriggerID = id;
                _eventTriggerTypeOn = noteOnType;
                _eventTriggerOn(this, 0);
                _eventTriggerID = currentTID;
                _eventTriggerTypeOn = currentType;
            }
        }
        
        
        /** set envelop step (&#64;fps) 
         *  @param fps Frame par second
         */
        public function setEnvelopFPS(fps:int) : void
        {
            _env_internval = SiOPMTable.instance.rate / fps;
        }
        
        
        /** release sweep (2nd argument of "s")
         *  @param sweep sweeping speed
         */
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
        
        
        /** amplitude/pitch modulation envelop (ma, mp) 
         *  @param isPitchMod The command is 'ma' or 'mp'.
         *  @param depth start modulation depth (same as 1st argument)
         *  @param end_depth end modulation depth (same as 2nd argument)
         *  @param delay changing delay (same as 3rd argument)
         *  @param term changing term (same as 4th argument)
         */
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
        
        
        /** set tone envelop (&#64;&#64;, _&#64;&#64;) 
         *  @param noteOn 1 for normal envelop, 0 for not-off envelop.
         *  @param table table SiMMLEnvelopTable
         *  @param step envelop speed (same as 2nd argument)
         */
        public function setToneEnvelop(noteOn:int, table:SiMMLEnvelopTable, step:int) : void
        {
            if (table==null || step==0) {
                _set_env_tone[noteOn] = null;
                _envelopOff(noteOn);
            } else {
                _set_env_tone[noteOn] = table.head;
                _set_cnt_tone[noteOn] = step;
                _envelopOn(noteOn);
            }
        }
        
        
        /** set amplitude envelop (na, _na) 
         *  @param noteOn 1 for normal envelop, 0 for not-off envelop.
         *  @param table table SiMMLEnvelopTable
         *  @param step envelop speed (same as 2nd argument)
         *  @param offset true for relative control (!na command), false for absolute control.
         */
        public function setAmplitudeEnvelop(noteOn:int, table:SiMMLEnvelopTable, step:int, offset:Boolean = false) : void
        {
            if (table==null || step==0) {
                _set_env_exp[noteOn] = null;
                _envelopOff(noteOn);
            } else {
                _set_env_exp[noteOn] = table.head;
                _set_cnt_exp[noteOn] = step;
                _set_exp_offset[noteOn] = offset;
                _envelopOn(noteOn);
            }
        }
        
        
        /** set filter envelop (nf, _nf)
         *  @param noteOn 1 for normal envelop, 0 for not-off envelop.
         *  @param table table SiMMLEnvelopTable
         *  @param step envelop speed (same as 2nd argument)
         */
        public function setFilterEnvelop(noteOn:int, table:SiMMLEnvelopTable, step:int) : void
        {
            if (table==null || step==0) {
                _set_env_filter[noteOn] = null;
                _envelopOff(noteOn);
            } else {
                _set_env_filter[noteOn] = table.head;
                _set_cnt_filter[noteOn] = step;
                _envelopOn(noteOn);
            }
        }
        
        
        /** set pitch envelop (np, _np)
         *  @param noteOn 1 for normal envelop, 0 for not-off envelop.
         *  @param table table SiMMLEnvelopTable
         *  @param step envelop speed (same as 2nd argument)
         */
        public function setPitchEnvelop(noteOn:int, table:SiMMLEnvelopTable, step:int) : void
        {
            if (table==null || step==0) {
                _set_env_pitch[noteOn] = _env_zero_table;
                _envelopOff(noteOn);
            } else {
                _set_env_pitch[noteOn] = table.head;
                _set_cnt_pitch[noteOn] = step;
                _pns_or[noteOn]        = true;
                _envelopOn(noteOn);
            }
        }
        
        
        /** set note envelop (nt, _nt)
         *  @param noteOn 1 for normal envelop, 0 for not-off envelop.
         *  @param table table SiMMLEnvelopTable
         *  @param step envelop speed (same as 2nd argument)
         */
        public function setNoteEnvelop(noteOn:int, table:SiMMLEnvelopTable, step:int) : void
        {
            if (table==null || step==0) {
                _set_env_note[noteOn] = _env_zero_table;
                _envelopOff(noteOn);
            } else {
                _set_env_note[noteOn] = table.head;
                _set_cnt_note[noteOn] = step;
                _pns_or[noteOn]       = true;
                _envelopOn(noteOn);
            }
        }
        
        
        
        
    //====================================================================================================
    // Internal uses
    //====================================================================================================
    // processing
    //--------------------------------------------------
        /** @private [internal use] prepare buffer */
        internal function prepareBuffer(bufferingTick:int) : int
        {
            // almost executing this
            if (_trackStartDelay == 0) return bufferingTick;
            
            if (bufferingTick <= _trackStartDelay) {
                _trackStartDelay -= bufferingTick;
                return 0;
            }
            
            var len:int = bufferingTick - _trackStartDelay;
            channel.nop(_trackStartDelay);
            _trackStartDelay = 0;
            return len;
        }
        
        
        /** @private [internal use] buffering */
        internal function buffer(length:int) : void
        {
            // check track stopping
            var trackStop:Boolean = false, trackStopResume:int = 0;
            if (_trackStopDelay > 0) {
                if (_trackStopDelay > length) {
                    _trackStopDelay -= length;
                } else {
                    trackStopResume = length - _trackStopDelay;
                    trackStop = true;
                    length = _trackStopDelay;
                    _trackStopDelay = 0;
                }
            }
            
            // buffeirng
            if (_keyOnCounter == 0) {
                // no status changing
                $(length);
            } else 
            if (_keyOnCounter > length) {
                // decrement _keyOnCounter
                $(length);
                _keyOnCounter -= length;
            } else {
                // process -> toggle key -> process
                length -= _keyOnCounter;
                $(_keyOnCounter);
                _toggleKey();
                if (length>0) $(length);
            }
            
            // track stop
            if (trackStop) {
                if (executor.pointer) {
                    executor.stop();
                } else if (channel.isNoteOn()) {
                    _keyOff();
                    _note = -1;
                }
                if (trackStopResume>0) $(trackStopResume);
            }
            
            // processing inside
            function $(procLen:int) : void {
                switch(_processMode) {
                case NORMAL:    channel.buffer(procLen);                       break;
                case ENVELOP:   _residue = _bufferEnvelop(procLen, _residue);  break;
                }
            }
        }
        
        
        // buffering with table envelops
        private function _bufferEnvelop(length:int, step:int) : int
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
        
        
        
        
    // key on/off
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
            var oldPitch:int = channel.pitch;
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
                // portament
                if (_set_sweep_step[1]>0) {
                    channel.pitch = oldPitch;
                    _sweep_step = ((_newPitch - oldPitch) << FIXED_BITS) / _set_sweep_step[1];
                    _sweep_end  = _newPitch << FIXED_BITS;
                    _env_pitch_offset = oldPitch << FIXED_BITS;
                }
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
                _sweep_step = (keyOn) ? 0 : _set_sweep_step[keyOn];
                _sweep_end  = (keyOn) ? 0 : _set_sweep_end[keyOn];
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
        /** @private [internal use] handler for MMLEvent.REST. */
        internal function _setRest() : void
        {
        }
        

        /** @private [internal use] handler for MMLEvent.NOTE. */
        internal function _setNote(note:int, length:int) : void
        {
            length = int(length * quantRatio) - quantCount - keyOnDelay;
            if (length < 1) length = 1;
            keyOn(note, length);
        }
        
        
        /** @praivate [internal use] Channel parameters (&#64;) */
        internal function _setChannelParameters(param:Vector.<int>) : MMLSequence
        {
            var ret:MMLSequence = null;
            if (param[0] != int.MIN_VALUE) {
                ret = channelModuleSetting.selectTone(this, param[0]);
                _tone = param[0];
            }
            channel.setParameters(param);
            return ret;
        }
        
        
        
        
    // private subs
    //--------------------------------------------------
        // envelop off
        private function _envelopOff(noteOn:int) : void
        {
            // update (pitch || note || sweep)
            if (_set_sweep_step[noteOn] == 0  && 
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

