//----------------------------------------------------------------------------------------------------
// class for SiMML sequencer setting
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.sequencer {
    import org.si.sion.sequencer.base.MMLSequence;
    import org.si.sion.module.SiOPMModule;
    import org.si.sion.module.SiOPMTable;
    import org.si.sion.module.SiOPMChannelBase;
    import org.si.sion.module.SiOPMChannelParam;
    import org.si.sion.module.SiOPMChannelManager;

    
    /** @private SiOPM channel setting */
    public class SiMMLChannelSetting
    {
    // constants
    //--------------------------------------------------
        static public const SELECT_TONE_NOP   :int = 0;
        static public const SELECT_TONE_NORMAL:int = 1;
        static public const SELECT_TONE_FM    :int = 2;
        
        
        
        
    // variables
    //--------------------------------------------------
        public   var type:int;
        internal var _selectToneType:int;
        internal var _pgTypeList:Vector.<int>;
        internal var _ptTypeList:Vector.<int>;
        internal var _initIndex:int;
        internal var _channelTone:Vector.<int>;
        internal var _channelType:int;
        
        
        
        
    // constructor
    //--------------------------------------------------
        function SiMMLChannelSetting(type:int, offset:int, length:int, step:int, channelCount:int)
        {
            var i:int, idx:int;
            _pgTypeList = new Vector.<int>(length, true);
            _ptTypeList = new Vector.<int>(length, true);
            for (i=0, idx=offset; i<length; i++, idx+=step) {
                _pgTypeList[i] = idx;
                _ptTypeList[i] = SiOPMTable.instance.getWaveTable(idx).defaultPTType;
            }
            _channelTone = new Vector.<int>(channelCount, true);
            for (i=0; i<channelCount; i++) { _channelTone[i] = i; }
            
            this._initIndex = 0;
            this.type = type;
            _channelType = SiOPMChannelManager.CT_CHANNEL_FM;
            _selectToneType = SELECT_TONE_NORMAL;
        }
        
        
        
        
    // tone setting
    //--------------------------------------------------
        /** initialize tone by channel number. */
        public function initializeTone(track:SiMMLTrack, chNum:int, bufferIndex:int) : int
        {
            if (track.channel == null) {
                // create new channel
                track.channel = SiOPMChannelManager.newChannel(_channelType, null, bufferIndex);
            } else 
            if (track.channel.channelType != _channelType) {
                // change channel type
                var prev:SiOPMChannelBase = track.channel;
                track.channel = SiOPMChannelManager.newChannel(_channelType, prev, bufferIndex);
                SiOPMChannelManager.deleteChannel(prev);
            }

            // initialize
            var channelTone:int = _initIndex;
            if (chNum>=0 && chNum<_channelTone.length) channelTone = _channelTone[chNum];
            track.channelNumber = (chNum<0) ? 0 : chNum;
            track.channel.setAlgorism(1, 0);
            track.channel.setType(_pgTypeList[channelTone], _ptTypeList[channelTone]);
            return (chNum == -1) ? -1 : channelTone;
        }
        
        
        /** select tone by tone number. */
        public function selectTone(track:SiMMLTrack, voiceIndex:int) : MMLSequence
        {
            if (voiceIndex == -1) return null;
            
            var voice:SiMMLVoice, param:SiOPMChannelParam=null;
            
            switch (_selectToneType) {
            case SELECT_TONE_NORMAL:
                if (voiceIndex <0 || voiceIndex >=_pgTypeList.length) voiceIndex = _initIndex;
                track.channel.setType(_pgTypeList[voiceIndex], _ptTypeList[voiceIndex]);
                break;
            case SELECT_TONE_FM:
                voiceIndex += track.channelNumber << 8;
                if (voiceIndex<0 || voiceIndex>=SiMMLTable.VOICE_MAX) voiceIndex=0;
                voice = SiMMLTable.instance.getSiMMLVoice(voiceIndex);
                if (voice) {
                    param = voice.channelParam;
                    if (param) {
                        track.channel.setSiOPMChannelParam(param, false);
                    } else { // set module type and channel number
                        track.setChannelModuleType(voice.moduleType, voice.channelNum, voice.toneNum);
                        track.channel.setAllAttackRate(voice.attackRate);
                        track.channel.setAllReleaseRate(voice.releaseRate);
                        track.pitchShift = voice.detune;
                    }
                    /* // comment out not to set these parameters
                    track.setPortament(voice.portament);
                    track.setReleaseSweep(voice.releaseSweep);
                    track.setModulationEnvelop(false, voice.amDepth, voice.amDepthEnd, voice.amDelay, voice.amTerm);
                    track.setModulationEnvelop(true,  voice.pmDepth, voice.pmDepthEnd, voice.pmDelay, voice.pmTerm);
                    */
                }
                return (param==null || param.initSequence.isEmpty()) ? null : param.initSequence;
            default:
                break;
            }
            return null;
        }
    }
}
