//----------------------------------------------------------------------------------------------------
// SiON Voice data
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion {
    import org.si.sion.utils.Translator;
    import org.si.sion.sequencer.SiMMLVoice;
    import org.si.sion.module.SiOPMChannelParam;
    
    
    /** SiON Voice data. This includes SiOPMChannelParam.
     *  @see org.si.sion.module.SiOPMChannelParam
     *  @see org.si.sion.module.SiOPMOperatorParam
     */
    public class SiONVoice extends SiMMLVoice
    {
    // variables
    //--------------------------------------------------
        /** voice name */
        public var name:String;
        
        
        
        
    // constrctor
    //--------------------------------------------------
        /** create new SiONVoice instance with '%' parameters, attack rate, release rate and detune.
         *  @param moduleType Module type. 1st argument of '%'.
         *  @param channelNum Channel number. 2nd argument of '%'.
         *  @param ar Attack rate (0-63). This parameter is available only when channelParam==null.
         *  @param rr Release rate (0-63). This parameter is available only when channelParam==null.
         *  @param dt Detune (64=1halftone). This parameter is available only when channelParam==null.
         */
        function SiONVoice(moduleType:int=0, channelNum:int=0, ar:int=63, rr:int=63, dt:int=0)
        {
            super();
            
            name = "";
            this.moduleType = moduleType;
            this.channelNum = channelNum;
            attackRate = ar;
            releaseRate = rr;
            detune = dt;
        }
        
        
        
        
    // parameter setting
    //--------------------------------------------------
        /** Set by #&#64; parameters Array */
        public function set param(args:Array) : void { channelParam = Translator.setParam(new SiOPMChannelParam(), args); }
        
        /** Set by #OPL&#64; parameters Array */
        public function set paramOPL(args:Array) : void { channelParam = Translator.setOPLParam(new SiOPMChannelParam(), args); }
        
        /** Set by #OPM&#64; parameters Array */
        public function set paramOPM(args:Array) : void { channelParam = Translator.setOPMParam(new SiOPMChannelParam(), args); }
        
        /** Set by #OPN&#64; parameters Array */
        public function set paramOPN(args:Array) : void { channelParam = Translator.setOPNParam(new SiOPMChannelParam(), args); }
        
        /** Set by #OPX&#64; parameters Array */
        public function set paramOPX(args:Array) : void { channelParam = Translator.setOPXParam(new SiOPMChannelParam(), args); }
        
        /** Set by #MA&#64; parameters Array */
        public function set paramMA3(args:Array) : void { channelParam = Translator.setMA3Param(new SiOPMChannelParam(), args); }
        
        /** Set phisical modeling synth guitar parameters.
         *  @param ar attack rate of plunk energy
         *  @param dr decay rate of plunk energy
         *  @param tl total level of plunk energy
         *  @param fixedPitch plunk noise pitch
         *  @param ws wave shape of plunk
         *  @param tension sustain rate of the tone
         */
        public function setPMSGuitar(ar:int=48, dr:int=48, tl:int=0, fixedPitch:int=0, ws:int=20, tension:int=8) : void {
            moduleType = 11;
            channelNum = 1;
            param = [1, 0, 0, ws, ar, dr, 0, 63, 15, tl, 0, 0, 1, 0, 0, 0, 0, fixedPitch];
            releaseRate = tension;
        }
        
        
        /** Set low pass filter parameters.
         *  @param ar attack rate of plunk energy
         *  @param dr decay rate of plunk energy
         *  @param tl total level of plunk energy
         *  @param fixedPitch plunk noise pitch
         *  @param ws wave shape of plunk
         *  @param tension sustain rate of the tone
         */
        public function setLPFilter() : void {
        }
    }
}


