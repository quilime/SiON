//----------------------------------------------------------------------------------------------------
// SiOPM channel parameters
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------




package org.si.sound.module {
    import org.si.sound.mml.MMLSequence;
    
    
    /** SiOPM Parameters */
    public class SiOPMChannelParam
    {
    // valiables 11 parameters
    //--------------------------------------------------
        /** operator params x4 */
        public var opeParam:Vector.<SiOPMOperatorParam>;
        
        /** operator count [0,4] */
        public var opeCount:int;
        /** algorism [0,] */
        public var alg:int;
        /** feedback [0,7] */
        public var fb:int;
        /** feedback connection [0,3] */
        public var fbc:int;
        /** envelop frequency ratio */
        public var fratio:int;
        /** LFO wave shape */
        public var lfoWaveShape:int;
        /** LFO frequency */
        public var lfoFreqStep:int;
        
        /** amplitude modulation depth */
        public var amd:int;
        /** pitch modulation depth */
        public var pmd:int;
        /** [extention] left volume */
        public var leftVolume:int;
        /** [extention] right volume */
        public var rightVolume:int;
        
        /** Initializing sequence */
        public var initSequence:MMLSequence;
        
        
        function SiOPMChannelParam()
        {
            initSequence = new MMLSequence();
            initialize();

            opeParam = new Vector.<SiOPMOperatorParam>(4, true);
            for (var i:int; i<4; i++) {
                opeParam[i] = new SiOPMOperatorParam();
            }
        }
        
        
        public function initialize() : SiOPMChannelParam
        {
            // 0 = no setting on each operator
            opeCount = 0;
            
            alg = 0;
            fb = 0;
            fbc = 0;
            lfoWaveShape = SiOPMTable.LFO_WAVE_TRIANGLE;
            lfoFreqStep = 12126;    // 12126 = 30frame/100fratio
            amd = 0;
            pmd = 0;
            fratio = 100;
            leftVolume  = 0.25;
            rightVolume = 0.25;
            
            if (opeParam) {
                for (var i:int; i<4; i++) { opeParam[i].initialize(); }
            }
            
            initSequence.free();
            
            return this;
        }
        
        
        public function toString() : String
        {
            var str:String = "SiOPMChannelParam : opeCount=";
            str += String(opeCount) + "\n";
            $("freq.ratio", fratio);
            $("alg", alg);
            $2("fb ", fb,  "fbc", fbc);
            $2("lws", lfoWaveShape, "lfq", SiOPMTable.LFO_TIMER_INITIAL*0.005782313/lfoFreqStep);
            $2("amd", amd, "pmd", pmd);
            $2("lvol", leftVolume,  "rvol", rightVolume);
            for (var i:int=0; i<opeCount; i++) {
                str += opeParam[i].toString() + "\n";
            }
            return str;
            function $ (p:String, i:int) : void { str += "  " + p + "=" + String(i) + "\n"; }
            function $2(p:String, i:int, q:String, j:int) : void { str += "  " + p + "=" + String(i) + " / " + q + "=" + String(j) + "\n"; }
        }
    }
}

