//----------------------------------------------------------------------------------------------------
// tables for SiMML driver
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------




package org.si.sound.mml {
    import org.si.utils.SLLint;
    import org.si.sound.module.SiOPMTable;
    import org.si.sound.module.SiOPMChannelParam;
    import org.si.sound.module.SiOPMChannelManager;
    
    
    
    /** SiMML table */
    public class SiMMLTable
    {
    // constants
    //--------------------------------------------------
        // module types (0-9)
        static public const MT_PSG   :int = 0;  // PSG
        static public const MT_APU   :int = 1;  // FC pAPU
        static public const MT_NOISE :int = 2;  // noise wave
        static public const MT_MA3   :int = 3;  // MA3 wave form
        static public const MT_CUSTOM:int = 4;  // SCC / custom wave table
        static public const MT_ALL   :int = 5;  // all pgTypes
        static public const MT_FM    :int = 6;  // FM sound module
        static public const MT_PCM   :int = 7;  // PCM
        static public const MT_PULSE :int = 8;  // pulse wave
        static public const MT_RAMP  :int = 9;  // ramp wave
        static public const MT_SAMPLE:int = 10; // sampler
        static public const MT_MAX   :int = 11;
        
        static private const MT_ARRAY_SIZE:int = 11;
        
        static public const ENV_TABLE_MAX:int = 512;
        static public const FM_PARAM_MAX:int = 256;
        
        
        
    // valiables
    //--------------------------------------------------
        /** Envelop tables */
        public var envelopTables:Array = null;
        /** FM parameter settings */
        public var fmParameters:Array = null;

        /** module setting table */
        public var channelModuleSetting:Array = null;
        /** module setting table */
        public var effectModuleSetting:Array = null;
       
        
        /** table from tsscp @s commnd to OPM ar */
        public var tss_s2ar:Vector.<String> = null;
        /** table from tsscp @s commnd to OPM dr */
        public var tss_s2dr:Vector.<String> = null;
        /** table from tsscp @s commnd to OPM sr */
        public var tss_s2sr:Vector.<String> = null;
        /** table from tsscp s commnd to OPM rr */
        public var tss_s2rr:Vector.<String> = null;
        
        
        /** algorism table for OPM/OPN. */
        public var alg_opm:Array = [[ 0, 0, 0, 0, 0, 0, 0, 0,-1,-1,-1,-1,-1,-1,-1,-1],
                                    [ 0, 1, 1, 1, 1, 0, 1, 1,-1,-1,-1,-1,-1,-1,-1,-1],
                                    [ 0, 1, 2, 3, 3, 4, 3, 5,-1,-1,-1,-1,-1,-1,-1,-1],
                                    [ 0, 1, 2, 3, 4, 5, 6, 7,-1,-1,-1,-1,-1,-1,-1,-1]];
        /** algorism table for OPL3 */
        public var alg_opl:Array = [[ 0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1],
                                    [ 0, 1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1],
                                    [ 0, 3, 2, 2,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1],
                                    [ 0, 4, 8, 9,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1]];
        /** algorism table for MA3 */
        public var alg_ma3:Array = [[ 0, 0, 0, 0, 0, 0, 0, 0,-1,-1,-1,-1,-1,-1,-1,-1],
                                    [ 0, 1, 1, 1, 0, 1, 1, 1,-1,-1,-1,-1,-1,-1,-1,-1],
                                    [-1,-1, 5, 2, 0, 3, 2, 2,-1,-1,-1,-1,-1,-1,-1,-1],
                                    [-1,-1, 7, 2, 0, 4, 8, 9,-1,-1,-1,-1,-1,-1,-1,-1]];
        /** algorism table for OPX. LSB4 is the flag of feedback connection. */
        public var alg_opx:Array = [[ 0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1],
                                    [ 0,16, 1, 2,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1],
                                    [ 0,16, 1, 2, 3,19, 5, 6,-1,-1,-1,-1,-1,-1,-1,-1],
                                    [ 0,16, 1, 2, 3,19, 4,20, 8,11, 6,22, 5, 9,12, 7]];
        /** initial connection */
        public var alg_init:Array = [0,1,5,7];

        
        
        
    // static public instance
    //--------------------------------------------------
        /** static public instance */
        static public var instance:SiMMLTable = null;
        
        
        /** static initializer */
        static public function initialize() : void
        {
            if (instance == null) instance = new SiMMLTable();
        }
        
        
        
        
    // constructor
    //--------------------------------------------------
        /** constructor */
        function SiMMLTable()
        {
            var i:int;
            
            // Channel module setting
            var ms:SiMMLChannelSetting;
            channelModuleSetting = new Array(MT_ARRAY_SIZE);
            channelModuleSetting[MT_PSG]    = new SiMMLChannelSetting(MT_PSG,    SiOPMTable.PG_SQUARE,      3,   1, 4);   // PSG
            channelModuleSetting[MT_APU]    = new SiMMLChannelSetting(MT_APU,    SiOPMTable.PG_PULSE,       12,  2, 5);   // FC pAPU
            channelModuleSetting[MT_NOISE]  = new SiMMLChannelSetting(MT_NOISE,  SiOPMTable.PG_NOISE_WHITE, 16,  1, 16);  // noise
            channelModuleSetting[MT_MA3]    = new SiMMLChannelSetting(MT_MA3,    SiOPMTable.PG_MA3_WAVE,    32,  1, 32);  // MA3
            channelModuleSetting[MT_CUSTOM] = new SiMMLChannelSetting(MT_CUSTOM, SiOPMTable.PG_CUSTOM,      256, 1, 256); // SCC / custom wave table
            channelModuleSetting[MT_ALL]    = new SiMMLChannelSetting(MT_ALL,    SiOPMTable.PG_SINE,        512, 1, 512); // all pgTypes
            channelModuleSetting[MT_FM]     = new SiMMLChannelSetting(MT_FM,     SiOPMTable.PG_SINE,        1,   1, 1);   // FM sound module
            channelModuleSetting[MT_PCM]    = new SiMMLChannelSetting(MT_PCM,    SiOPMTable.PG_PCM,         256, 1, 256); // PCM
            channelModuleSetting[MT_PULSE]  = new SiMMLChannelSetting(MT_PULSE,  SiOPMTable.PG_PULSE,       32,  1, 32);  // pulse
            channelModuleSetting[MT_RAMP]   = new SiMMLChannelSetting(MT_RAMP,   SiOPMTable.PG_RAMP,        128, 1, 128); // ramp
            channelModuleSetting[MT_SAMPLE] = new SiMMLChannelSetting(MT_SAMPLE, 0,                         2,   1, 2);   // sampler. this is based on SiOPMChannelSampler
            
            // PSG setting
            ms = channelModuleSetting[MT_PSG];
            ms._pgTypeList[0] = SiOPMTable.PG_SQUARE;
            ms._pgTypeList[1] = SiOPMTable.PG_NOISE_PULSE;
            ms._pgTypeList[2] = SiOPMTable.PG_PC_NZ_16BIT;
            ms._ptTypeList[0] = SiOPMTable.PT_PSG;
            ms._ptTypeList[1] = SiOPMTable.PT_PSG_NOISE;
            ms._ptTypeList[2] = SiOPMTable.PT_PSG;
            ms._channelTone[0] = 0;
            ms._channelTone[1] = 0;
            ms._channelTone[2] = 0;
            ms._channelTone[3] = 1;
            // APU setting
            ms = channelModuleSetting[MT_APU];
            ms._pgTypeList[8]  = SiOPMTable.PG_TRIANGLE_FC;
            ms._pgTypeList[9]  = SiOPMTable.PG_NOISE_PULSE;
            ms._pgTypeList[10] = SiOPMTable.PG_NOISE_SHORT;
            ms._pgTypeList[11] = SiOPMTable.PG_CUSTOM;
            for (i=0; i<9;  i++) { ms._ptTypeList[i] = SiOPMTable.PT_PSG; }
            for (i=9; i<12; i++) { ms._ptTypeList[i] = SiOPMTable.PT_APU_NOISE; }
            ms._initIndex       = 1;
            ms._channelTone[0] = 4;
            ms._channelTone[1] = 4;
            ms._channelTone[2] = 8;
            ms._channelTone[3] = 9;
            ms._channelTone[4] = 11;
            // FM setting
            channelModuleSetting[MT_FM]._selectToneType = SiMMLChannelSetting.SELECT_TONE_FM;
            // Sampler
            channelModuleSetting[MT_SAMPLE]._selectToneType = SiMMLChannelSetting.SELECT_TONE_NOP;
            channelModuleSetting[MT_SAMPLE]._channelType    = SiOPMChannelManager.CT_CHANNEL_SAMPLER;
           
            
            // These tables are just depended on my ear ... ('A`)
            tss_s2ar = _logTable(41, -4, 63, 9);
            tss_s2dr = _logTable(52, -4,  0, 20);
            tss_s2sr = _logTable( 9,  5,  0, 63);
            tss_s2rr = _logTable(12,  4, 63, 63);
            //trace(tss_s2ar); trace(tss_s2dr); trace(tss_s2sr); trace(tss_s2rr);
            
            function _logTable(start:int, step:int, v0:int, v255:int) : Vector.<String> {
                var vector:Vector.<String> = new Vector.<String>(256, true);
                var imax:int, j:int, t:int, dt:int;

                t  = start<<16;
                dt = step<<16;
                for (i=1, j=1; j<=8; j++) {
                    for (imax=1<<j; i<imax; i++) {
                        vector[i] = String(t>>16);
                        t += dt;
                    }
                    dt >>= 1;
                }
                vector[0]   = String(v0);
                vector[255] = String(v255);
                
                return vector;
            }
            
            // envelop table
            envelopTables = new Array(ENV_TABLE_MAX);
            for (i=0; i<ENV_TABLE_MAX; i++) { envelopTables[i] = null; }
            // FM parameter settings
            fmParameters = new Array(FM_PARAM_MAX);
            for (i=0; i<FM_PARAM_MAX; i++) { fmParameters[i] = null; }
        }
        
        
        
        
    // operations
    //--------------------------------------------------
        /** Reset all user tables */
        static public function resetAllUserTables() : void
        {
            var i:int, imax:int;
            
            // Reset all envelop tables
            imax = instance.envelopTables.length;
            for (i=0; i<imax; i++) { instance.envelopTables[i] = null }
            
            // Reset all FM parameter settings
            imax = instance.fmParameters.length;
            for (i=0; i<imax; i++) { instance.fmParameters[i] = null; }
        }
        
        
        /** Register envelop table */
        static public function registerEnvelopTable(index:int, table:SiMMLEnvelopTable) : void
        {
            if ((index<0 && index>=ENV_TABLE_MAX) || index == 255) return;
            instance.envelopTables[index] = table;
        }
        
        
        /** Register SiOPMChannelParam */
        static public function registerChannelParam(index:int, param:SiOPMChannelParam) : void
        {
            if (index<0 && index>=FM_PARAM_MAX) return;
            instance.fmParameters[index] = param;
        }
        
        
        /** Get SiOPMChannelParam */
        static public function getSiOPMChannelParam(index:int) : SiOPMChannelParam
        {
            if (index<0 && index>=FM_PARAM_MAX) return null;
            return instance.fmParameters[index];
        }
    }
}

