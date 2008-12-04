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

        /** LP filter cutoff */
        public var cutoff:int;
        /** LP filter resonance */
        public var resonanse:int;
        /** LP filter attack rate */
        public var far:int;
        /** LP filter decay rate 1 */
        public var fdr1:int;
        /** LP filter decay rate 2 */
        public var fdr2:int;
        /** LP filter release rate */
        public var frr:int;
        /** LP filter decay offset 1 */
        public var fdc1:int;
        /** LP filter decay offset 2 */
        public var fdc2:int;
        /** LP filter sustain offset */
        public var fsc:int;
        /** LP filter release offset */
        public var frc:int;
        
        /** Initializing sequence */
        public var initSequence:MMLSequence;
        
        
        /** LFO cycle time */
        public function set lfoFrame(fps:int) : void
        {
            lfoFreqStep = SiOPMTable.LFO_TIMER_INITIAL/(fps*2.882352941176471);
        }
        
        public function get lfoFrame() : int
        {
            return int(SiOPMTable.LFO_TIMER_INITIAL * 0.346938775510204 / lfoFreqStep);
        }
        
        
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
            opeCount = 1;
            
            alg = 0;
            fb = 0;
            fbc = 0;
            lfoWaveShape = SiOPMTable.LFO_WAVE_TRIANGLE;
            lfoFreqStep = 12126;    // 12126 = 30frame/100fratio
            amd = 0;
            pmd = 0;
            fratio = 100;
            leftVolume  = 32;
            rightVolume = 32;
            
            cutoff = 128;
            resonanse = 0;
            far = 0;
            fdr1 = 0;
            fdr2 = 0;
            frr = 0;
            fdc1 = 128;
            fdc2 = 64;
            fsc = 32;
            frc = 128;
            
            if (opeParam) {
                for (var i:int; i<4; i++) { opeParam[i].initialize(); }
            }
            
            initSequence.free();
            
            return this;
        }
        
        
        public function copyFrom(org:SiOPMChannelParam) : SiOPMChannelParam
        {
            opeCount = org.opeCount;
            
            alg = org.alg;
            fb = org.fb;
            fbc = org.fbc;
            lfoWaveShape = org.lfoWaveShape;
            lfoFreqStep = org.lfoFreqStep;
            amd = org.amd;
            pmd = org.pmd;
            fratio = org.fratio;
            leftVolume = org.leftVolume;
            rightVolume = org.rightVolume;
            
            cutoff = org.cutoff;
            resonanse = org.resonanse;
            far = org.far;
            fdr1 = org.fdr1;
            fdr2 = org.fdr2;
            frr = org.frr;
            fdc1 = org.fdc1;
            fdc2 = org.fdc2;
            fsc = org.fsc;
            frc = org.frc;
            
            if (opeParam) {
                for (var i:int; i<4; i++) { opeParam[i].copyFrom(org.opeParam[i]); }
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
            $2("co", cutoff, "res", resonanse);
            str += "fenv=" + String(far) + "/" + String(fdr1) + "/"+ String(fdr2) + "/"+ String(frr) + "\n";
            str += "feco=" + String(fdc1) + "/"+ String(fdc2) + "/"+ String(fsc) + "/"+ String(frc) + "\n";
            for (var i:int=0; i<opeCount; i++) {
                str += opeParam[i].toString() + "\n";
            }
            return str;
            function $ (p:String, i:int) : void { str += "  " + p + "=" + String(i) + "\n"; }
            function $2(p:String, i:int, q:String, j:int) : void { str += "  " + p + "=" + String(i) + " / " + q + "=" + String(j) + "\n"; }
        }
    }
}

