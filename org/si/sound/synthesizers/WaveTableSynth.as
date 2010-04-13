// Wave Table Synthesizer 
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound.synthesizers {
    import org.si.sion.*;
    import org.si.sion.utils.SiONUtil;
    import org.si.sion.module.SiOPMWaveTable;
    import org.si.sion.module.channels.SiOPMChannelFM;
    import org.si.sion.sequencer.SiMMLTrack;
    import org.si.sound.SoundObject;
    
    
    /** Wave Table Synthesizer 
     */
    public class WaveTableSynth extends BasicSynth
    {
    // namespace
    //----------------------------------------
        use namespace _synthesizer_internal;
        
        
        
        
    // constants
    //----------------------------------------
        /** single layer mode */
        static public const SINGLE:String = "single";
        /** detuned layer mode with double operators */
        static public const DETUNE:String = "detune";
        /** detune layer mode with triple operators */
        static public const TRIPLE_DETUNE:String = "tripleDetune";
        /** detune layer mode with quadraple operators */
        static public const QUAD_DETUNE:String = "quadDetune";
        /** layered by closed sus4 code (3operators)*/
        static public const SUS4:String = "sus4";
        /** layered by closed sus47 code (4operators)*/
        static public const SUS47:String = "sus47";
        /** layered by closed major code (3operators)*/
        static public const MAJOR:String = "M";
        /** layered by closed minor code (3operators)*/
        static public const MINOR:String = "m";
        /** layered by closed 7th code (4operators)*/
        static public const SEVENTH:String = "7";
        /** layered by closed minor 7th code (4operators)*/
        static public const MINOR_SEVENTH:String = "m7";
        /** layered by closed major 7th code (4operators)*/
        static public const MAJOR_SEVENTH:String = "M7";
        /** layered by opened 7th code (4operators)*/
        static public const SEVENTH_OPENED:String = "7opened";
        /** layered by opened minor 7th code (4operators)*/
        static public const MINOR_SEVENTH_OPENED:String = "m7opened";
        /** layered by opened major 7th code (4operators)*/
        static public const MAJOR_SEVENTH_OPENED:String = "M7opened";
        
        /** operator settings */
        static protected var _operatorSetting:* = {
            SINGLE:[0], DETUNE:[0,0], TRIPLE_DETUNE:[0,0,0], QUAD_DETUNE:[0,0,0,0], 
            SUS4:[0,5,7], SUS47:[0,5,7,10], MAJOR:[0,4,7], MINOR:[0,3,7], 
            SEVENTH:[0,4,7,10], MINOR_SEVENTH:[0,3,7,10], MAJOR_SEVENTH:[0,4,7,11], 
            SEVENTH_OPENED:[0,7,10,16], MINOR_SEVENTH_OPENED:[0,7,10,15], MAJOR_SEVENTH_OPENED:[0,7,11,16]
        };
        
        
        
    // variables
    //----------------------------------------
        /** wavelet */
        protected var _wavelet:Vector.<Number>;
        /** wave table */
        protected var _waveTable:SiOPMWaveTable;
        /** wave color */
        protected var _waveColor:uint;
        /** layering type */
        protected var _layerType:String;
        /** layering type */
        protected var _operatorPitch:Array;
        /** layering detune */
        protected var _layerDetune:int;
        
        
        
        
    // properties
    //----------------------------------------
        /** wave color.  */
        public function get color() : uint { return _waveColor; }
        public function set color(c:uint) : void {
            _waveTable.wavelet = SiONUtil.logTransVector(SiONUtil.waveColor(c, 0, _wavelet), false, _waveTable.wavelet);
            var i:int, imax:int = _tracks.length, ch:SiOPMChannelFM;
            for (i=0; i<imax; i++) {
                ch = _tracks[i].channel as SiOPMChannelFM;
                if (ch != null) ch.setWaveData(_waveTable);
            }
        }
        
        
        /** layering type */
        public function get layerType() : String { return _layerType; }
        public function set layerType(t:String) : void {
            _operatorPitch = _operatorSetting[t];
            if (_operatorPitch == null) throw _errorNoLayerType(t);
            _layerType = t;
            var i:int, det:int, imax:int = _operatorPitch.length;
            _voice.channelParam.opeCount = imax;
            _voice.channelParam.alg = [0,1,5,7][imax];
            for (i=0, det=-((_layerDetune*(imax-1))>>1); i<imax; i++, det+=_layerDetune) {
                _voice.channelParam.operatorParam[i].detune = (_operatorPitch[i]<<6) + det;
            }
            _voiceUpdateNumber++;
        }
        
        
        /** layer detune, 1 = halftone */
        public function get layerDetune() : int { return _layerDetune; }
        public function set layerDetune(d:int) : void { 
            _layerDetune = d;
            var i:int, det:int, imax:int = _operatorPitch.length;
            for (i=0, det=-((_layerDetune*(imax-1))>>1); i<imax; i++, det+=_layerDetune) {
                _voice.channelParam.operatorParam[i].detune = (_operatorPitch[i]<<6) + det;
            }
            var ch:SiOPMChannelFM, op:int, opMax:int = _operatorPitch.length;
            imax = _tracks.length;
            for (i=0; i<imax; i++) {
                ch = _tracks[i].channel as SiOPMChannelFM;
                if (ch != null) {
                    for (op=0; op<opMax; op++) ch.operator[op].detune = _voice.channelParam.operatorParam[i].detune;
                }
            }
        }

        
        
        
    // constructor
    //----------------------------------------
        /** constructor */
        function WaveTableSynth(layerType:String="single", waveColor:uint=0x1000000f)
        {
            _wavelet = new Vector.<Number>();
            _waveTable = new SiOPMWaveTable();
            _voice.waveData = _waveTable;
            _layerDetune = 4;
            this.layerType = layerType;
            this.color = waveColor;
        }
        
        
        
        
    // errors
    //----------------------------------------
        // no layer type error
        private function _errorNoLayerType(type:String) : Error
        {
            return new Error("WaveTableSynth; no layer type '"+type+"'");
        }
    }
}


