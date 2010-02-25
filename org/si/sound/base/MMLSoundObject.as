//----------------------------------------------------------------------------------------------------
// Class for sound object playing MML
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound {
    import org.si.sion.*;
    import org.si.sound.base.*;
    import org.si.sion.sequencer.SiMMLTrack;
    import org.si.sion.sequencer.SiMMLSequencer;
    import org.si.sion.sequencer.base.MMLSequence;
    
    
    /** Sound object with plural tracks */
    public class MMLSoundObject extends SoundObject
    {
    // variables
    //----------------------------------------
        /** mml text. */
        protected var _mml:String;
        
        /** sequence data. */
        protected var _data:SiONData;

        /** flag that mml text is compiled to data */
        protected var _compiled:Boolean

        /** filter to control track */
        protected var _trackFilter:uint;
        
        
        
        
    // properties
    //----------------------------------------
        /** MML text */
        public function get mml() : String { return _mml; }
        public function set mml(str:String) : void {
            _mml = str || "";
            _compiled = false;
            _compile();
        }
        
        /** sequence data */
        public function get data() : SiONData { return _data; }
        
        /** @private */
        override public function get isPlaying() : Boolean { return (_tracks != null); }
        
        
        /** @private */
        override public function set channelMute(m:Boolean) : void { 
            super.channelMute = m;
            if (_tracks) {
                var i:int, f:uint, imax:int = _tracks.length;
                for (i=0, f=_trackFilter; i<imax; i++, f>>=1) {
                    if (f&1) _tracks[i].channel.mute = _totalMute;
                }
            }
        }
        
        /** @private */
        override public function set channelVolume(v:Number) : void {
            super.channelVolume = v;
            if (_tracks) {
                var i:int, f:uint, imax:int = _tracks.length;
                for (i=0, f=_trackFilter; i<imax; i++, f>>=1) {
                    if (f&1) _tracks[i].channel.masterVolume = _totalVolume*128;
                }
            }
        }
        
        /** @private */
        override public function set channelPan(p:Number) : void {
            super.channelPan = p;
            if (_tracks) {
                var i:int, f:uint, imax:int = _tracks.length;
                for (i=0, f=_trackFilter; i<imax; i++, f>>=1) {
                    if (f&1) _tracks[i].channel.pan = _totalPan;
                }
            }
        }
        
        /** @private */
        public function set channelEffectSend1(v:Number) : void {
            super.channelEffectSend1 = v;
            v = _volume[1] * 0.0078125;
            if (_tracks) {
                var i:int, f:uint, imax:int = _tracks.length;
                for (i=0, f=_trackFilter; i<imax; i++, f>>=1) {
                    if (f&1) _tracks[i].channel.setStreamSend(1, v);
                }
            }
        }
        
        /** @private */
        public function set channelEffectSend2(v:Number) : void {
            super.channelEffectSend2 = v;
            v = _volume[2] * 0.0078125;
            if (_tracks) {
                var i:int, f:uint, imax:int = _tracks.length;
                for (i=0, f=_trackFilter; i<imax; i++, f>>=1) {
                    if (f&1) _tracks[i].channel.setStreamSend(2, v);
                }
            }
        }
        
        /** @private */
        public function set channelEffectSend3(v:Number) : void {
            super.channelEffectSend3 = v;
            v = _volume[3] * 0.0078125;
            if (_tracks) {
                var i:int, f:uint, imax:int = _tracks.length;
                for (i=0, f=_trackFilter; i<imax; i++, f>>=1) {
                    if (f&1) _tracks[i].channel.setStreamSend(3, v);
                }
            }
        }
        
        /** @private */
        public function set channelEffectSend4(v:Number) : void {
            super.channelEffectSend4 = v;
            v = _volume[4] * 0.0078125;
            if (_tracks) {
                var i:int, f:uint, imax:int = _tracks.length;
                for (i=0, f=_trackFilter; i<imax; i++, f>>=1) {
                    if (f&1) _tracks[i].channel.setStreamSend(4, v);
                }
            }
        }
        
        /** @private */
        public function set channelPitchBend(p:Number) : void {
            super.channelPitchBend = p;
            if (_tracks) {
                var i:int, f:uint, pb:int = p*64, imax:int = _tracks.length;
                for (i=0, f=_trackFilter; i<imax; i++, f>>=1) {
                    if (f&1) _tracks[i].channel.pitchBend = pb;
                }
            }
        }
        
        
        
        
        
    // constructor
    //----------------------------------------
        /** constructor */
        function MMLSoundObject(mml:String=null) {
            _data = new SiONData();
            _tracks = null;
            _trackFilter = 0xffffffff;
            this.mml = mml;
            super(_data.title);
        }
        
        
        
        
    // operations
    //----------------------------------------
        /** Play sound. */
        override public function play() : void { 
            if (!_compiled) _compile();
            if (_tracks) {
                for each (var t:SiMMLTrack in _tracks) t.setDisposal();
                _tracks = null;
            }
            _tracks = _sequenceOn(_data, false);
        }
        
        
        /** Stop sound. */
        override public function stop() : void {
            if (_tracks) {
                for each (var t:SiMMLTrack in _tracks) t.setDisposal();
                _tracks = null;
            }
            _sequenceOff(false);
        }
        
        
        
        
    // internal
    //----------------------------------------
        /** call this after the update mml */
        protected function _compile() : void {
            if (!driver) return;
            if (_mml != "") {
                driver.compile(_mml, _data);
                name = _data.title;
            } else {
                _data.clear();
                name = "";
            }
            _compiled = true;
        }
    }
}

