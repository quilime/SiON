//----------------------------------------------------------------------------------------------------
// Class for sound object playing MML
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound.base {
    import org.si.sion.*;
    import org.si.sion.sequencer.SiMMLTrack;
    import org.si.sion.sequencer.SiMMLSequencer;
    import org.si.sion.sequencer.base.MMLSequence;
    import org.si.sound.synthesizers._synthesizer_internal;
    
    
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
        override public function set coarseTune(n:int) : void {
            super.coarseTune = n;
            if (_tracks) {
                var i:int, f:uint, imax:int = _tracks.length;
                for (i=0, f=_trackFilter; i<imax; i++, f>>=1) {
                    if (f&1) _tracks[i].noteShift = _noteShift;
                }
            }
        }
        
        /** @private */
        override public function set fineTune(p:Number) : void {
            super.fineTune = p;
            if (_tracks) {
                var i:int, f:uint, imax:int = _tracks.length, ps:int = _pitchShift*64;
                for (i=0, f=_trackFilter; i<imax; i++, f>>=1) {
                    if (f&1) _tracks[i].pitchShift = ps;
                }
            }
        }
        
        /** @private */
        override public function set gateTime(g:Number) : void {
            super.gateTime = g;
            if (_tracks) {
                var i:int, f:uint, imax:int = _tracks.length;
                for (i=0, f=_trackFilter; i<imax; i++, f>>=1) {
                    if (f&1) _tracks[i].quantRatio = _gateTime;
                }
            }
        }
        
        /** @private */
        override public function set eventMask(m:int) : void {
            super.eventMask = m;
            if (_tracks) {
                var i:int, f:uint, imax:int = _tracks.length;
                for (i=0, f=_trackFilter; i<imax; i++, f>>=1) {
                    if (f&1) _tracks[i].eventMask = _eventMask;
                }
            }
        }
        
        /** @private */
        override public function set mute(m:Boolean) : void { 
            super.mute = m;
            if (_tracks) {
                var i:int, f:uint, imax:int = _tracks.length;
                for (i=0, f=_trackFilter; i<imax; i++, f>>=1) {
                    if (f&1) _tracks[i].channel.mute = _mute;
                }
            }
        }
        
        /** @private */
        override public function set volume(v:Number) : void {
            super.volume = v;
            if (_tracks) {
                var i:int, f:uint, imax:int = _tracks.length;
                for (i=0, f=_trackFilter; i<imax; i++, f>>=1) {
                    if (f&1) _tracks[i].channel.masterVolume = _volumes[0];
                }
            }
        }
        
        /** @private */
        override public function set pan(p:Number) : void {
            super.pan = p;
            if (_tracks) {
                var i:int, f:uint, imax:int = _tracks.length;
                for (i=0, f=_trackFilter; i<imax; i++, f>>=1) {
                    if (f&1) _tracks[i].channel.pan = _pan;
                }
            }
        }
        
        /** @private */
        override public function set effectSend1(v:Number) : void {
            super.effectSend1 = v;
            v = _volumes[1] * 0.0078125;
            if (_tracks) {
                var i:int, f:uint, imax:int = _tracks.length;
                for (i=0, f=_trackFilter; i<imax; i++, f>>=1) {
                    if (f&1) _tracks[i].channel.setStreamSend(1, v);
                }
            }
        }
        
        /** @private */
        override public function set effectSend2(v:Number) : void {
            super.effectSend2 = v;
            v = _volumes[2] * 0.0078125;
            if (_tracks) {
                var i:int, f:uint, imax:int = _tracks.length;
                for (i=0, f=_trackFilter; i<imax; i++, f>>=1) {
                    if (f&1) _tracks[i].channel.setStreamSend(2, v);
                }
            }
        }
        
        /** @private */
        override public function set effectSend3(v:Number) : void {
            super.effectSend3 = v;
            v = _volumes[3] * 0.0078125;
            if (_tracks) {
                var i:int, f:uint, imax:int = _tracks.length;
                for (i=0, f=_trackFilter; i<imax; i++, f>>=1) {
                    if (f&1) _tracks[i].channel.setStreamSend(3, v);
                }
            }
        }
        
        /** @private */
        override public function set effectSend4(v:Number) : void {
            super.effectSend4 = v;
            v = _volumes[4] * 0.0078125;
            if (_tracks) {
                var i:int, f:uint, imax:int = _tracks.length;
                for (i=0, f=_trackFilter; i<imax; i++, f>>=1) {
                    if (f&1) _tracks[i].channel.setStreamSend(4, v);
                }
            }
        }
        
        /** @private */
        override public function set pitchBend(p:Number) : void {
            super.pitchBend = p;
            if (_tracks) {
                var i:int, f:uint, pb:int = p*64, imax:int = _tracks.length;
                for (i=0, f=_trackFilter; i<imax; i++, f>>=1) {
                    if (f&1) _tracks[i].pitchBend = pb;
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
        /** Reset */
        override public function reset() : void 
        {
        }
        
        
        /** Play sound. */
        override public function play() : void { 
            _compile();
            stop();
            _tracks = _sequenceOn(_data, false);
            if (_tracks) _synthesizer._registerTracks(_tracks);
        }
        
        
        /** Stop sound. */
        override public function stop() : void {
            if (_tracks) {
                _synthesizer._unregisterTracks(_tracks[0], _tracks.length);
                for each (var t:SiMMLTrack in _tracks) t.setDisposable();
                _tracks = null;
                _sequenceOff(false);
            }
        }
        
        
        
        
    // internal
    //----------------------------------------
        /** call this after the update mml */
        protected function _compile() : void {
            if (!driver || _compiled) return;
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

