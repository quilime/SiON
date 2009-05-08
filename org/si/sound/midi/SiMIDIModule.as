//----------------------------------------------------------------------------------------------------
// MIDI module
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------




package org.si.sound.midi {
    import org.si.sound.*;
    import org.si.sound.mml.SiMMLSequencer;
    import org.si.sound.mml.SiMMLTrack;
    
    

    
    /** MIDI module (still in concept) */
    public class SiMIDIModule
    {
    // constants
    //--------------------------------------------------
        /** Tone setting size. 1024 = 128tones x 8banks. */
        static public const TONE_SETTING_SIZE:int = 1024;
        /** Track size. 16tracks x 4banks. */
        static public const TRACK_SIZE:int = 64;
        
        
        
        
    // valiables
    //--------------------------------------------------
        /** MIDI tracks */
        public var tracks:Vector.<SiMIDITrack>;
        
        // tone settings
        private var _toneSettings:Vector.<SiONToneSetting>;
        
        // sequencer instance
        private var _sequencer:SiMMLSequencer;
        
        
        
        
    // constructor
    //--------------------------------------------------
        /** Create new MIDI module. */
        function SiMIDIModule(sequencer:SiMMLSequencer)
        {
            var i:int;
            
            _sequencer = sequencer;
            
            _toneSettings = new Vector.<SiONToneSetting>(TONE_SETTING_SIZE);
            for (i=0; i<TONE_SETTING_SIZE; i++) _toneSettings[i] = null;
            tracks = new Vector.<SiMIDITrack>(TRACK_SIZE);
            for (i=0; i<TRACK_SIZE; i++) tracks[i] = new SiMIDITrack(this, i);
        }
        
        
        /** register tone setting. */
        public function registerToneSetting(toneNumber:int, toneSetting:SiONToneSetting) : void
        {
            if (toneNumber<0 || toneNumber>=TONE_SETTING_SIZE) return;
            _toneSettings[toneNumber] = toneSetting;
        }
        
        
        /** Note on. This function only is available after play().
         *  @param trackNumber track number [0-63].
         *  @param note note number [0-127].
         *  @return The SiMMLTrack switched key on. Returns null when tracks are overflowed.
         */
        public function noteOn(trackNumber:int, note:int) : SiMMLTrack
        {
            var trackID:int = (trackNumber & SiMMLTrack.TRACK_ID_FILTER) | SiMMLTrack.MIDI_TRACK_ID_OFFSET,
                midiTrack:SiMIDITrack = tracks[trackNumber],
                seqTrack:SiMMLTrack = _sequencer.getFreeControlableTrack(trackID) || _sequencer.newControlableTrack(trackID);
            if (seqTrack) {
                var setting:SiONToneSetting = _toneSettings[midiTrack.programNumber];
                if (setting) setting.setTrackTone(seqTrack);
                seqTrack.setEventTrigger(midiTrack.eventTriggerID, midiTrack.noteOnTrigger, midiTrack.noteOffTrigger);
                seqTrack.keyOn(note);
            }
            return seqTrack;
        }
        
        
        /** Note off. This function only is available after play(). 
         *  @param trackNumber track number [0-63].
         *  @param note note number [0-127].
         *  @return The SiMMLTrack switched key off. Returns null when tracks are overflowed.
         */
        public function noteOff(trackNumber:int, note:int) : SiMMLTrack
        {
            var trackID:int = (trackNumber & SiMMLTrack.TRACK_ID_FILTER) | SiMMLTrack.MIDI_TRACK_ID_OFFSET,
                midiTrack:SiMIDITrack = tracks[trackNumber],
                seqTrack:SiMMLTrack = _sequencer.findControlableTrack(trackID, note);
            if (seqTrack) seqTrack.keyOff();
            return seqTrack;
        }
        
        
        /** program change.
         *  @param trackNumber track number [0-63].
         *  @param programNumber program number [0-127].
         *  @return MIDI Track instance.
         */
        public function programChenge(trackNumber:int, programNumber:int) : SiMIDITrack
        {
            var midiTrack:SiMIDITrack = tracks[trackNumber];
            midiTrack.programNumber = programNumber;
            return midiTrack;
        }
        
        
        /** volume.
         *  @param trackNumber track number [0-63].
         *  @param volume volume [0-128].
         *  @return MIDI Track instance.
         */
        public function volume(trackNumber:int, volume:int) : SiMIDITrack
        {
            var midiTrack:SiMIDITrack = tracks[trackNumber];
            midiTrack.volumes[0] = volume * 0.0078125;
            return midiTrack;
        }
    }
}


