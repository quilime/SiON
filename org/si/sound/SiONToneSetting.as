//----------------------------------------------------------------------------------------------------
// tone setting
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------




package org.si.sound {
    import org.si.sound.mml.SiMMLTrack;
    import org.si.sound.mml.SiMMLEnvelopTable;
    import org.si.sound.module.SiOPMChannelParam;
    
    
    /** Tone setting.
     *  @see org.si.sound.module.SiOPMChannelParam
     *  @see org.si.sound.module.SiOPMOperatorParam
     */
    public class SiONToneSetting
    {
        /** module type. 1st argument of '%'. @default 0 */
        public var moduleType:int;
        /** channel number. 2nd argument of '%'. @default 0 */
        public var channelNum:int;
        /** tone number. 1st argument of '&#64;'. -1;do nothing. @default -1 */
        public var toneNum:int;
        /** parameters for FM sound channel. null;do nothing. @default null */
        public var channelParam:SiOPMChannelParam;
        
        
        /** portament. [NOT IMPLEMENTED]. @default 0 */
        public var portament:int;
        /** release sweep. 2nd argument of '&#64;rr' and 's'. @default 0 */
        public var releaseSweep:int;
        
        
        /** amplitude modulation depth. 1st argument of 'ma'. @default 0 */
        public var amDepth:int;
        /** amplitude modulation depth after changing. 2nd argument of 'ma'. @default 0 */
        public var amDepthEnd:int;
        /** amplitude modulation changing delay. 3rd argument of 'ma'. @default 0 */
        public var amDelay:int;
        /** amplitude modulation changing term. 4th argument of 'ma'. @default 0 */
        public var amTerm:int;
        /** pitch modulation depth. 1st argument of 'mp'. @default 0 */
        public var pmDepth:int;
        /** pitch modulation depth after changing. 2nd argument of 'mp'. @default 0 */
        public var pmDepthEnd:int;
        /** pitch modulation changing delay. 3rd argument of 'mp'. @default 0 */
        public var pmDelay:int;
        /** pitch modulation changing term. 4th argument of 'mp'. @default 0 */
        public var pmTerm:int;
        
        
        /** note on tone envelop table. 1st argument of '&#64;&#64;' @default null */
        public var noteOnToneEnvelop:SiMMLEnvelopTable;
        /** note on amplitude envelop table. 1st argument of 'na' @default null */
        public var noteOnAmplitudeEnvelop:SiMMLEnvelopTable;
        /** note on filter envelop table. 1st argument of 'nf' @default null */
        public var noteOnFilterEnvelop:SiMMLEnvelopTable;
        /** note on pitch envelop table. 1st argument of 'np' @default null */
        public var noteOnPitchEnvelop:SiMMLEnvelopTable;
        /** note on note envelop table. 1st argument of 'nt' @default null */
        public var noteOnNoteEnvelop:SiMMLEnvelopTable;
        /** note off tone envelop table. 1st argument of '_&#64;&#64;' @default null */
        public var noteOffToneEnvelop:SiMMLEnvelopTable;
        /** note off amplitude envelop table. 1st argument of '_na' @default null */
        public var noteOffAmplitudeEnvelop:SiMMLEnvelopTable;
        /** note off filter envelop table. 1st argument of '_nf' @default null */
        public var noteOffFilterEnvelop:SiMMLEnvelopTable;
        /** note off pitch envelop table. 1st argument of '_np' @default null */
        public var noteOffPitchEnvelop:SiMMLEnvelopTable;
        /** note off note envelop table. 1st argument of '_nt' @default null */
        public var noteOffNoteEnvelop:SiMMLEnvelopTable;
        
        
        /** note on tone envelop tablestep. 2nd argument of '&#64;&#64;' @default 1 */
        public var noteOnToneEnvelopStep:int;
        /** note on amplitude envelop tablestep. 2nd argument of 'na' @default 1 */
        public var noteOnAmplitudeEnvelopStep:int;
        /** note on filter envelop tablestep. 2nd argument of 'nf' @default 1 */
        public var noteOnFilterEnvelopStep:int;
        /** note on pitch envelop tablestep. 2nd argument of 'np' @default 1 */
        public var noteOnPitchEnvelopStep:int;
        /** note on note envelop tablestep. 2nd argument of 'nt' @default 1 */
        public var noteOnNoteEnvelopStep:int;
        /** note off tone envelop tablestep. 2nd argument of '_&#64;&#64;' @default 1 */
        public var noteOffToneEnvelopStep:int;
        /** note off amplitude envelop tablestep. 2nd argument of '_na' @default 1 */
        public var noteOffAmplitudeEnvelopStep:int;
        /** note off filter envelop tablestep. 2nd argument of '_nf' @default 1 */
        public var noteOffFilterEnvelopStep:int;
        /** note off pitch envelop tablestep. 2nd argument of '_np' @default 1 */
        public var noteOffPitchEnvelopStep:int;
        /** note off note envelop tablestep. 2nd argument of '_nt' @default 1 */
        public var noteOffNoteEnvelopStep:int;
        
        
        
        
        /** constructor */
        function SiONToneSetting()
        {
            moduleType = 0;
            channelNum = 0;
            toneNum = -1;
            
            channelParam = null;
            
            portament = 0;
            
            amDepth = 0;
            amDepthEnd = 0;
            amDelay = 0;
            amTerm = 0;
            pmDepth = 0;
            pmDepthEnd = 0;
            pmDelay = 0;
            pmTerm = 0;

            noteOnToneEnvelop = null;
            noteOnAmplitudeEnvelop = null;
            noteOnFilterEnvelop = null;
            noteOnPitchEnvelop = null;
            noteOnNoteEnvelop = null;
            noteOffToneEnvelop = null;
            noteOffAmplitudeEnvelop = null;
            noteOffFilterEnvelop = null;
            noteOffPitchEnvelop = null;
            noteOffNoteEnvelop = null;
            
            noteOnToneEnvelopStep = 1;
            noteOnAmplitudeEnvelopStep = 1;
            noteOnFilterEnvelopStep = 1;
            noteOnPitchEnvelopStep = 1;
            noteOnNoteEnvelopStep = 1;
            noteOffToneEnvelopStep = 1;
            noteOffAmplitudeEnvelopStep = 1;
            noteOffFilterEnvelopStep = 1;
            noteOffPitchEnvelopStep = 1;
            noteOffNoteEnvelopStep = 1;
        }
        
        
        /** set sequencer track */
        public function setTrackTone(track:SiMMLTrack, withVolume:Boolean=false) : SiMMLTrack
        {
            if (channelParam) {
                track.setChannelModuleType(6, 0);
                track.channel.setSiOPMChannelParam(channelParam, withVolume);
            } else {
                track.setChannelModuleType(moduleType, channelNum, toneNum);
            }
            track.setPortament(portament);
            track.setReleaseSweep(releaseSweep);
            track.setModulationEnvelop(false, amDepth, amDepthEnd, amDelay, amTerm);
            track.setModulationEnvelop(true,  pmDepth, pmDepthEnd, pmDelay, pmTerm);
            if (noteOnToneEnvelop != null) track.setToneEnvelop(1, noteOnToneEnvelop, noteOnToneEnvelopStep);
            if (noteOnAmplitudeEnvelop != null) track.setAmplitudeEnvelop(1, noteOnAmplitudeEnvelop, noteOnAmplitudeEnvelopStep);
            if (noteOnFilterEnvelop != null) track.setFilterEnvelop(1, noteOnFilterEnvelop, noteOnFilterEnvelopStep);
            if (noteOnPitchEnvelop != null) track.setPitchEnvelop(1, noteOnPitchEnvelop, noteOnPitchEnvelopStep);
            if (noteOnNoteEnvelop != null) track.setNoteEnvelop(1, noteOnNoteEnvelop, noteOnNoteEnvelopStep);
            if (noteOffToneEnvelop != null) track.setToneEnvelop(0, noteOffToneEnvelop, noteOffToneEnvelopStep);
            if (noteOffAmplitudeEnvelop != null) track.setAmplitudeEnvelop(0, noteOffAmplitudeEnvelop, noteOffAmplitudeEnvelopStep);
            if (noteOffFilterEnvelop != null) track.setFilterEnvelop(0, noteOffFilterEnvelop, noteOffFilterEnvelopStep);
            if (noteOffPitchEnvelop != null) track.setPitchEnvelop(0, noteOffPitchEnvelop, noteOffPitchEnvelopStep);
            if (noteOffNoteEnvelop != null) track.setNoteEnvelop(0, noteOffNoteEnvelop, noteOffNoteEnvelopStep);
            return track;
        }
    }
}


