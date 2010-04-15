//----------------------------------------------------------------------------------------------------
// Class for play drum tracks
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound {
    import org.si.sion.SiONData;
    import org.si.sion.sequencer.SiMMLTrack;
    import org.si.sound.namespaces._sound_object_internal;
    import org.si.sound.synthesizers.DrumMachinePresetVoice;
    import org.si.sound.patterns.DrumMachinePresetPattern;
    import org.si.sound.patterns.Sequencer;
    
    
    /** Drum machinie provides independent bass drum, snare drum and hihat symbals tracks. */
    public class DrumMachine extends MultiTrackSoundObject
    {
    // namespace
    //----------------------------------------
        use namespace _sound_object_internal;
        
        
        
        
    // static variables
    //----------------------------------------
        static private var _presetVoice:DrumMachinePresetVoice = null;
        static private var _presetPattern:DrumMachinePresetPattern = null;
        
        
        
        
    // variables
    //----------------------------------------
        /** @private [protected] bass drum pattern sequencer */
        protected var _bass:Sequencer;
        /** @private [protected] snare drum pattern sequencer */
        protected var _snare:Sequencer;
        /** @private [protected] hi-hat cymbal pattern sequencer */
        protected var _hihat:Sequencer;
        
        /** @private [protected] Sequence data */
        protected var _data:SiONData;
        
        // preset pattern list
        static private var bassPatternList:Array;
        static private var snarePatternList:Array;
        static private var hihatPatternList:Array;
        static private var percusPatternList:Array;
        static private var bassVoiceList:Array;
        static private var snareVoiceList:Array;
        static private var hihatVoiceList:Array;
        static private var percusVoiceList:Array;
        
        
        
    // properties
    //----------------------------------------
        /** Preset voices */
        public function get presetVoice() : DrumMachinePresetVoice { return _presetVoice; }
        
        /** Preset patterns */
        public function get presetPattern() : DrumMachinePresetPattern { return _presetPattern; }
        
        /** maximum value of basePatternNumber */  public function get bassPatternNumberMax()  : int { return bassPatternList.length; }
        /** maximum value of snarePatternNumber */ public function get snarePatternNumberMax() : int { return snarePatternList.length; }
        /** maximum value of hihatPatternNumber */ public function get hihatPatternNumberMax() : int { return hihatPatternList.length; }
        /** maximum value of baseVoiceNumber */    public function get bassVoiceNumberMax()  : int { return bassVoiceList.length>>1; }
        /** maximum value of snareVoiceNumber */   public function get snareVoiceNumberMax() : int { return snareVoiceList.length>>1; }
        /** maximum value of hihatVoiceNumber */   public function get hihatVoiceNumberMax() : int { return hihatVoiceList.length>>1; }
        
        
        /** Sequencer object of bass drum */
        public function get bass()  : Sequencer { return _bass; }
        /** Sequencer object of snare drum */
        public function get snare() : Sequencer { return _snare; }
        /** Sequencer object of hihat symbal */
        public function get hihat() : Sequencer { return _hihat; }
        
        
        /** bass drum pattern number, -1 sets no patterns. */
        public function set bassPatternNumber(index:int) : void {
            if (index < -1 || index >= bassPatternList.length) return;
            bass.pattern = (index != -1) ? bassPatternList[index] : null;
        }
        
        
        /** snare drum pattern number, -1 sets no patterns. */
        public function set snarePatternNumber(index:int) : void {
            if (index < -1 || index >= snarePatternList.length) return;
            snare.pattern = (index != -1) ? snarePatternList[index] : null;
        }
        
        
        /** hi-hat cymbal pattern number, -1 sets no patterns. */
        public function set hihatPatternNumber(index:int) : void {
            if (index < -1 || index >= hihatPatternList.length) return;
            hihat.pattern = (index != -1) ? hihatPatternList[index] : null;
        }
        
        
        /** bass drum pattern number. */
        public function set bassVoiceNumber(index:int) : void {
            index <<= 1;
            if (index < 0 || index >= bassVoiceList.length) return;
            bass.voiceList = [bassVoiceList[index], bassVoiceList[index+1]];
        }
        
        
        /** snare drum pattern number. */
        public function set snareVoiceNumber(index:int) : void {
            index <<= 1;
            if (index < 0 || index >= snareVoiceList.length) return;
            snare.voiceList = [snareVoiceList[index], snareVoiceList[index+1]];
        }
        
        
        /** hi-hat cymbal pattern number. */
        public function set hihatVoiceNumber(index:int) : void {
            index <<= 1;
            if (index < 0 || index >= hihatVoiceList.length) return;
            hihat.voiceList = [hihatVoiceList[index], hihatVoiceList[index+1]];
        }
        
        
        
        
    // constructor
    //----------------------------------------
        /** constructor 
         *  @param bassPatternNumber bass drum pattern number
         *  @param snarePatternNumber snare drum pattern number
         *  @param hihatPatternNumber hihat symbal pattern number
         *  @param bassVoiceNumber bass drum voice number
         *  @param snareVoiceNumber snare drum voice number
         *  @param hihatVoiceNumber hihat symbal voice number
         */
        function DrumMachine(bassPatternNumber:int=0, snarePatternNumber:int=8, hihatPatternNumber:int=0, bassVoiceNumber:int=0, snareVoiceNumber:int=0, hihatVoiceNumber:int=0)
        {
            if (_presetVoice == null) {
                _presetVoice = new DrumMachinePresetVoice();
                _presetPattern = new DrumMachinePresetPattern();
                bassPatternList   = _presetPattern["bass"];
                snarePatternList  = _presetPattern["snare"];
                hihatPatternList  = _presetPattern["hihat"];
                percusPatternList = _presetPattern["percus"];
                bassVoiceList   = _presetVoice["bass"];
                snareVoiceList  = _presetVoice["snare"];
                hihatVoiceList  = _presetVoice["hihat"];
                percusVoiceList = _presetVoice["percus"];
            }
            
            super("DrumMachine");
            
            _data = new SiONData();
            _bass   = new Sequencer(this, _data, 36, 192, 1);
            _snare  = new Sequencer(this, _data, 68, 128, 1);
            _hihat  = new Sequencer(this, _data, 68, 64,  1);
            this.bassVoiceNumber = bassVoiceNumber;
            this.snareVoiceNumber = snareVoiceNumber;
            this.hihatVoiceNumber = hihatVoiceNumber;
            
            setPatternNumbers(bassPatternNumber, snarePatternNumber, hihatPatternNumber);
        }
        
        
        
        
    // operation
    //----------------------------------------
        /** play drum sequence */
        override public function play() : void
        {
            stop();
            _tracks = _sequenceOn(_data, false, false);
            if (_tracks && _tracks.length == 3) {
                _synthesizer._registerTracks(_tracks);
                _bass.play(_tracks[0]);
                _snare.play(_tracks[1]);
                _hihat.play(_tracks[2]);
            }
        }
        
        
        /** stop sequence */
        override public function stop() : void
        {
            if (_tracks) {
                _bass.stop();
                _snare.stop();
                _hihat.stop();
                _synthesizer._unregisterTracks(_tracks[0], _tracks.length);
                for each (var t:SiMMLTrack in _tracks) t.setDisposable();
                _tracks = null;
                _sequenceOff(false);
            }
            _stopEffect();
        }
        
        
        
        
    // configure
    //----------------------------------------
        /** Set all pattern indeces 
         *  @param bassPatternNumber bass drum pattern index
         *  @param snarePatternNumber snare drum pattern index
         *  @param hihatPatternNumber hihat symbal pattern index
         */
        public function setPatternNumbers(bassPatternNumber:int, snarePatternNumber:int, hihatPatternNumber:int) : DrumMachine
        {
            this.bassPatternNumber  = bassPatternNumber;
            this.snarePatternNumber = snarePatternNumber;
            this.hihatPatternNumber = hihatPatternNumber;
            return this;
        }
    }
}

