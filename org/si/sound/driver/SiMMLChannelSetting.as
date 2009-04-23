//----------------------------------------------------------------------------------------------------
// class for SiMML sequencer setting
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------




package org.si.sound.driver {
    import org.si.sound.mml.MMLSequence;
    import org.si.sound.module.SiOPMModule;
    import org.si.sound.module.SiOPMTable;
    import org.si.sound.module.SiOPMChannelBase;
    import org.si.sound.module.SiOPMChannelParam;
    import org.si.sound.module.SiOPMChannelManager;

    
    /** SiOPM channel setting */
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
                _ptTypeList[i] = SiOPMTable.instance.defaultPTType[idx];
            }
            _channelTone = new Vector.<int>(channelCount, true);
            for (i=0; i<channelCount; i++) { _channelTone[i] = 0; }
            
            this._initIndex = 0;
            this.type = type;
            _channelType = SiOPMChannelManager.CT_CHANNEL_FM;
            _selectToneType = SELECT_TONE_NORMAL;
        }
        
        
        
        
    // tone setting
    //--------------------------------------------------
        /** initialize tone by channel number. */
        public function initializeTone(track:SiMMLSequencerTrack, chNum:int, bufferIndex:int) : int
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
            var channelTone:int = (chNum<0 || chNum>=_channelTone.length) ? _initIndex : _channelTone[chNum];
            track.channel.setType(_pgTypeList[channelTone], _ptTypeList[channelTone]);
            track.channel.setAlgorism(1, 0);
            return channelTone;
        }
        
        
        /** select tone by tone number. */
        public function selectTone(track:SiMMLSequencerTrack, toneIndex:int) : MMLSequence
        {
            var param:SiOPMChannelParam;
            
            switch (_selectToneType) {
            case SELECT_TONE_NORMAL:
                if (toneIndex <0 || toneIndex >=_pgTypeList.length) toneIndex = _initIndex;
                track.channel.setType(_pgTypeList[toneIndex], _ptTypeList[toneIndex]);
                break;
            case SELECT_TONE_FM:
                if (toneIndex<0 || toneIndex>=256) toneIndex=0;
                param = SiMMLTable.getSiOPMChannelParam(toneIndex);
                if (param) track.channel.setSiOPMChannelParam(param, false);
                return (param.initSequence.isEmpty()) ? null : param.initSequence;
            default:
                break;
            }
            return null;
        }
    }
}

